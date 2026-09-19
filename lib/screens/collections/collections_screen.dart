import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/saved_requests/saved_requests_controller.dart';
import 'package:lurc/screens/collections/saved_request_editor_screen.dart';
import 'package:lurc/theme/lurc_theme.dart';

enum _RequestAction { edit, rename, move, delete }

enum _CollectionAction { newFolder, rename, move, delete }

class CollectionsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  var _busy = false;

  Future<void> _write(
    Future<void> Function(SavedRequestsController) operation,
    String message,
  ) async {
    if (!mounted || _busy) return;
    setState(() => _busy = true);
    try {
      await operation(ref.read(savedRequestsControllerProvider.notifier));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save changes. Please retry.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _name(String title, String initial, String action) =>
      showDialog<String>(
        context: context,
        builder: (_) =>
            _NameDialog(title: title, initialName: initial, action: action),
      );

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _createCollection([String? parentId]) async {
    final name = await _name(
      parentId == null ? 'New collection' : 'New folder',
      '',
      'Create',
    );
    if (name == null || !mounted) return;
    await _write(
      (controller) => controller.saveCollection(
        Collection(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          parentId: parentId,
        ),
      ),
      'Collection created',
    );
  }

  Future<void> _collectionAction(
    Collection collection,
    _CollectionAction action,
  ) async {
    switch (action) {
      case _CollectionAction.newFolder:
        await _createCollection(collection.id);
      case _CollectionAction.rename:
        final name = await _name('Rename collection', collection.name, 'Save');
        if (name == null || !mounted) return;
        await _write(
          (controller) =>
              controller.saveCollection(collection.copyWith(name: name)),
          'Collection renamed',
        );
      case _CollectionAction.move:
        final state = ref.read(savedRequestsControllerProvider).requireValue;
        final destination = await showModalBottomSheet<_Destination>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const ListTile(title: Text('Move folder')),
                ListTile(
                  title: const Text('Top level'),
                  onTap: () => Navigator.pop(context, const _Destination(null)),
                ),
                for (final candidate in state.collections)
                  if (candidate.id != collection.id &&
                      !_isDescendant(
                        state.collections,
                        candidate,
                        collection.id,
                      ))
                    ListTile(
                      title: Text(candidate.name),
                      onTap: () => Navigator.pop(
                        context,
                        _Destination(candidate.id),
                      ),
                    ),
              ],
            ),
          ),
        );
        if (destination == null || !mounted) return;
        await _write(
          (controller) => controller.saveCollection(
            collection.copyWith(
              parentId: destination.id,
              clearParent: destination.id == null,
            ),
          ),
          'Folder moved',
        );
      case _CollectionAction.delete:
        final confirmed = await _confirm(
          'Delete collection?',
          'Delete “${collection.name}”? Its saved requests will be moved '
              'to Unfiled. No requests will be deleted.',
        );
        if (!confirmed || !mounted) return;
        await _write(
          (controller) => controller.deleteCollection(collection.id),
          'Collection deleted. Saved requests kept in Unfiled.',
        );
    }
  }

  Future<void> _requestAction(
    SavedRequest request,
    _RequestAction action,
  ) async {
    switch (action) {
      case _RequestAction.edit:
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => SavedRequestEditorScreen(request: request),
          ),
        );
      case _RequestAction.rename:
        final name = await _name('Rename request', request.name, 'Save');
        if (name == null || !mounted) return;
        await _write(
          (controller) => controller.saveRequest(request.copyWith(name: name)),
          'Request renamed',
        );
      case _RequestAction.move:
        final collections = ref
            .read(savedRequestsControllerProvider)
            .requireValue
            .collections;
        final destination = await showModalBottomSheet<_Destination>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.7,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('Move request'),
                    subtitle: Text(request.name),
                    trailing: IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  _destinationTile(context, request, null, 'Unfiled'),
                  for (final collection in collections)
                    _destinationTile(
                      context,
                      request,
                      collection.id,
                      collection.name,
                    ),
                ],
              ),
            ),
          ),
        );
        if (destination == null || !mounted) return;
        if (destination.id == request.collectionId) return;
        await _write(
          (controller) => controller.saveRequest(
            request.copyWith(
              collectionId: destination.id,
              clearCollection: destination.id == null,
            ),
          ),
          'Request moved',
        );
      case _RequestAction.delete:
        final confirmed = await _confirm(
          'Delete saved request?',
          'Delete “${request.name}”? This cannot be undone.',
        );
        if (!confirmed || !mounted) return;
        await _write(
          (controller) => controller.deleteRequest(request.id),
          'Saved request deleted',
        );
    }
  }

  bool _isDescendant(
    List<Collection> collections,
    Collection candidate,
    String ancestorId,
  ) {
    var parentId = candidate.parentId;
    while (parentId != null) {
      if (parentId == ancestorId) return true;
      final matches = collections.where((item) => item.id == parentId);
      if (matches.isEmpty) return false;
      parentId = matches.single.parentId;
    }
    return false;
  }

  Widget _collectionTile(
    Collection collection,
    List<Collection> collections,
    List<SavedRequest> requests,
  ) => ExpansionTile(
    key: PageStorageKey('collection-${collection.id}'),
    initiallyExpanded: true,
    controlAffinity: ListTileControlAffinity.leading,
    childrenPadding: const EdgeInsets.only(left: LurcSpacing.lg),
    title: Row(
      children: [
        const Icon(Icons.folder_outlined, size: 20),
        const SizedBox(width: LurcSpacing.sm),
        Expanded(child: Text(collection.name)),
      ],
    ),
    subtitle: Text(_requestCount(requests.length)),
    trailing: PopupMenuButton<_CollectionAction>(
      tooltip: 'Actions for ${collection.name}',
      enabled: !_busy,
      onSelected: (action) => _collectionAction(collection, action),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _CollectionAction.newFolder,
          child: Text('New folder'),
        ),
        PopupMenuItem(
          value: _CollectionAction.rename,
          child: Text('Rename collection'),
        ),
        PopupMenuItem(
          value: _CollectionAction.move,
          child: Text('Move folder'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _CollectionAction.delete,
          child: Text('Delete collection'),
        ),
      ],
    ),
    children: [
      for (final child in collections.where(
        (item) => item.parentId == collection.id,
      ))
        _collectionTile(
          child,
          collections,
          ref
              .read(savedRequestsControllerProvider)
              .requireValue
              .requestsInCollection(child.id),
        ),
      if (requests.isEmpty &&
          !collections.any((item) => item.parentId == collection.id))
        const ListTile(title: Text('No saved requests')),
      ...requests.map(_requestTile),
    ],
  );

  Widget _destinationTile(
    BuildContext context,
    SavedRequest request,
    String? id,
    String name,
  ) => ListTile(
    leading: Icon(
      id == null ? Icons.inventory_2_outlined : Icons.folder_outlined,
    ),
    title: Text(name),
    selected: id == request.collectionId,
    trailing: id == request.collectionId ? const Icon(Icons.check) : null,
    onTap: () => Navigator.pop(context, _Destination(id)),
  );

  String _requestCount(int count) =>
      '$count saved request${count == 1 ? '' : 's'}';

  Widget _requestTile(SavedRequest request) => ListTile(
    key: ValueKey('request-${request.id}'),
    onTap: () => Navigator.pop(context, request),
    leading: SizedBox(
      width: 48,
      child: Text(
        request.method.name.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium,
      ),
    ),
    title: Text(request.name),
    subtitle: Text(request.url, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: PopupMenuButton<_RequestAction>(
      tooltip: 'Actions for ${request.name}',
      enabled: !_busy,
      onSelected: (action) => _requestAction(request, action),
      itemBuilder: (_) => const [
        PopupMenuItem(value: _RequestAction.edit, child: Text('Edit request')),
        PopupMenuItem(
          value: _RequestAction.rename,
          child: Text('Rename request'),
        ),
        PopupMenuItem(value: _RequestAction.move, child: Text('Move request')),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _RequestAction.delete,
          child: Text('Delete request'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(savedRequestsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _createCollection,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Collection'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_busy) const LinearProgressIndicator(),
            Expanded(
              child: library.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Could not load collections.\n$error')),
                data: (state) {
                  if (state.collections.isEmpty && state.requests.isEmpty) {
                    return const _EmptyLibrary();
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      LurcSpacing.sm,
                      LurcSpacing.sm,
                      LurcSpacing.sm,
                      96,
                    ),
                    children: [
                      for (final collection
                          in state.childCollections(null))
                        _collectionTile(
                          collection,
                          state.collections,
                          state.requestsInCollection(collection.id),
                        ),
                      if (state.requestsInCollection(null).isNotEmpty)
                        ExpansionTile(
                          key: const PageStorageKey('unfiled'),
                          initiallyExpanded: true,
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: const Text('Unfiled'),
                          children: state
                              .requestsInCollection(null)
                              .map(_requestTile)
                              .toList(),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const new(this.id);
  final String? id;
}

class _NameDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.initialName,
    required this.action,
  });
  final String title;
  final String initialName;
  final String action;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Enter a name' : null,
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.action)),
    ],
  );
}

class _EmptyLibrary extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(LurcSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: LurcSpacing.md),
          Text(
            'No saved requests yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: LurcSpacing.sm),
          Text(
            'Create a collection, then save requests from the '
            'request workspace.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
