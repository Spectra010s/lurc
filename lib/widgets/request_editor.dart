import 'package:flutter/material.dart';

class RequestEditor extends StatelessWidget {
  const RequestEditor({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        minLines: 4,
        maxLines: 8,
        decoration: const InputDecoration(
          labelText: 'Request body',
          alignLabelWithHint: true,
          hintText: '{"key":"value"}',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
