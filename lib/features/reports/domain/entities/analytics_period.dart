/// Time ranges for analytics and reports.
enum AnalyticsPeriod {
  daily,
  weekly,
  monthly,
  yearly;

  String get label => switch (this) {
        daily => 'Daily',
        weekly => 'Weekly',
        monthly => 'Monthly',
        yearly => 'Yearly',
      };
}
