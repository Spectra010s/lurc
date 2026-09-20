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
      Align(
        alignment: Alignment.centerLeft,
        child: DropdownButton<RequestBodyType>(
          value: mode,
          underline: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(8),
          items: const [
            DropdownMenuItem(
              value: RequestBodyType.none,
              child: Text('None'),
            ),
            DropdownMenuItem(
              value: RequestBodyType.json,
              child: Text('JSON'),
            ),
            DropdownMenuItem(
              value: RequestBodyType.text,
              child: Text('Text'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onModeChanged(value);
          },
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
          minLines: 10,
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
