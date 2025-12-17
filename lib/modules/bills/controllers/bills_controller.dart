import 'package:get/get.dart';

import '../../../data/models/bill_group_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/local_expense_repository.dart';

class BillsController extends GetxController {
  BillsController(this._repository);

  final LocalExpenseRepository _repository;

  final bills = <BillGroupModel>[].obs;
  final wallets = <WalletModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _repository.fetchBillGroups(),
        _repository.fetchWallets(),
      ]);
      bills.assignAll(results[0] as List<BillGroupModel>);
      wallets.assignAll(results[1] as List<WalletModel>);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshBills() async {
    bills.assignAll(await _repository.fetchBillGroups());
  }

  Future<bool> addBill({
    required String title,
    String? description,
    required DateTime eventDate,
    required double total,
    required String currency,
    required List<BillParticipantModel> participants,
  }) async {
    final group = BillGroupModel(
      title: title,
      description: description,
      eventDate: eventDate,
      total: total,
      currency: currency,
      createdAt: DateTime.now(),
      participants: participants,
    );
    final saved = await _repository.insertBillGroup(group);
    if (saved == null) return false;
    bills.insert(0, saved);
    return true;
  }

  Future<void> deleteBill(int id) async {
    await _repository.deleteBillGroup(id);
    bills.removeWhere((bill) => bill.id == id);
  }

  Future<void> markParticipantAsPaid(
    BillGroupModel bill,
    BillParticipantModel participant,
  ) async {
    if (participant.id == null) return;
    await _repository.updateBillParticipantPaid(
      participant.id!,
      participant.share,
    );
    if (participant.walletId != null) {
      final categoryId = await _repository.ensureSystemCategory(
        name: 'الفواتير المشتركة',
        icon: 'receipt_long',
        color: 0xFF8E44AD,
      );
      await _repository.addTransaction(
        TransactionModel(
          walletId: participant.walletId!,
          categoryId: categoryId,
          amount: participant.share,
          type: TransactionType.expense,
          note: 'دفتر الفواتير - ${bill.title} (${participant.name})',
          date: DateTime.now(),
        ),
      );
    }
    await refreshBills();
  }
}
