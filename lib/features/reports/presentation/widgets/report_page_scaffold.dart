import 'package:flutter/material.dart';

/// Reusable scaffold for report pages.
class ReportPageScaffold extends StatelessWidget {
  const ReportPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.filterBar,
    this.summaryCards,
    this.actions,
  });

  final String title;
  final Widget child;
  final Widget? filterBar;
  final Widget? summaryCards;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
          if (filterBar != null) ...[
            const SizedBox(height: 16),
            filterBar!,
          ],
          if (summaryCards != null) ...[
            const SizedBox(height: 20),
            summaryCards!,
          ],
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }
}
