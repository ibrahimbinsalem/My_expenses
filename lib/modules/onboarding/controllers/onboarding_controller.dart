import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/settings_service.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/local_expense_repository.dart';
import '../../../routes/app_routes.dart';

class OnboardingController extends GetxController {
  OnboardingController(this._repository, this._settingsService);

  final LocalExpenseRepository _repository;
  final SettingsService _settingsService;

  final pageController = PageController();
  final currentPage = 0.obs;
  final nameController = TextEditingController();
  final walletNameController = TextEditingController(text: 'محفظتي');
  final currencyController = TextEditingController(text: 'SAR');
  final startingBalanceController = TextEditingController(text: '0');
  final selectedCategories = <int>{}.obs;
  final isSaving = false.obs;

  final recommendedCategories = [
    {'name': 'مطاعم', 'icon': 'restaurant', 'color': 0xFFFF7675},
    {'name': 'مشتريات', 'icon': 'shopping_bag', 'color': 0xFF6C5CE7},
    {'name': 'المواصلات', 'icon': 'directions_car', 'color': 0xFF74B9FF},
    {'name': 'المنزل', 'icon': 'home', 'color': 0xFF55EFC4},
    {'name': 'الصحة', 'icon': 'vaccines', 'color': 0xFFFD9644},
    {'name': 'ترفيه', 'icon': 'celebration', 'color': 0xFFFDCB6E},
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  Future<void> completeSetup() async {
    if (nameController.text.isEmpty || walletNameController.text.isEmpty) {
      return;
    }
    isSaving.value = true;
    try {
      final userId = await _repository.insertUser(
        UserModel(name: nameController.text, createdAt: DateTime.now()),
      );

      await _repository.insertWallet(
        WalletModel(
          userId: userId,
          name: walletNameController.text,
          type: 'cash',
          balance: double.tryParse(startingBalanceController.text) ?? 0,
          currency: currencyController.text,
          createdAt: DateTime.now(),
        ),
      );

      if (selectedCategories.isNotEmpty) {
        for (final index in selectedCategories) {
          final category = recommendedCategories[index];
          await _repository.insertCategory(
            CategoryModel(
              name: category['name']! as String,
              icon: category['icon']! as String,
              color: category['color']! as int,
            ),
          );
        }
      }

      await _settingsService.setOnboardingComplete();
      Get.offAllNamed(AppRoutes.dashboard);
    } finally {
      isSaving.value = false;
    }
  }

  void toggleCategory(int index) {
    if (selectedCategories.contains(index)) {
      selectedCategories.remove(index);
    } else {
      selectedCategories.add(index);
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    nameController.dispose();
    walletNameController.dispose();
    currencyController.dispose();
    startingBalanceController.dispose();
    super.onClose();
  }
}
