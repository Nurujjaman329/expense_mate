/// Domain enums shared across features.
library;

enum TransactionType {
  income,
  expense,
  transfer;

  String get label => switch (this) {
        income => 'Income',
        expense => 'Expense',
        transfer => 'Transfer',
      };
}

enum PaymentMethod {
  cash,
  card,
  bankTransfer,
  mobileBanking,
  digitalWallet,
  crypto,
  other;

  String get label => switch (this) {
        cash => 'Cash',
        card => 'Card',
        bankTransfer => 'Bank Transfer',
        mobileBanking => 'Mobile Banking',
        digitalWallet => 'Digital Wallet',
        crypto => 'Crypto',
        other => 'Other',
      };
}

enum WalletType {
  cash,
  bank,
  creditCard,
  debitCard,
  bkash,
  nagad,
  rocket,
  payPal,
  wise,
  crypto;

  String get label => switch (this) {
        cash => 'Cash',
        bank => 'Bank',
        creditCard => 'Credit Card',
        debitCard => 'Debit Card',
        bkash => 'bKash',
        nagad => 'Nagad',
        rocket => 'Rocket',
        payPal => 'PayPal',
        wise => 'Wise',
        crypto => 'Crypto',
      };
}

enum BudgetPeriod {
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

enum GoalType {
  emergencyFund,
  vacation,
  house,
  car,
  education,
  wedding,
  investment,
  other;

  String get label => switch (this) {
        emergencyFund => 'Emergency Fund',
        vacation => 'Vacation',
        house => 'House',
        car => 'Car',
        education => 'Education',
        wedding => 'Wedding',
        investment => 'Investment',
        other => 'Other',
      };

  String get icon => switch (this) {
        emergencyFund => 'shield',
        vacation => 'flight',
        house => 'home',
        car => 'directions_car',
        education => 'school',
        wedding => 'favorite',
        investment => 'trending_up',
        other => 'savings',
      };

  int get color => switch (this) {
        emergencyFund => 0xFFF44336,
        vacation => 0xFF2196F3,
        house => 0xFF4CAF50,
        car => 0xFF9C27B0,
        education => 0xFF009688,
        wedding => 0xFFE91E63,
        investment => 0xFFFF9800,
        other => 0xFF607D8B,
      };
}

enum SyncStatus {
  synced,
  pending,
  failed;

  String get label => switch (this) {
        synced => 'Synced',
        pending => 'Pending',
        failed => 'Failed',
      };
}

enum ThemeModeOption {
  system,
  light,
  dark;

  String get label => switch (this) {
        system => 'System',
        light => 'Light',
        dark => 'Dark',
      };
}

enum RecurringRule {
  weekly,
  monthly,
  yearly;

  String get label => switch (this) {
        weekly => 'Weekly',
        monthly => 'Monthly',
        yearly => 'Yearly',
      };
}

enum NotificationType {
  billReminder,
  budgetAlert,
  goalMilestone,
  system;

  String get label => switch (this) {
        billReminder => 'Bill Reminder',
        budgetAlert => 'Budget Alert',
        goalMilestone => 'Goal Milestone',
        system => 'System',
      };

  String get icon => switch (this) {
        billReminder => 'receipt_long',
        budgetAlert => 'pie_chart',
        goalMilestone => 'flag',
        system => 'notifications',
      };
}
