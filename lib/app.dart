import 'package:flutter/material.dart';
import 'package:lurc/screens/request/request_screen.dart';
import 'package:lurc/theme/lurc_theme.dart';

class LurcApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lurc',
      debugShowCheckedModeBanner: false,
      theme: LurcTheme.light(),
      darkTheme: LurcTheme.dark(),
      themeMode: ThemeMode.system,
      home: const RequestScreen(),
    );
  }
}
