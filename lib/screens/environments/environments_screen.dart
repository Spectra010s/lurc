import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/environments/environment.dart';
import 'package:lurc/core/environments/environment_controller.dart';
import 'package:lurc/widgets/key_value_editor.dart';

class EnvironmentsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environments = ref.watch(environmentsControllerProvider);
    final activeId = ref.watch(activeEnvironmentIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Environments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editEnvironment(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Environment'),
      ),
      body: environments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load environments.\n$error')),
        data: (items) {
          if (items.isEmpty) return const _EmptyEnvironments();
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final environment = items[index];
              final active = environment.id == activeId;
              return ListTile(
                leading: Icon(
                  active ? Icons.radio_button_checked : Icons.radio_button_off,
                ),
                title: Text(environment.name),
                subtitle: Text(
                  '${environment.variables.length} variable'
                  '${environment.variables.length == 1 ? '' : 's'}'
                  '${active ? ' • Active' : ''}',
                ),
                onTap: () =>
                    ref.read(activeEnvironmentIdProvider.notifier).selectedId =
                        environment.id,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      unawaited(_editEnvironment(context, ref, environment));
                    } else if (value == 'delete') {
                      unawaited(
                        ref
                            .read(environmentsControllerProvider.notifier)
                            .delete(environment.id),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editEnvironment(
    BuildContext context,
    WidgetRef ref, [
    Environment? existing,
  ]) async {
    final result = await Navigator.of(context).push<Environment>(
      MaterialPageRoute(
        builder: (_) => _EnvironmentEditor(environment: existing),
      ),
    );
    if (result == null || !context.mounted) return;
    await ref.read(environmentsControllerProvider.notifier).save(result);
    if (!context.mounted) return;
    ref.read(activeEnvironmentIdProvider.notifier).selectedId = result.id;
  }
}

class _EnvironmentEditor extends StatefulWidget {
  const new({this.environment});

  final Environment? environment;

  @override
  State<_EnvironmentEditor> createState() => _EnvironmentEditorState();
}

class _EnvironmentEditorState extends State<_EnvironmentEditor> {
  late final TextEditingController _nameController;
  late List<KeyValueEntry> _variables;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.environment?.name);
    _variables =
        widget.environment?.variables.entries
            .map((entry) => KeyValueEntry(key: entry.key, value: entry.value))
            .toList(growable: false) ??
        const [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      Environment(
        id:
            widget.environment?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        variables: keyValueEntriesToMap(_variables),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.environment == null ? 'New environment' : 'Edit environment',
      ),
      actions: [TextButton(onPressed: _save, child: const Text('Save'))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _nameController,
          autofocus: widget.environment == null,
          decoration: const InputDecoration(
            labelText: 'Environment name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Use variables as {{name}} in URLs, params, headers, and bodies.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        KeyValueEditor(
          label: 'Variables',
          initialEntries: _variables,
          onChanged: (entries) => _variables = entries,
        ),
      ],
    ),
  );
}

class _EmptyEnvironments extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune_outlined, size: 48),
          SizedBox(height: 12),
          Text('No environments yet'),
          SizedBox(height: 6),
          Text('Create one to reuse values across your requests.'),
        ],
      ),
    ),
  );
}
