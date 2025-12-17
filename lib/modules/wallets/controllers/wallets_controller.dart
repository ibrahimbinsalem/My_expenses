import 'package:get/get.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/local_expense_repository.dart';

class WalletsController extends GetxController {
  WalletsController(this._repository);

  final LocalExpenseRepository _repository;

  final wallets = <WalletModel>[].obs;
  final isLoading = false.obs;
  final walletTypes = ['cash', 'bank', 'digital'];
  final selectedType = 'cash'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWallets();
  }

  Future<void> fetchWallets() async {
    isLoading.value = true;
    try {
      wallets.assignAll(await _repository.fetchWallets());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addWallet({
    required String name,
    required String currencyCode,
    required double initialBalance,
    required String type,
  }) async {
    if (name.trim().isEmpty) return false;
    final normalizedCurrency = currencyCode.toUpperCase();
    final walletId = await _repository.insertWallet(
      WalletModel(
        name: name.trim(),
        type: type,
        balance: 0,
        currency: normalizedCurrency,
        createdAt: DateTime.now(),
        isGoal: false,
      ),
    );
    if (initialBalance > 0) {
      final depositCategoryId = await _repository.ensureSystemCategory(
        name: 'شحن رصيد'.tr,
        icon: 'savings',
        color: 0xFF4CAF50,
      );
      await _repository.addTransaction(
        TransactionModel(
          walletId: walletId,
          categoryId: depositCategoryId,
          amount: initialBalance,
          type: TransactionType.income,
          note: 'رصيد افتتاحي'.tr,
          date: DateTime.now(),
        ),
      );
    }
    return true;
  }

  Future<bool> renameWallet(WalletModel wallet, String newName) async {
    if (wallet.id == null) return false;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    await _repository.updateWallet(wallet.copyWith(name: trimmed));
    await fetchWallets();
    return true;
  }

  Future<void> deleteWallet(WalletModel wallet) async {
    if (wallet.id == null) return;
    await _repository.deleteWallet(wallet.id!);
    await fetchWallets();
  }
}
