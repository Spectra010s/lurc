import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/saved_requests/saved_requests_controller.dart';
import 'package:lurc/widgets/key_value_editor.dart';
import 'package:lurc/widgets/request_editor.dart';

class SavedRequestEditorScreen extends ConsumerStatefulWidget {
  const new({required this.request, super.key});

  final SavedRequest request;

  @override
  ConsumerState<SavedRequestEditorScreen> createState() =>
      _SavedRequestEditorScreenState();
}

class _SavedRequestEditorScreenState
    extends ConsumerState<SavedRequestEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _body;
  late HttpMethod _method;
  late RequestBodyType _bodyType;
  late Map<String, String> _query;
  late Map<String, String> _headers;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final request = widget.request;
    _name = TextEditingController(text: request.name);
    _url = TextEditingController(text: request.url);
    _body = TextEditingController(text: request.body);
    _method = request.method;
    _bodyType = request.bodyType;
    _query = request.queryParameters;
    _headers = request.headers;
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final original = widget.request;
      await ref
          .read(savedRequestsControllerProvider.notifier)
          .saveRequest(
            original.copyWith(
              name: _name.text.trim(),
              method: _method,
              url: _url.text,
              queryParameters: _query,
              headers: _headers,
              body: _body.text == (original.body ?? '')
                  ? original.body
                  : _body.text,
              bodyType: _bodyType,
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save request. Please retry.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<KeyValueEntry> _entries(Map<String, String> values) => values.entries
      .map((entry) => KeyValueEntry(key: entry.key, value: entry.value))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Edit saved request'),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    ),
    body: SafeArea(
      child: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Request name'),
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a request name'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HttpMethod>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: [
                  for (final method in HttpMethod.values)
                    DropdownMenuItem(
                      value: method,
                      child: Text(method.name.toUpperCase()),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _url,
                decoration: const InputDecoration(labelText: 'URL'),
                keyboardType: TextInputType.url,
                autocorrect: false,
                enableSuggestions: false,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a URL'
                    : null,
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                maintainState: true,
                tilePadding: EdgeInsets.zero,
                title: const Text('Query parameters'),
                children: [
                  KeyValueEditor(
                    label: 'Parameters',
                    initialEntries: _entries(widget.request.queryParameters),
                    onChanged: (entries) =>
                        _query = keyValueEntriesToMap(entries),
                  ),
                ],
              ),
              ExpansionTile(
                maintainState: true,
                tilePadding: EdgeInsets.zero,
                title: const Text('Headers'),
                children: [
                  KeyValueEditor(
                    label: 'Headers',
                    initialEntries: _entries(widget.request.headers),
                    onChanged: (entries) =>
                        _headers = keyValueEntriesToMap(entries),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RequestEditor(
                controller: _body,
                mode: _bodyType,
                onModeChanged: (mode) => setState(() => _bodyType = mode),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
