import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/environments/environment.dart';
import 'package:lurc/core/environments/environment_controller.dart';
import 'package:lurc/theme/lurc_theme.dart';
import 'package:lurc/widgets/key_value_editor.dart';

List<EnvironmentVariable> _environmentEntries(List<KeyValueEntry> entries) => [
  for (final entry in entries)
    if (entry.enabled && entry.key.trim().isNotEmpty)
      EnvironmentVariable(
        key: entry.key.trim(),
        value: entry.value,
        secret: entry.secret,
      ),
];

class EnvironmentsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environments = ref.watch(environmentsControllerProvider);
    final activeId = ref.watch(activeEnvironmentIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Environments')),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _editEnvironment(context, ref),
        tooltip: 'New environment',
        child: const Icon(Icons.add),
      ),
      body: environments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load environments.\n$error')),
        data: (items) {
          if (items.isEmpty) return const _EmptyEnvironments();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              LurcSpacing.sm,
              LurcSpacing.sm,
              LurcSpacing.sm,
              96,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final environment = items[index];
              final active = environment.id == activeId;
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: LurcSpacing.lg,
                  vertical: LurcSpacing.xs,
                ),
                leading: Icon(
                  active ? Icons.check_circle : Icons.circle_outlined,
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  environment.name,
                  style: active
                      ? const TextStyle(fontWeight: FontWeight.w600)
                      : null,
                ),
                subtitle: Text(
                  '${environment.variables.length} variable'
                  '${environment.variables.length == 1 ? '' : 's'}',
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
                        _deleteEnvironment(context, ref, environment),
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

  Future<void> _deleteEnvironment(
    BuildContext context,
    WidgetRef ref,
    Environment environment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete environment?'),
        content: Text(
          '“${environment.name}” and its variables will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(environmentsControllerProvider.notifier)
        .delete(environment.id);
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
        widget.environment?.variables
            .map(
              (variable) => KeyValueEntry(
                key: variable.key,
                value: variable.value,
                secret: variable.secret,
              ),
            )
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
        variables: _environmentEntries(_variables),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.environment == null ? 'New environment' : 'Edit environment',
      ),
      actions: [
        TextButton(
          onPressed: _nameController.text.trim().isEmpty ? null : _save,
          child: const Text('Save'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(LurcSpacing.lg),
      children: [
        TextField(
          controller: _nameController,
          autofocus: widget.environment == null,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Environment name',
            hintText: 'Development',
          ),
        ),
        const SizedBox(height: LurcSpacing.xl),
        Text(
          'Use variables as {{name}} in URLs, params, headers, and bodies.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: LurcSpacing.sm),
        KeyValueEditor(
          label: 'Variables',
          initialEntries: _variables,
          allowSecrets: true,
          onChanged: (entries) => _variables = entries,
        ),
      ],
    ),
  );
}

class _EmptyEnvironments extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(LurcSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tune_outlined,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: LurcSpacing.md),
          Text(
            'No environments yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: LurcSpacing.sm),
          Text(
            'Create one to reuse values across your requests.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
