import 'package:flutter/material.dart';

import '../../core/http/http_client.dart';
import '../../core/http/request.dart';
import '../../core/http/response.dart';
import '../../widgets/request_bar.dart';
import '../../widgets/request_editor.dart';
import '../../widgets/response_view.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  final _client = LurcHttpClient();

  HttpMethod _method = HttpMethod.get;
  HttpResponse? _response;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Enter a URL');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _response = null;
    });

    try {
      final response = await _client.execute(
        HttpRequest(
          method: _method,
          url: url,
          body: _bodyController.text.isEmpty ? null : _bodyController.text,
        ),
      );

      if (!mounted) return;
      setState(() => _response = response);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lurc')),
      body: Column(
        children: [
          RequestBar(
            method: _method,
            controller: _urlController,
            loading: _loading,
            onMethodChanged: (method) => setState(() => _method = method),
            onSend: _sendRequest,
          ),
          RequestEditor(controller: _bodyController),
          Expanded(
            child: ResponseView(
              response: _response,
              error: _error,
              loading: _loading,
            ),
          ),
        ],
      ),
    );
  }
}
