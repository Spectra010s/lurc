import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lurc/core/saved_requests/collection.dart';
import 'package:lurc/core/saved_requests/saved_request.dart';
import 'package:lurc/core/saved_requests/saved_requests_controller.dart';

class CollectionsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(savedRequestsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCollection(context, ref),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Collection'),
      ),
      body: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Could not load collections.\n$error'),
        ),
        data: (state) {
          if (state.collections.isEmpty && state.requests.isEmpty) {
            return const _EmptyLibrary();
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (final collection in state.collections)
                _CollectionSection(
                  collection: collection,
                  requests: state.requestsInCollection(collection.id),
                ),
              if (state.requestsInCollection(null).isNotEmpty)
                _UnfiledSection(
                  requests: state.requestsInCollection(null),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Collection name'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim(),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await ref
        .read(savedRequestsControllerProvider.notifier)
        .saveCollection(Collection(id: id, name: name));
  }
}

class _CollectionSection extends ConsumerWidget {
  const new({required this.collection, required this.requests});

  final Collection collection;
  final List<SavedRequest> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ExpansionTile(
    initiallyExpanded: true,
    leading: const Icon(Icons.folder_outlined),
    title: Text(collection.name),
    subtitle: Text(
      '${requests.length} request${requests.length == 1 ? '' : 's'}',
    ),
    trailing: PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          unawaited(
            ref
                .read(savedRequestsControllerProvider.notifier)
                .deleteCollection(collection.id),
          );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete collection'),
        ),
      ],
    ),
    children: requests.isEmpty
        ? const [ListTile(title: Text('No saved requests'))]
        : requests
            .map((request) => _SavedRequestTile(request: request))
            .toList(),
  );
}

class _UnfiledSection extends StatelessWidget {
  const new({required this.requests});

  final List<SavedRequest> requests;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    leading: const Icon(Icons.inventory_2_outlined),
    title: const Text('Unfiled'),
    children: requests
        .map((request) => _SavedRequestTile(request: request))
        .toList(),
  );
}

class _SavedRequestTile extends ConsumerWidget {
  const new({required this.request});

  final SavedRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    onTap: () => Navigator.pop(context, request),
    leading: SizedBox(
      width: 48,
      child: Text(
        request.method.name.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium,
      ),
    ),
    title: Text(request.name),
    subtitle: Text(
      request.url,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: IconButton(
      tooltip: 'Delete saved request',
      icon: const Icon(Icons.delete_outline),
      onPressed: () => ref
          .read(savedRequestsControllerProvider.notifier)
          .deleteRequest(request.id),
    ),
  );
}

class _EmptyLibrary extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_outlined, size: 48),
          SizedBox(height: 12),
          Text('No collections yet'),
          SizedBox(height: 6),
          Text(
            'Create a collection, then save requests from the request '
            'workspace.',
          ),
        ],
      ),
    ),
  );
}
