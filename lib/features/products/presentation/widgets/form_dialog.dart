import 'package:flutter/material.dart';

class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.width = 480,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: child,
        ),
      ),
      actions: actions,
    );
  }
}
