import 'package:flutter/material.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/theme/lurc_theme.dart';

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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      LurcSpacing.lg,
      LurcSpacing.sm,
      LurcSpacing.lg,
      LurcSpacing.md,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final methodPicker = SizedBox(
          width: compact ? 112 : 128,
          child: DropdownButtonFormField<HttpMethod>(
            initialValue: method,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Method',
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
        );
        final urlField = TextField(
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
            hintText: 'https://api.example.com/users',
            isDense: true,
          ),
        );
        final action = SizedBox(
          height: 48,
          child: loading
              ? OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Cancel'),
                )
              : FilledButton.icon(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send'),
                ),
        );

        if (compact) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  methodPicker,
                  const SizedBox(width: LurcSpacing.sm),
                  Expanded(child: urlField),
                ],
              ),
              const SizedBox(height: LurcSpacing.sm),
              SizedBox(width: double.infinity, child: action),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            methodPicker,
            const SizedBox(width: LurcSpacing.sm),
            Expanded(child: urlField),
            const SizedBox(width: LurcSpacing.sm),
            action,
          ],
        );
      },
    ),
  );
}
