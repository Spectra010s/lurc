import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/environments/environment.dart';
import 'package:lurc/core/environments/environment_controller.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/saved_requests/saved_requests_controller.dart';
import 'package:lurc/screens/collections/collections_screen.dart';
import 'package:lurc/screens/environments/environments_screen.dart';
import 'package:lurc/screens/history/history_screen.dart';
import 'package:lurc/screens/request/request_controller.dart';
import 'package:lurc/theme/lurc_theme.dart';
import 'package:lurc/widgets/key_value_editor.dart';
import 'package:lurc/widgets/request_bar.dart';
import 'package:lurc/widgets/request_editor.dart';
import 'package:lurc/widgets/request_workspace.dart';
import 'package:lurc/widgets/response_view.dart';

class RequestScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen> {
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  List<KeyValueEntry> _queryParameters = const [];
  List<KeyValueEntry> _headers = const [];
  RequestBodyType _bodyMode = RequestBodyType.none;
  var _editorRevision = 0;

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final headers = keyValueEntriesToMap(_headers);
    if (_bodyMode == RequestBodyType.json &&
        !headers.keys.any((key) => key.toLowerCase() == 'content-type')) {
      headers['Content-Type'] = 'application/json';
    }
    await ref.read(requestControllerProvider.notifier).send(
      url: _urlController.text,
      body: _bodyMode == RequestBodyType.none ? null : _bodyController.text,
      bodyType: _bodyMode,
      validateJsonBody: _bodyMode == RequestBodyType.json,
      queryParameters: keyValueEntriesToMap(_queryParameters),
      headers: headers,
    );
  }

  void _loadSnapshot({
    required HttpMethod method,
    required String url,
    required String? body,
    required RequestBodyType bodyType,
    required Map<String, String> queryParameters,
    required Map<String, String> headers,
  }) {
    ref.read(requestControllerProvider.notifier).setMethod(method);
    setState(() {
      _urlController.text = url;
      _bodyController.text = body ?? '';
      _queryParameters = queryParameters.entries
          .map((entry) => KeyValueEntry(key: entry.key, value: entry.value))
          .toList(growable: false);
      _headers = headers.entries
          .map((entry) => KeyValueEntry(key: entry.key, value: entry.value))
          .toList(growable: false);
      _bodyMode = bodyType;
      _editorRevision++;
    });
  }

  Future<void> _openHistory() async {
    final record = await Navigator.of(context).push<RequestRecord>(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
    if (record == null || !mounted) return;
    final snapshot = record.request;
    _loadSnapshot(
      method: snapshot.method,
      url: snapshot.url,
      body: snapshot.body,
      bodyType: snapshot.bodyType,
      queryParameters: snapshot.queryParameters,
      headers: snapshot.headers,
    );
  }

  Future<void> _openCollections() async {
    final saved = await Navigator.of(context).push<SavedRequest>(
      MaterialPageRoute(builder: (_) => const CollectionsScreen()),
    );
    if (saved == null || !mounted) return;
    _loadSnapshot(
      method: saved.method,
      url: saved.url,
      body: saved.body,
      bodyType: saved.bodyType,
      queryParameters: saved.queryParameters,
      headers: saved.headers,
    );
  }

  Future<void> _openEnvironments() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const EnvironmentsScreen()),
    );
  }

  Future<void> _saveRequest(HttpMethod method) async {
    final library = await ref.read(savedRequestsControllerProvider.future);
    if (!mounted) return;
    final result = await showDialog<_SaveRequestResult>(
      context: context,
      builder: (context) => _SaveRequestDialog(
        collections: library.collections,
      ),
    );
    if (result == null || result.name.isEmpty) return;

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await ref.read(savedRequestsControllerProvider.notifier).saveRequest(
      SavedRequest(
        id: id,
        name: result.name,
        method: method,
        url: _urlController.text.trim(),
        collectionId: result.collectionId,
        queryParameters: keyValueEntriesToMap(_queryParameters),
        headers: keyValueEntriesToMap(_headers),
        body: _bodyMode == RequestBodyType.none
            ? null
            : _bodyController.text,
        bodyType: _bodyMode,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved “${result.name}”')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(requestControllerProvider);
    final requestController = ref.read(requestControllerProvider.notifier);
    final environments =
        ref.watch(environmentsControllerProvider).value ?? const [];
    final activeEnvironment = ref.watch(activeEnvironmentProvider);
    final environmentController =
        ref.read(activeEnvironmentIdProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lurc'),
        actions: [
          _EnvironmentMenu(
            environments: environments,
            active: activeEnvironment,
            onSelected: (id) => environmentController.selectedId = id,
            onManage: _openEnvironments,
          ),
          IconButton(
            tooltip: 'Save request',
            onPressed: request.loading
                ? null
                : () => _saveRequest(request.method),
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
      drawer: _WorkspaceDrawer(
        activeEnvironment: activeEnvironment,
        onHistory: _openHistory,
        onCollections: _openCollections,
        onEnvironments: _openEnvironments,
      ),
      body: SafeArea(
        top: false,
        child: RequestWorkspace(
          loading: request.loading,
          result: request.response ?? request.error,
          requestBar: RequestBar(
            method: request.method,
            controller: _urlController,
            loading: request.loading,
            onMethodChanged: requestController.setMethod,
            onSend: _sendRequest,
            onCancel: requestController.cancel,
          ),
          editor: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                if (activeEnvironment != null)
                  _ActiveEnvironmentBanner(
                    environment: activeEnvironment,
                    onClear: () => environmentController.selectedId = null,
                  ),
                const _RequestSectionTabs(),
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(LurcSpacing.lg),
                        child: KeyValueEditor(
                          key: ValueKey('params-$_editorRevision'),
                          label: 'Query parameters',
                          initialEntries: _queryParameters,
                          onChanged: (entries) => _queryParameters = entries,
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(LurcSpacing.lg),
                        child: KeyValueEditor(
                          key: ValueKey('headers-$_editorRevision'),
                          label: 'Headers',
                          initialEntries: _headers,
                          onChanged: (entries) => _headers = entries,
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(LurcSpacing.lg),
                        child: RequestEditor(
                          controller: _bodyController,
                          mode: _bodyMode,
                          onModeChanged: (mode) =>
                              setState(() => _bodyMode = mode),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          response: ResponseView(
            response: request.response,
            error: request.error,
            loading: request.loading,
          ),
        ),
      ),
    );
  }
}

class _RequestSectionTabs extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: const TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerHeight: 1,
      labelPadding: EdgeInsets.symmetric(horizontal: LurcSpacing.lg),
      tabs: [
        Tab(text: 'Params'),
        Tab(text: 'Headers'),
        Tab(text: 'Body'),
      ],
    ),
  );
}

class _EnvironmentMenu extends StatelessWidget {
  const new({
    required this.environments,
    required this.active,
    required this.onSelected,
    required this.onManage,
  });

  final List<Environment> environments;
  final Environment? active;
  final ValueChanged<String?> onSelected;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: active == null
        ? 'Select environment'
        : 'Environment: ${active!.name}',
    icon: Badge(
      isLabelVisible: active != null,
      smallSize: 7,
      child: Icon(active == null ? Icons.tune_outlined : Icons.tune),
    ),
    onSelected: (value) {
      if (value == '__manage__') {
        onManage();
      } else if (value == '__none__') {
        onSelected(null);
      } else {
        onSelected(value);
      }
    },
    itemBuilder: (context) => [
      if (active != null)
        const PopupMenuItem(
          value: '__none__',
          child: Text('No environment'),
        ),
      ...environments.map(
        (environment) => PopupMenuItem(
          value: environment.id,
          child: Row(
            children: [
              Icon(
                environment.id == active?.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(environment.name)),
            ],
          ),
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: '__manage__',
        child: Text('Manage environments'),
      ),
    ],
  );
}

class _ActiveEnvironmentBanner extends StatelessWidget {
  const new({required this.environment, required this.onClear});

  final Environment environment;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LurcSpacing.lg,
        vertical: LurcSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: LurcSpacing.sm),
          Expanded(
            child: Text(
              environment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Clear environment',
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    ),
  );
}

class _SaveRequestDialog extends StatefulWidget {
  const new({required this.collections});

  final List<Collection> collections;

  @override
  State<_SaveRequestDialog> createState() => _SaveRequestDialogState();
}

class _SaveRequestDialogState extends State<_SaveRequestDialog> {
  final _nameController = TextEditingController();
  String? _collectionId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Save request'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Get current user',
          ),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(
                context,
                _SaveRequestResult(name, _collectionId),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          decoration: const InputDecoration(labelText: 'Collection'),
          items: [
            const DropdownMenuItem<String?>(child: Text('Unfiled')),
            ...widget.collections.map(
              (collection) => DropdownMenuItem<String?>(
                value: collection.id,
                child: Text(collection.name),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _collectionId = value),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _nameController.text.trim().isEmpty
            ? null
            : () => Navigator.pop(
                  context,
                  _SaveRequestResult(
                    _nameController.text.trim(),
                    _collectionId,
                  ),
                ),
        child: const Text('Save'),
      ),
    ],
  );
}

class _SaveRequestResult {
  const new(this.name, this.collectionId);

  final String name;
  final String? collectionId;
}

class _WorkspaceDrawer extends StatelessWidget {
  const new({
    required this.activeEnvironment,
    required this.onHistory,
    required this.onCollections,
    required this.onEnvironments,
  });

  final Environment? activeEnvironment;
  final VoidCallback onHistory;
  final VoidCallback onCollections;
  final VoidCallback onEnvironments;

  @override
  Widget build(BuildContext context) => NavigationDrawer(
    onDestinationSelected: (index) {
      Navigator.pop(context);
      if (index == 1) onCollections();
      if (index == 2) onHistory();
      if (index == 3) onEnvironments();
    },
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          28,
          LurcSpacing.xl,
          LurcSpacing.lg,
          LurcSpacing.sm,
        ),
        child: Text(
          'Lurc',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          28,
          0,
          LurcSpacing.lg,
          LurcSpacing.md,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.pop(context);
            onEnvironments();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: LurcSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.tune_outlined, size: 18),
                const SizedBox(width: LurcSpacing.sm),
                Expanded(
                  child: Text(
                    activeEnvironment?.name ?? 'No environment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      ),
      const Divider(),
      const NavigationDrawerDestination(
        icon: Icon(Icons.send_outlined),
        selectedIcon: Icon(Icons.send),
        label: Text('Request'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder),
        label: Text('Collections'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.history),
        label: Text('History'),
      ),
      const Divider(),
      const NavigationDrawerDestination(
        icon: Icon(Icons.tune_outlined),
        label: Text('Environments'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.settings_outlined),
        label: Text('Settings'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.info_outline),
        label: Text('About'),
      ),
    ],
  );
}
