import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isSaving = false.obs;
  final categories = <CategoryModel>[].obs;
  final wallets = <WalletModel>[].obs;
  final selectedCategoryId = RxnInt();
  final selectedWalletId = RxnInt();
  final selectedDate = DateTime.now().obs;
  final attachedReceiptPath = RxnString();
  final attachedReceiptName = RxnString();

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
    final amount = double.parse(amountController.text);
    WalletModel? wallet;
    for (final item in wallets) {
      if (item.id == selectedWalletId.value) {
        wallet = item;
        break;
      }
    }
    if (wallet != null && amount > wallet.balance) {
      Get.snackbar('common.alert'.tr, 'transactions.insufficientFunds'.tr);
      return;
    }
    final categoryId = selectedCategoryId.value;
    if (categoryId == null) {
      Get.snackbar('common.alert'.tr, 'transactions.category_required'.tr);
      return;
    }
    isSaving.value = true;
    String? archivedReceiptPath;
    try {
      archivedReceiptPath = await _archiveReceipt();
      final transaction = TransactionModel(
        walletId: selectedWalletId.value!,
        categoryId: categoryId,
        amount: amount,
        type: TransactionType.expense,
        note: noteController.text,
        date: selectedDate.value,
        imagePath: archivedReceiptPath,
      );
      await _repository.addTransaction(transaction);
      attachedReceiptPath.value = null;
      attachedReceiptName.value = null;
      Get.back(result: true);
    } catch (e) {
      if (archivedReceiptPath != null) {
        final file = File(archivedReceiptPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      Get.snackbar('common.alert'.tr, 'transactions.save_error'.tr);
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

  Future<void> pickReceiptImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null) return;
    attachedReceiptPath.value = file.path;
    attachedReceiptName.value = file.name;
  }

  void removeReceipt() {
    attachedReceiptPath.value = null;
    attachedReceiptName.value = null;
  }

  Future<void> captureReceiptPhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;
    attachedReceiptPath.value = image.path;
    attachedReceiptName.value = p.basename(image.path);
  }

  Future<String?> _archiveReceipt() async {
    final sourcePath = attachedReceiptPath.value;
    if (sourcePath == null) return null;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return null;
    final documentsDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(documentsDir.path, 'receipts'));
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    final extension = p.extension(sourcePath);
    final fileName =
        'receipt_${DateTime.now().microsecondsSinceEpoch}${extension.isNotEmpty ? extension : '.jpg'}';
    final savedPath = p.join(receiptsDir.path, fileName);
    await sourceFile.copy(savedPath);
    return savedPath;
  }

  void onWalletChanged(int? walletId) {
    selectedWalletId.value = walletId;
  }

  void onCategoryChanged(int? categoryId) {
    selectedCategoryId.value = categoryId;
  }
}
