import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/request_bar.dart';
import '../../widgets/request_editor.dart';
import '../../widgets/response_view.dart';
import 'request_controller.dart';

class RequestScreen extends ConsumerStatefulWidget {
  const RequestScreen({super.key});

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen> {
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();

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
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(requestControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lurc')),
      body: Column(
        children: [
          RequestBar(
            method: request.method,
            controller: _urlController,
            loading: request.loading,
            onMethodChanged: ref.read(requestControllerProvider.notifier).setMethod,
            onSend: _sendRequest,
          ),
          RequestEditor(controller: _bodyController),
          Expanded(
            child: ResponseView(
              response: request.response,
              error: request.error,
              loading: request.loading,
            ),
          ),
        ],
      ),
    );
  }
}
