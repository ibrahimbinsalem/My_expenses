import 'package:get/get.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/local_expense_repository.dart';

class ReceiptsController extends GetxController {
  ReceiptsController(this._repository);

  final LocalExpenseRepository _repository;

  final receipts = <TransactionModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadReceipts();
  }

  Future<void> loadReceipts() async {
    isLoading.value = true;
    try {
      final txns = await _repository.fetchTransactions();
      receipts.assignAll(txns.where((txn) => txn.imagePath != null));
    } finally {
      isLoading.value = false;
    }
  }
}
