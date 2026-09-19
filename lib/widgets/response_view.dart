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
    final statusCode = currentResponse.statusCode;
    final statusColor = statusCode >= 200 && statusCode < 400
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

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
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LurcSpacing.sm,
                      vertical: LurcSpacing.xs,
                    ),
                    child: Text(
                      '$statusCode',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _ResponseMetric(
                  icon: Icons.schedule_outlined,
                  value: '${currentResponse.duration.inMilliseconds} ms',
                ),
                _ResponseMetric(
                  icon: Icons.data_object_outlined,
                  value: '${utf8.encode(currentResponse.body).length} bytes',
                ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerHeight: 1,
            labelPadding: const EdgeInsets.symmetric(
              horizontal: LurcSpacing.lg,
            ),
            tabs: [
              const Tab(text: 'Body'),
              Tab(text: 'Headers (${currentResponse.headers.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                currentResponse.body.isEmpty
                    ? const _ResponseState(
                        icon: Icons.inbox_outlined,
                        title: 'Empty response body',
                        message: 'The server returned a response with no body.',
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(LurcSpacing.lg),
                        child: SelectableText(
                          _formattedBody(currentResponse.body),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontFamily: 'monospace',
                                height: 1.5,
                              ),
                        ),
                      ),
                currentResponse.headers.isEmpty
                    ? const _ResponseState(
                        icon: Icons.notes_rounded,
                        title: 'No response headers',
                        message: 'The server returned no headers to inspect.',
                      )
                    : ListView(
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

class _ResponseMetric extends StatelessWidget {
  const new({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 14,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: LurcSpacing.xs),
      Text(
        value,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
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
