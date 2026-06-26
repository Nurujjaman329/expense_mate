import 'package:flutter/material.dart';

/// Maps stored icon name strings to Material [IconData].
class IconMapper {
  IconMapper._();

  static const _icons = <String, IconData>{
    'work': Icons.work_outline,
    'business': Icons.business_outlined,
    'stars': Icons.stars_outlined,
    'trending_up': Icons.trending_up,
    'card_giftcard': Icons.card_giftcard_outlined,
    'laptop': Icons.laptop_mac_outlined,
    'replay': Icons.replay,
    'restaurant': Icons.restaurant_outlined,
    'directions_car': Icons.directions_car_outlined,
    'local_gas_station': Icons.local_gas_station_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'shopping_cart': Icons.shopping_cart_outlined,
    'local_hospital': Icons.local_hospital_outlined,
    'school': Icons.school_outlined,
    'flight': Icons.flight_outlined,
    'movie': Icons.movie_outlined,
    'bolt': Icons.bolt_outlined,
    'water_drop': Icons.water_drop_outlined,
    'propane': Icons.propane_outlined,
    'wifi': Icons.wifi_outlined,
    'phone_android': Icons.phone_android_outlined,
    'shield': Icons.shield_outlined,
    'home': Icons.home_outlined,
    'receipt_long': Icons.receipt_long_outlined,
    'subscriptions': Icons.subscriptions_outlined,
    'account_balance_wallet': Icons.account_balance_wallet_outlined,
    'account_balance': Icons.account_balance_outlined,
    'credit_card': Icons.credit_card_outlined,
    'payments': Icons.payments_outlined,
    'currency_bitcoin': Icons.currency_bitcoin_outlined,
    'more_horiz': Icons.more_horiz,
    'swap_horiz': Icons.swap_horiz,
  };

  static IconData fromName(String? name) {
    if (name == null || name.isEmpty) return Icons.category_outlined;
    return _icons[name] ?? Icons.category_outlined;
  }
}
