import 'package:flutter/material.dart';

/// Model for sidebar navigation items.
class SidebarItemModel {
  const SidebarItemModel({
    required this.label,
    required this.icon,
    required this.path,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final String path;
  final String? tooltip;
}
