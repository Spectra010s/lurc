import 'package:flutter/material.dart';
import 'package:lurc/core/http/request.dart';

class RequestBar extends StatelessWidget {
  const new({
    required this.method,
    required this.controller,
    required this.loading,
    required this.onMethodChanged,
    required this.onSend,
    required this.onCancel,
    super.key,
  });

  final HttpMethod method;
  final TextEditingController controller;
  final bool loading;
  final ValueChanged<HttpMethod> onMethodChanged;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: controller,
            enabled: !loading,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) {
              if (!loading) onSend();
            },
            decoration: const InputDecoration(
              labelText: 'Request URL',
              hintText: 'https://example.com',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<HttpMethod>(
                  initialValue: method,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Method',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: loading
                      ? null
                      : (value) {
                          if (value != null) onMethodChanged(value);
                        },
                  items: HttpMethod.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.name.toUpperCase()),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: loading
                      ? OutlinedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.stop),
                          label: const Text('Cancel'),
                        )
                      : FilledButton.icon(
                          onPressed: onSend,
                          icon: const Icon(Icons.send),
                          label: const Text('Send'),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
