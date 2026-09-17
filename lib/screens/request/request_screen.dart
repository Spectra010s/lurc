import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/http/request_record.dart';
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
  RequestBodyMode _bodyMode = RequestBodyMode.none;
  var _editorRevision = 0;

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final headers = keyValueEntriesToMap(_headers);
    if (_bodyMode == RequestBodyMode.json &&
        !headers.keys.any((key) => key.toLowerCase() == 'content-type')) {
      headers['Content-Type'] = 'application/json';
    }

    await ref.read(requestControllerProvider.notifier).send(
      url: _urlController.text,
      body: _bodyMode == RequestBodyMode.none ? null : _bodyController.text,
      bodyType: _bodyMode.name,
      validateJsonBody: _bodyMode == RequestBodyMode.json,
      queryParameters: keyValueEntriesToMap(_queryParameters),
      headers: headers,
    );
  }

  Future<void> _openHistory() async {
    final record = await Navigator.of(context).push<RequestRecord>(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
    if (record == null || !mounted) return;

    final snapshot = record.request;
    final bodyMode = RequestBodyMode.values.firstWhere(
      (mode) => mode.name == snapshot.bodyType,
      orElse: () => RequestBodyMode.none,
    );

    ref.read(requestControllerProvider.notifier).setMethod(snapshot.method);
    setState(() {
      _urlController.text = snapshot.url;
      _bodyController.text = snapshot.body ?? '';
      _queryParameters = snapshot.queryParameters.entries
          .map((entry) => KeyValueEntry(key: entry.key, value: entry.value))
          .toList(growable: false);
      _headers = snapshot.headers.entries
          .map((entry) => KeyValueEntry(key: entry.key, value: entry.value))
          .toList(growable: false);
      _bodyMode = bodyMode;
      _editorRevision++;
    });
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
            tooltip: 'Request history',
            onPressed: request.loading ? null : _openHistory,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
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
                  const TabBar(
                    tabs: [
                      Tab(text: 'Params'),
                      Tab(text: 'Headers'),
                      Tab(text: 'Body'),
                    ],
                  ),
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
                            onModeChanged: (mode) {
                              setState(() => _bodyMode = mode);
                            },
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
