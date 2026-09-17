import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/saved_requests/saved_requests_controller.dart';
import 'package:lurc/screens/collections/collections_screen.dart';
import 'package:lurc/screens/history/history_screen.dart';
import 'package:lurc/screens/request/request_controller.dart';
import 'package:lurc/widgets/key_value_editor.dart';
import 'package:lurc/widgets/request_bar.dart';
import 'package:lurc/widgets/request_editor.dart';
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

  Future<void> _saveRequest(HttpMethod method) async {
    final library = await ref.read(savedRequestsControllerProvider.future);
    if (!mounted) return;
    final result = await showDialog<_SaveRequestResult>(
      context: context,
      builder: (context) => _SaveRequestDialog(collections: library.collections),
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
        body: _bodyMode == RequestBodyType.none ? null : _bodyController.text,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lurc'),
        actions: [
          IconButton(
            tooltip: 'Save request',
            onPressed: request.loading ? null : () => _saveRequest(request.method),
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
      drawer: _WorkspaceDrawer(onHistory: _openHistory, onCollections: _openCollections),
      body: Column(
        children: [
          RequestBar(
            method: request.method,
            controller: _urlController,
            loading: request.loading,
            onMethodChanged: requestController.setMethod,
            onSend: _sendRequest,
            onCancel: requestController.cancel,
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(tabs: [Tab(text: 'Params'), Tab(text: 'Headers'), Tab(text: 'Body')]),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: KeyValueEditor(
                            key: ValueKey('params-$_editorRevision'),
                            label: 'Query parameters',
                            initialEntries: _queryParameters,
                            onChanged: (entries) => _queryParameters = entries,
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: KeyValueEditor(
                            key: ValueKey('headers-$_editorRevision'),
                            label: 'Headers',
                            initialEntries: _headers,
                            onChanged: (entries) => _headers = entries,
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: RequestEditor(
                            controller: _bodyController,
                            mode: _bodyMode,
                            onModeChanged: (mode) => setState(() => _bodyMode = mode),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.38,
                    child: ResponseView(
                      response: request.response,
                      error: request.error,
                      loading: request.loading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          initialValue: _collectionId,
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
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _SaveRequestResult(_nameController.text.trim(), _collectionId),
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
  const new({required this.onHistory, required this.onCollections});

  final VoidCallback onHistory;
  final VoidCallback onCollections;

  @override
  Widget build(BuildContext context) => NavigationDrawer(
    selectedIndex: 0,
    onDestinationSelected: (index) {
      Navigator.pop(context);
      if (index == 1) onCollections();
      if (index == 2) onHistory();
    },
    children: const [
      Padding(
        padding: EdgeInsets.fromLTRB(28, 24, 16, 12),
        child: Text('Lurc', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
      ),
      NavigationDrawerDestination(icon: Icon(Icons.send_outlined), selectedIcon: Icon(Icons.send), label: Text('Request')),
      NavigationDrawerDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: Text('Collections')),
      NavigationDrawerDestination(icon: Icon(Icons.history), label: Text('History')),
      Divider(),
      NavigationDrawerDestination(icon: Icon(Icons.tune_outlined), label: Text('Environments')),
      NavigationDrawerDestination(icon: Icon(Icons.settings_outlined), label: Text('Settings')),
      NavigationDrawerDestination(icon: Icon(Icons.info_outline), label: Text('About')),
    ],
  );
}
