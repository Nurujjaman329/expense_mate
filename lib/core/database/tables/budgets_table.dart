import 'package:drift/drift.dart';

/// Budget limits by period and category.
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get period => text()();
  TextColumn get categoryId => text().nullable()();
  RealColumn get spent => real().withDefault(const Constant(0))();
  RealColumn get alertThreshold =>
      real().withDefault(const Constant(0.8))();
  BoolColumn get alertEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
