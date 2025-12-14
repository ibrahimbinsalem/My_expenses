import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/local_expense_repository.dart';
import '../../../data/services/ocr_service.dart';
import '../../../data/services/voice_entry_service.dart';

class TransactionsController extends GetxController {
  TransactionsController(
    this._repository,
    this._ocrService,
    this._voiceEntryService,
  );

  final LocalExpenseRepository _repository;
  final ReceiptOcrService _ocrService;
  final VoiceEntryService _voiceEntryService;

  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isSaving = false.obs;
  final categories = <CategoryModel>[].obs;
  final wallets = <WalletModel>[].obs;
  final selectedCategoryId = RxnInt();
  final selectedWalletId = RxnInt();
  final selectedType = TransactionType.expense.obs;
  final selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadFormData();
  }

  Future<void> loadFormData() async {
    categories.assignAll(await _repository.fetchCategories());
    final loadedWallets = await _repository.fetchWallets();
    wallets.assignAll(loadedWallets);
    if (loadedWallets.isNotEmpty) {
      selectedWalletId.value = loadedWallets.first.id;
    }
    if (categories.isNotEmpty) {
      selectedCategoryId.value = categories.first.id;
    }
  }

  Future<void> saveTransaction() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (selectedWalletId.value == null || selectedCategoryId.value == null) {
      return;
    }
    isSaving.value = true;
    try {
      final transaction = TransactionModel(
        walletId: selectedWalletId.value!,
        categoryId: selectedCategoryId.value!,
        amount: double.parse(amountController.text),
        type: selectedType.value,
        note: noteController.text,
        date: selectedDate.value,
      );
      await _repository.addTransaction(transaction);
      Get.back(result: true);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> autofillFromReceipt(String imagePath) async {
    final receiptData = await _ocrService.parseReceipt(imagePath);
    final amount = receiptData['amount'] as num?;
    if (amount != null) {
      amountController.text = amount.toString();
    }
    final date = receiptData['date'] as String?;
    if (date != null) {
      selectedDate.value = DateTime.parse(date);
    }
  }

  Future<void> handleVoiceCommand(String audioPath) async {
    final sentence = await _voiceEntryService.transcribe(audioPath);
    final parsed = _voiceEntryService.parseIntent(sentence);
    final amount = parsed['amount'] as double?;
    if (amount != null) {
      amountController.text = amount.toString();
    }
    noteController.text = parsed['note'] as String? ?? '';
  }

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
