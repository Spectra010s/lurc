import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/http/request_record.dart';
import 'package:lurc/screens/history/history_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load request history.\n$error'),
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text('No requests yet.'));
          }

          return ListView.separated(
            itemCount: records.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final record = records[index];
              return _HistoryTile(record: record);
            },
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
        content: const Text('This removes all locally stored request history.'),
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
    final duration = record.durationMs == null ? '' : '${record.durationMs} ms';

    return ListTile(
      onTap: () => Navigator.pop(context, record),
      title: Text(
        request.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [status, duration, _formatTime(record.sentAt)]
            .where((value) => value.isNotEmpty)
            .join(' • '),
      ),
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
