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
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectableText(error!),
      );
    }

    if (response == null) {
      return const Center(child: Text('Send a request to see the response.'));
    }

    final currentResponse = response!;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  '${currentResponse.statusCode}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${currentResponse.duration.inMilliseconds} ms'),
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
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(_formattedBody(currentResponse.body)),
                ),
                ListView(
                  padding: const EdgeInsets.all(12),
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
