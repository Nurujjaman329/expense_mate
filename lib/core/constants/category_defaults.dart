/// Default income and expense category definitions seeded on first launch.
class CategoryDefaults {
  CategoryDefaults._();

  static const List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Salary', 'icon': 'work', 'color': 0xFF4CAF50},
    {'name': 'Business', 'icon': 'business', 'color': 0xFF2196F3},
    {'name': 'Bonus', 'icon': 'stars', 'color': 0xFFFF9800},
    {'name': 'Investment', 'icon': 'trending_up', 'color': 0xFF9C27B0},
    {'name': 'Gift', 'icon': 'card_giftcard', 'color': 0xFFE91E63},
    {'name': 'Freelancing', 'icon': 'laptop', 'color': 0xFF00BCD4},
    {'name': 'Cashback', 'icon': 'replay', 'color': 0xFF8BC34A},
    {'name': 'Others', 'icon': 'more_horiz', 'color': 0xFF607D8B},
  ];

  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food', 'icon': 'restaurant', 'color': 0xFFFF5722},
    {'name': 'Transport', 'icon': 'directions_car', 'color': 0xFF3F51B5},
    {'name': 'Fuel', 'icon': 'local_gas_station', 'color': 0xFFFF9800},
    {'name': 'Shopping', 'icon': 'shopping_bag', 'color': 0xFFE91E63},
    {'name': 'Groceries', 'icon': 'shopping_cart', 'color': 0xFF4CAF50},
    {'name': 'Health', 'icon': 'local_hospital', 'color': 0xFFF44336},
    {'name': 'Education', 'icon': 'school', 'color': 0xFF2196F3},
    {'name': 'Travel', 'icon': 'flight', 'color': 0xFF009688},
    {'name': 'Entertainment', 'icon': 'movie', 'color': 0xFF9C27B0},
    {'name': 'Electricity', 'icon': 'bolt', 'color': 0xFFFFEB3B},
    {'name': 'Water', 'icon': 'water_drop', 'color': 0xFF03A9F4},
    {'name': 'Gas', 'icon': 'propane', 'color': 0xFF795548},
    {'name': 'Internet', 'icon': 'wifi', 'color': 0xFF00BCD4},
    {'name': 'Phone', 'icon': 'phone_android', 'color': 0xFF673AB7},
    {'name': 'Insurance', 'icon': 'shield', 'color': 0xFF607D8B},
    {'name': 'Rent', 'icon': 'home', 'color': 0xFF8BC34A},
    {'name': 'Tax', 'icon': 'receipt_long', 'color': 0xFF455A64},
    {'name': 'Subscriptions', 'icon': 'subscriptions', 'color': 0xFFFF4081},
    {'name': 'Others', 'icon': 'more_horiz', 'color': 0xFF9E9E9E},
  ];
}
