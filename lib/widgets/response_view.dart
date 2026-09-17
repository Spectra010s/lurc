import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lurc/core/http/response.dart';

class ResponseView extends StatelessWidget {
  const new({
    required this.response,
    required this.error,
    required this.loading,
    super.key,
  });

  final HttpResponse? response;
  final String? error;
  final bool loading;

  String _formattedBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } on FormatException {
      return body;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Waiting for response…'),
          ],
        ),
      );
    }

    if (error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request failed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(error!),
          ],
        ),
      );
    }

    if (response == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ready when you are',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Send a request to inspect its status, body, and headers.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currentResponse = response!;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  'Status ${currentResponse.statusCode}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${currentResponse.duration.inMilliseconds} ms'),
                Text('${utf8.encode(currentResponse.body).length} bytes'),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Body'),
              Tab(text: 'Headers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    currentResponse.body.isEmpty
                        ? 'Empty response body'
                        : _formattedBody(currentResponse.body),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontFamily: 'monospace', height: 1.5),
                  ),
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: currentResponse.headers.entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SelectableText('${entry.key}: ${entry.value}'),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
