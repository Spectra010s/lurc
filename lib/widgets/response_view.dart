import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lurc/core/http/response.dart';
import 'package:lurc/theme/lurc_theme.dart';

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
      return const _ResponseState(
        icon: Icons.sync_rounded,
        title: 'Sending request',
        message: 'Waiting for the server to respond…',
        loading: true,
      );
    }

    if (error != null) {
      return _ResponseState(
        icon: Icons.error_outline_rounded,
        title: 'Request failed',
        message: error!,
      );
    }

    if (response == null) {
      return const _ResponseState(
        icon: Icons.data_object_rounded,
        title: 'No response yet',
        message: 'Send a request to inspect its status, body, and headers.',
      );
    }

    final currentResponse = response!;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LurcSpacing.lg,
              LurcSpacing.md,
              LurcSpacing.lg,
              LurcSpacing.sm,
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  '${currentResponse.statusCode}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('${currentResponse.duration.inMilliseconds} ms'),
                Text('${utf8.encode(currentResponse.body).length} bytes'),
              ],
            ),
          ),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Body'),
              Tab(text: 'Headers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(LurcSpacing.lg),
                  child: SelectableText(
                    currentResponse.body.isEmpty
                        ? 'Empty response body'
                        : _formattedBody(currentResponse.body),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontFamily: 'monospace', height: 1.5),
                  ),
                ),
                ListView(
                  padding: const EdgeInsets.all(LurcSpacing.lg),
                  children: currentResponse.headers.entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: LurcSpacing.sm,
                          ),
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


class _ResponseState extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(LurcSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          const SizedBox(height: LurcSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: LurcSpacing.sm),
          SelectableText(
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
