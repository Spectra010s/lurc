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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          DropdownButton<HttpMethod>(
            value: method,
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
                .toList(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: loading ? null : onSend,
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send'),
          ),
        ],
      ),
    );
  }
}
