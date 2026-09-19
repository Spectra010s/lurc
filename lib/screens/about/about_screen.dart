import 'package:flutter/material.dart';
import 'package:lurc/theme/lurc_theme.dart';

class AboutScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About')),
    body: ListView(
      padding: const EdgeInsets.all(LurcSpacing.xl),
      children: [
        Icon(
          Icons.api_rounded,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: LurcSpacing.lg),
        Text(
          'Lurc',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: LurcSpacing.sm),
        Text(
          'A native Android API client for building, sending, inspecting, and revisiting HTTP requests directly from your phone.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: LurcSpacing.xxl),
        const Divider(),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.phone_android_outlined),
          title: Text('Built for API work on a phone'),
          subtitle: Text(
            'Build and send HTTP requests, inspect responses, revisit history, and organize reusable requests without leaving Android.',
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.lock_outline),
          title: Text('Local-first'),
          subtitle: Text(
            'Requests are sent directly from your device. Lurc does not need a remote backend to proxy them.',
          ),
        ),
      ],
    ),
  );
}
