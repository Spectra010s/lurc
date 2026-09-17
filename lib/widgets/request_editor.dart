import 'package:flutter/material.dart';
import 'package:lurc/core/http/request_body_type.dart';

class RequestEditor extends StatelessWidget {
  const new({
    required this.controller,
    required this.mode,
    required this.onModeChanged,
    super.key,
  });

  final TextEditingController controller;
  final RequestBodyType mode;
  final ValueChanged<RequestBodyType> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Body', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<RequestBodyType>(
          segments: const [
            ButtonSegment(value: RequestBodyType.none, label: Text('None')),
            ButtonSegment(value: RequestBodyType.json, label: Text('JSON')),
            ButtonSegment(value: RequestBodyType.text, label: Text('Text')),
          ],
          selected: {mode},
          onSelectionChanged: (selection) => onModeChanged(selection.first),
        ),
        if (mode != RequestBodyType.none) ...[
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
              hintText: mode == RequestBodyType.json
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
