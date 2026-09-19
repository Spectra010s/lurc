import 'package:flutter/material.dart';
import 'package:lurc/theme/lurc_theme.dart';
import 'package:lurc/theme/theme_mode_controller.dart';

class SettingsScreen extends StatelessWidget {
  const new({required this.themeController, super.key});

  final ThemeModeController themeController;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: LurcSpacing.sm),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LurcSpacing.lg,
            LurcSpacing.md,
            LurcSpacing.lg,
            LurcSpacing.sm,
          ),
          child: Text(
            'Appearance',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        RadioGroup<ThemeMode>(
          groupValue: themeController.mode,
          onChanged: (mode) {
            if (mode != null) themeController.setMode(mode);
          },
          child: const Column(
            children: [
              RadioListTile(
                value: ThemeMode.system,
                title: Text('System default'),
                subtitle: Text('Follow your Android theme'),
              ),
              RadioListTile(
                value: ThemeMode.light,
                title: Text('Light'),
              ),
              RadioListTile(
                value: ThemeMode.dark,
                title: Text('Dark'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
