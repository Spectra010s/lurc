import 'package:flutter/material.dart';
import 'package:lurc/screens/request/request_screen.dart';
import 'package:lurc/theme/lurc_theme.dart';
import 'package:lurc/theme/theme_mode_controller.dart';

class LurcApp extends StatefulWidget {
  const new({super.key});

  @override
  State<LurcApp> createState() => _LurcAppState();
}

class _LurcAppState extends State<LurcApp> {
  ThemeModeController? _themeController;

  @override
  void initState() {
    super.initState();
    ThemeModeController.load().then((controller) {
      if (!mounted) return;
      setState(() => _themeController = controller);
    });
  }

  @override
  void dispose() {
    _themeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _themeController;
    return MaterialApp(
      title: 'Lurc',
      theme: LurcTheme.light(),
      darkTheme: LurcTheme.dark(),
      themeMode: controller?.mode ?? ThemeMode.system,
      home: RequestScreen(themeController: controller),
    );
  }
}
