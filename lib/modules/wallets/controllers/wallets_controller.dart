import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/local_expense_repository.dart';

class WalletsController extends GetxController {
  WalletsController(this._repository);

  final LocalExpenseRepository _repository;

  final wallets = <WalletModel>[].obs;
  final isLoading = false.obs;
  final nameController = TextEditingController();
  final balanceController = TextEditingController();
  final currencyController = TextEditingController(text: 'SAR');
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

  Future<void> addWallet() async {
    if (nameController.text.trim().isEmpty) return;
    await _repository.insertWallet(
      WalletModel(
        name: nameController.text.trim(),
        type: selectedType.value,
        balance: double.tryParse(balanceController.text) ?? 0,
        currency: currencyController.text,
        createdAt: DateTime.now(),
      ),
    );
    nameController.clear();
    balanceController.clear();
    await fetchWallets();
  }

  @override
  void onClose() {
    nameController.dispose();
    balanceController.dispose();
    currencyController.dispose();
    super.onClose();
  }
}
