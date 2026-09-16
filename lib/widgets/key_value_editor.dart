import 'package:flutter/material.dart';

class KeyValueEntry {
  const new({required this.key, required this.value});

  final String key;
  final String value;
}

Map<String, String> keyValueEntriesToMap(List<KeyValueEntry> entries) {
  return {
    for (final entry in entries)
      if (entry.key.trim().isNotEmpty) entry.key.trim(): entry.value,
  };
}

class KeyValueEditor extends StatefulWidget {
  const new({
    required this.label,
    required this.onChanged,
    super.key,
  });

  final String label;
  final ValueChanged<List<KeyValueEntry>> onChanged;

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  final List<_EditorRow> _rows = [_EditorRow()];

  void _notifyChanged() {
    widget.onChanged(
      _rows
          .map(
            (row) => KeyValueEntry(
              key: row.keyController.text,
              value: row.valueController.text,
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
  final keyController = TextEditingController();
  final valueController = TextEditingController();

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
