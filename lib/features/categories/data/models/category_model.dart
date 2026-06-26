import 'package:drift/drift.dart';
import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/data/firestore_mapper.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';

/// Maps between Drift, Firestore, and domain category models.
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.type,
    required super.icon,
    required super.color,
    super.isDefault,
    super.syncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory CategoryModel.fromDrift(Category row) {
    return CategoryModel(
      id: row.id,
      userId: row.userId,
      name: row.name,
      type: TransactionType.values.byName(row.type),
      icon: row.icon,
      color: row.color,
      isDefault: row.isDefault,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  factory CategoryModel.fromFirestore(String id, Map<String, dynamic> json) {
    return CategoryModel(
      id: id,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      icon: json['icon'] as String,
      color: (json['color'] as num).toInt(),
      isDefault: json['isDefault'] as bool? ?? false,
      syncStatus: SyncStatus.synced,
      createdAt: FirestoreMapper.parseDate(json['createdAt']),
      updatedAt: FirestoreMapper.parseDate(json['updatedAt']),
    );
  }

  CategoriesCompanion toCompanion({bool? isDeleted}) {
    return CategoriesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(type.name),
      icon: Value(icon),
      color: Value(color),
      isDefault: Value(isDefault),
      syncStatus: Value(syncStatus.name),
      isDeleted: Value(isDeleted ?? false),
      createdAt: Value(createdAt ?? DateTime.now()),
      updatedAt: Value(updatedAt ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type.name,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
      'isDeleted': false,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  CategoryEntity toEntity() => this;
}
