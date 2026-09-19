import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:lurc/screens/history/history_controller.dart';
import 'package:lurc/theme/lurc_theme.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  HttpMethod? _method;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(requestHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Clear history',
            onPressed: history.value?.isNotEmpty ?? false
                ? () => _confirmClear(context, ref)
                : null,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _HistoryError(
          onRetry: () => ref.invalidate(requestHistoryProvider),
        ),
        data: (records) {
          if (records.isEmpty) {
            return const _HistoryState(
              icon: Icons.history_rounded,
              title: 'No request history',
              message: 'Requests you send will appear here for quick reuse.',
            );
          }
          final query = _searchController.text.trim().toLowerCase();
          final filtered = records.where((record) {
            final matchesMethod =
                _method == null || record.request.method == _method;
            final matchesQuery = query.isEmpty ||
                record.request.url.toLowerCase().contains(query);
            return matchesMethod && matchesQuery;
          }).toList(growable: false);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LurcSpacing.lg,
                  LurcSpacing.sm,
                  LurcSpacing.lg,
                  LurcSpacing.xs,
                ),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search requests',
                  leading: const Icon(Icons.search),
                  constraints: const BoxConstraints(minHeight: 48),
                  elevation: const WidgetStatePropertyAll(0),
                  trailing: _searchController.text.isEmpty
                      ? null
                      : [
                          IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: LurcSpacing.lg,
                    vertical: LurcSpacing.xs,
                  ),
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _method == null,
                      onSelected: (_) => setState(() => _method = null),
                    ),
                    const SizedBox(width: LurcSpacing.sm),
                    for (final method in HttpMethod.values) ...[
                      ChoiceChip(
                        label: Text(method.name.toUpperCase()),
                        selected: _method == method,
                        onSelected: (_) => setState(() => _method = method),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const _HistoryState(
                        icon: Icons.search_off_rounded,
                        title: 'No matches',
                        message: 'Try another URL or request method.',
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        padding: const EdgeInsets.only(
                          top: LurcSpacing.xs,
                          bottom: LurcSpacing.lg,
                        ),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _HistoryTile(record: filtered[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This removes all locally stored request history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(requestHistoryProvider.notifier).clear();
    }
  }
}

class _HistoryTile extends ConsumerWidget {
  const new({required this.record});
  final RequestRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = record.request;
    final status = record.statusCode == null ? '' : '${record.statusCode}';
    final duration =
        record.durationMs == null ? '' : '${record.durationMs} ms';
    final metadata = [
      status,
      duration,
      _formatTime(record.sentAt),
    ].where((value) => value.isNotEmpty).join(' • ');

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LurcSpacing.lg,
        vertical: LurcSpacing.xs,
      ),
      onTap: () => Navigator.pop(context, record),
      title: Text(
        request.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(metadata),
      leading: SizedBox(
        width: 54,
        child: Text(
          request.method.name.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'History actions',
        onSelected: (value) async {
          if (value != 'delete') return;
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Delete history entry?'),
              content: Text(request.url),
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
          if (confirmed ?? false) {
            await ref.read(requestHistoryProvider.notifier).delete(record.id);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'delete', child: Text('Delete from history')),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day} $hour:$minute';
  }
}


class _HistoryState extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(LurcSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: LurcSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: LurcSpacing.sm),
          Text(
            message,
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


class _HistoryError extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(LurcSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: LurcSpacing.md),
          Text(
            'Could not load history',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: LurcSpacing.sm),
          Text(
            'Your local request history could not be opened.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: LurcSpacing.lg),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
