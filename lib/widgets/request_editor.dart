import 'package:flutter/material.dart';
import 'package:lurc/core/http/request_body_type.dart';
import 'package:lurc/theme/lurc_theme.dart';

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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<RequestBodyType>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: RequestBodyType.none, label: Text('None')),
            ButtonSegment(value: RequestBodyType.json, label: Text('JSON')),
            ButtonSegment(value: RequestBodyType.text, label: Text('Text')),
          ],
          selected: {mode},
          onSelectionChanged: (selection) => onModeChanged(selection.first),
        ),
      ),
      if (mode == RequestBodyType.none)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: LurcSpacing.xl),
          child: Text(
            'This request has no body.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        )
      else ...[
        const SizedBox(height: LurcSpacing.md),
        TextField(
          controller: controller,
          minLines: 8,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          autocorrect: false,
          enableSuggestions: false,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: mode == RequestBodyType.json
                ? '{"key": "value"}'
                : 'Request body',
            alignLabelWithHint: true,
          ),
        ),
      ],
    ],
  );
}
