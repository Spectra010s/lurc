import 'package:flutter/material.dart';
import 'package:lurc/theme/lurc_theme.dart';

class KeyValueEntry {
  const new({
    required this.key,
    required this.value,
    this.enabled = true,
    this.secret = false,
  });

  final String key;
  final String value;
  final bool enabled;
  final bool secret;
}

Map<String, String> keyValueEntriesToMap(List<KeyValueEntry> entries) {
  return {
    for (final entry in entries)
      if (entry.enabled && entry.key.trim().isNotEmpty)
        entry.key.trim(): entry.value,
  };
}

class KeyValueEditor extends StatefulWidget {
  const new({
    required this.label,
    required this.onChanged,
    this.initialEntries = const [],
    this.allowSecrets = false,
    super.key,
  });

  final String label;
  final ValueChanged<List<KeyValueEntry>> onChanged;
  final List<KeyValueEntry> initialEntries;
  final bool allowSecrets;

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  late final List<_EditorRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialEntries.isEmpty
        ? [_EditorRow()]
        : widget.initialEntries
            .map(
              (entry) => _EditorRow(
                key: entry.key,
                value: entry.value,
                enabled: entry.enabled,
                secret: entry.secret,
              ),
            )
            .toList();
  }

  void _notifyChanged() {
    widget.onChanged(
      _rows
          .map(
            (row) => KeyValueEntry(
              key: row.keyController.text,
              value: row.valueController.text,
              enabled: row.enabled,
              secret: row.secret,
            ),
          )
          .toList(growable: false),
    );
  }

  void _addRow() {
    setState(() => _rows.add(_EditorRow()));
    _notifyChanged();
  }

  void _removeRow(int index) {
    _rows.removeAt(index).dispose();
    setState(() {});
    _notifyChanged();
  }

  void _setEnabled(int index, bool enabled) {
    setState(() => _rows[index].enabled = enabled);
    _notifyChanged();
  }

  void _setSecret(int index, bool secret) {
    setState(() => _rows[index].secret = secret);
    _notifyChanged();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            tooltip: 'Add row',
            onPressed: _addRow,
            icon: const Icon(Icons.add, size: 20),
          ),
        ],
      ),
      const SizedBox(height: LurcSpacing.xs),
      for (var index = 0; index < _rows.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: LurcSpacing.sm),
          child: _row(context, index),
        ),
    ],
  );

  Widget _row(BuildContext context, int index) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 440;
      final row = _rows[index];
      final keyField = Semantics(
        textField: true,
        label: '${widget.label} key ${index + 1}',
        child: TextField(
        controller: row.keyController,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _notifyChanged(),
        decoration: const InputDecoration(hintText: 'Key', isDense: true),
        ),
      );
      final valueField = Semantics(
        textField: true,
        label: '${widget.label} value ${index + 1}',
        child: TextField(
        controller: row.valueController,
        obscureText: widget.allowSecrets && row.secret,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _notifyChanged(),
        onSubmitted: (_) {
          if (index == _rows.length - 1) _addRow();
        },
        decoration: const InputDecoration(hintText: 'Value', isDense: true),
        ),
      );
      final actions = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: row.enabled ? 'Disable row' : 'Enable row',
            button: true,
            child: Tooltip(
              message: row.enabled ? 'Disable row' : 'Enable row',
              child: Checkbox(
              value: row.enabled,
              onChanged: (value) => _setEnabled(index, value ?? true),
              visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          if (widget.allowSecrets)
            IconButton(
              tooltip: row.secret ? 'Show value' : 'Hide value',
              onPressed: () => _setSecret(index, !row.secret),
              icon: Icon(
                row.secret
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          IconButton(
            tooltip: 'Remove row',
            onPressed: _rows.length == 1 ? null : () => _removeRow(index),
            icon: const Icon(Icons.close),
          ),
        ],
      );

      if (compact) {
        return Column(
          children: [
            keyField,
            const SizedBox(height: LurcSpacing.sm),
            valueField,
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.enabled ? 'Enabled' : 'Disabled',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                actions,
              ],
            ),
            const Divider(height: 1),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: keyField),
          const SizedBox(width: LurcSpacing.sm),
          Expanded(child: valueField),
          actions,
        ],
      );
    },
  );

}

class _EditorRow {
  new({
    String key = '',
    String value = '',
    this.enabled = true,
    this.secret = false,
  })
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  final TextEditingController keyController;
  final TextEditingController valueController;
  bool enabled;
  bool secret;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
