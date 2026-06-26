/// Firestore collection and field name constants.
/// Centralizes collection paths to prevent typos across repositories.
class FirestoreConstants {
  FirestoreConstants._();

  // Collections
  static const String users = 'users';
  static const String wallets = 'wallets';
  static const String transactions = 'transactions';
  static const String categories = 'categories';
  static const String budgets = 'budgets';
  static const String goals = 'goals';
  static const String savings = 'savings';
  static const String bills = 'bills';
  static const String notifications = 'notifications';
  static const String settings = 'settings';
  static const String receipts = 'receipts';

  // Common fields
  static const String userId = 'userId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String isDeleted = 'isDeleted';
}
