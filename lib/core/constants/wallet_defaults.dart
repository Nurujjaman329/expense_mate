import 'package:expense_mate/core/constants/app_enums.dart';

/// Default wallet seeded for new users.
class WalletDefaults {
  WalletDefaults._();

  static const defaultWalletName = 'Cash';
  static const defaultWalletType = WalletType.cash;
  static const defaultIcon = 'account_balance_wallet';
  static const defaultColor = 0xFF00695C;
}
