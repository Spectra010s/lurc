import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sample_provider.dart';

class SamplePage extends ConsumerWidget {
  const SamplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sampleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sample')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : ListView(
                  children: state.items
                      .map((e) => ListTile(title: Text(e)))
                      .toList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(sampleProvider.notifier).loadSamples(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
