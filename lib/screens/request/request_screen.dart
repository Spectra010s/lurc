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

  Map<String, String> _toMap(List<KeyValueEntry> entries) {
    return {
      for (final entry in entries)
        if (entry.key.trim().isNotEmpty) entry.key.trim(): entry.value,
    };
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    await ref.read(requestControllerProvider.notifier).send(
      url: _urlController.text,
      body: _bodyController.text,
      queryParameters: _toMap(_queryParameters),
      headers: _toMap(_headers),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  KeyValueEditor(
                    label: 'Query parameters',
                    onChanged: (entries) => _queryParameters = entries,
                  ),
                  KeyValueEditor(
                    label: 'Headers',
                    onChanged: (entries) => _headers = entries,
                  ),
                  RequestEditor(controller: _bodyController),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
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
