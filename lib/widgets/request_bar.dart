import 'package:flutter/material.dart';
import 'package:lurc/core/http/request.dart';

class RequestBar extends StatelessWidget {
  const new({
    required this.method,
    required this.controller,
    required this.loading,
    required this.onMethodChanged,
    required this.onSend,
    super.key,
  });

  final HttpMethod method;
  final TextEditingController controller;
  final bool loading;
  final ValueChanged<HttpMethod> onMethodChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          TextField(
            controller: controller,
            enabled: !loading,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: 'https://example.com',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear URL',
                      onPressed: loading ? null : controller.clear,
                      icon: const Icon(Icons.close),
                    ),
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
                child: FilledButton.icon(
                  onPressed: loading ? null : onSend,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(loading ? 'Sending' : 'Send'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
