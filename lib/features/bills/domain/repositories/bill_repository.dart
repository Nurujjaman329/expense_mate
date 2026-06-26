import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/features/bills/domain/entities/bill_entity.dart';

abstract class BillRepository {
  Stream<List<BillEntity>> watchBills(String userId);

  Future<Result<BillEntity>> createBill(BillEntity bill);

  Future<Result<BillEntity>> updateBill(BillEntity bill);

  Future<Result<void>> deleteBill(String id);

  Future<Result<BillEntity>> markAsPaid(BillEntity bill);

  Future<Result<void>> syncFromRemote(String userId);
}
