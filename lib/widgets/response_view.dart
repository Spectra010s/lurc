import 'package:flutter/material.dart';
import 'package:lurc/core/http/response.dart';

class ResponseView extends StatelessWidget {
  const ResponseView({
    required this.response,
    required this.error,
    required this.loading,
    super.key,
  });

  final HttpResponse? response;
  final String? error;
  final bool loading;

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

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${response!.statusCode} • ${response!.duration.inMilliseconds} ms',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(response!.body),
            ),
          ),
        ],
      ),
    );
  }
}
