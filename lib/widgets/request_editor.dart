import 'package:flutter/material.dart';

enum RequestBodyMode { none, json, text }

class RequestEditor extends StatelessWidget {
  const new({
    required this.controller,
    required this.mode,
    required this.onModeChanged,
    super.key,
  });

  final TextEditingController controller;
  final RequestBodyMode mode;
  final ValueChanged<RequestBodyMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Body', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<RequestBodyMode>(
          segments: const [
            ButtonSegment(value: RequestBodyMode.none, label: Text('None')),
            ButtonSegment(value: RequestBodyMode.json, label: Text('JSON')),
            ButtonSegment(value: RequestBodyMode.text, label: Text('Text')),
          ],
          selected: {mode},
          onSelectionChanged: (selection) => onModeChanged(selection.first),
        ),
        if (mode != RequestBodyMode.none) ...[
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 12,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: mode == RequestBodyMode.json
                  ? '{"key":"value"}'
                  : 'Request body',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}
