import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return Column(
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
            TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (var index = 0; index < _rows.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: _rows[index].enabled
                      ? 'Disable row'
                      : 'Enable row',
                  child: Checkbox(
                    value: _rows[index].enabled,
                    onChanged: (value) => _setEnabled(index, value ?? true),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _rows[index].keyController,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _notifyChanged(),
                    decoration: const InputDecoration(
                      hintText: 'Key',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _rows[index].valueController,
                    obscureText: widget.allowSecrets && _rows[index].secret,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _notifyChanged(),
                    onSubmitted: (_) {
                      if (index == _rows.length - 1) _addRow();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Value',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.allowSecrets)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: _rows[index].secret
                        ? 'Secret value hidden'
                        : 'Mark as secret',
                    onPressed: () => _setSecret(index, !_rows[index].secret),
                    icon: Icon(
                      _rows[index].secret
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove row',
                  onPressed: _rows.length == 1
                      ? null
                      : () => _removeRow(index),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
      ],
    );
  }
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
