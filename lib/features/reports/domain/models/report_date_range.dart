/// Preset date range for reports.
enum ReportDatePreset {
  today,
  thisWeek,
  thisMonth,
  custom,
}

/// Date range for report filtering.
class ReportDateRange {
  const ReportDateRange({
    required this.from,
    required this.to,
    this.preset = ReportDatePreset.custom,
  });

  final DateTime from;
  final DateTime to;
  final ReportDatePreset preset;

  /// Start of today.
  static DateTime get todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// End of today (23:59:59).
  static DateTime get todayEnd {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  /// Start of this week (Monday).
  static DateTime get thisWeekStart {
    final now = DateTime.now();
    final weekday = now.weekday;
    final daysFromMonday = weekday - DateTime.monday;
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }

  /// End of this week (Sunday 23:59:59).
  static DateTime get thisWeekEnd {
    final start = thisWeekStart;
    return DateTime(
      start.year,
      start.month,
      start.day + 6,
      23,
      59,
      59,
    );
  }

  /// Start of this month.
  static DateTime get thisMonthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// End of this month.
  static DateTime get thisMonthEnd {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  static ReportDateRange today() => ReportDateRange(
        from: todayStart,
        to: todayEnd,
        preset: ReportDatePreset.today,
      );

  static ReportDateRange thisWeek() => ReportDateRange(
        from: thisWeekStart,
        to: thisWeekEnd,
        preset: ReportDatePreset.thisWeek,
      );

  static ReportDateRange thisMonth() => ReportDateRange(
        from: thisMonthStart,
        to: thisMonthEnd,
        preset: ReportDatePreset.thisMonth,
      );

  static ReportDateRange custom(DateTime from, DateTime to) => ReportDateRange(
        from: from,
        to: DateTime(to.year, to.month, to.day, 23, 59, 59),
        preset: ReportDatePreset.custom,
      );
}
