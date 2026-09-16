import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    await ref.read(requestControllerProvider.notifier).send(
      url: _urlController.text,
      body: _bodyMode == RequestBodyMode.none ? null : _bodyController.text,
      queryParameters: keyValueEntriesToMap(_queryParameters),
      headers: keyValueEntriesToMap(_headers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(requestControllerProvider);
    final requestController = ref.read(requestControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Lurc')),
      body: Column(
        children: [
          RequestBar(
            method: request.method,
            controller: _urlController,
            loading: request.loading,
            onMethodChanged: requestController.setMethod,
            onSend: _sendRequest,
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
                            label: 'Query parameters',
                            onChanged: (entries) => _queryParameters = entries,
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: KeyValueEditor(
                            label: 'Headers',
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
