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
