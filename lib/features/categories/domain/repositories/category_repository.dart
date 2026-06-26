import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';

abstract class CategoryRepository {
  Stream<List<CategoryEntity>> watchCategories(String userId);

  Future<Result<List<CategoryEntity>>> getCategoriesByType(
    String userId,
    TransactionType type,
  );

  Future<Result<void>> syncFromRemote(String userId);
}
