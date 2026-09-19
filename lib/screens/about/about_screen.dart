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
          'API testing built for Android.',
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
          title: Text('Native mobile workspace'),
          subtitle: Text(
            'Build requests, inspect responses, save collections, and switch environments from your phone.',
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.lock_outline),
          title: Text('Local-first'),
          subtitle: Text(
            'Your request workspace and saved data stay on your device.',
          ),
        ),
      ],
    ),
  );
}
