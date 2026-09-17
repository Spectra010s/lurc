import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/http/request.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:lurc/screens/history/history_controller.dart';

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
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load request history.\n$error'),
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text('No requests yet.'));
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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search URL',
                  leading: const Icon(Icons.search),
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
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _method == null,
                      onSelected: (_) => setState(() => _method = null),
                    ),
                    const SizedBox(width: 8),
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
                    ? const Center(child: Text('No matching requests.'))
                    : ListView.separated(
                        itemCount: filtered.length,
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
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      trailing: IconButton(
        tooltip: 'Delete request',
        onPressed: () =>
            ref.read(requestHistoryProvider.notifier).delete(record.id),
        icon: const Icon(Icons.delete_outline),
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
