import 'package:flutter/material.dart';
import 'package:lurc/screens/request/request_screen.dart';

class LurcApp extends StatelessWidget {
  const LurcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lurc',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const RequestScreen(),
    );
  }
}
