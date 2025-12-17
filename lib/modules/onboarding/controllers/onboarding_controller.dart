import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/settings_service.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/currency_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/local_expense_repository.dart';
import '../../../routes/app_routes.dart';
import '../../settings/controllers/settings_controller.dart';

class OnboardingController extends GetxController {
  OnboardingController(this._repository, this._settingsService);

  final LocalExpenseRepository _repository;
  final SettingsService _settingsService;

  final pageController = PageController();
  final currentPage = 0.obs;
  final nameController = TextEditingController();
  final selectedCategories = <int>{}.obs;
  final isSaving = false.obs;
  final isSetupValid = false.obs;
  final currencies = <CurrencyModel>[].obs;

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

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(_validateSetup);
    ever(currencies, (_) => _validateSetup());
    ever(selectedCategories, (_) => _validateSetup());
    loadCurrencies();
    _validateSetup();
  }

  Future<void> loadCurrencies() async {
    try {
      final data = await _repository.fetchCurrencies();
      currencies.assignAll(data);
    } catch (_) {
      // ignore
    }
    _validateSetup();
  }

  Future<bool> addInitialCurrencies(
    List<Map<String, String>> selections,
  ) async {
    if (selections.isEmpty) return false;
    var added = false;
    for (final option in selections) {
      final code = option['code']?.toUpperCase();
      final name = option['name'];
      if (code == null || name == null) continue;
      final exists = await _repository.currencyCodeExists(code);
      if (exists) continue;
      await _repository.insertCurrency(
        CurrencyModel(code: code, name: name),
      );
      added = true;
    }
    if (added) {
      await loadCurrencies();
    }
    _validateSetup();
    return added;
  }

  Future<void> removeCurrency(CurrencyModel currency) async {
    if (currency.id == null) {
      currencies.remove(currency);
      _validateSetup();
      return;
    }
    await _repository.deleteCurrency(currency.id!);
    await loadCurrencies();
    _validateSetup();
  }

  Future<void> completeSetup() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('common.alert'.tr, 'أدخل اسم المستخدم لإكمال الإعداد.'.tr);
      return;
    }
    if (currencies.isEmpty) {
      Get.snackbar(
        'common.alert'.tr,
        'اختر عملة واحدة على الأقل قبل المتابعة.'.tr,
      );
      return;
    }
    if (selectedCategories.isEmpty) {
      Get.snackbar(
        'common.alert'.tr,
        'اختر فئة واحدة على الأقل للمتابعة.'.tr,
      );
      return;
    }
    isSaving.value = true;
    try {
      await _repository.saveUser(
        UserModel(name: nameController.text.trim(), createdAt: DateTime.now()),
      );

      if (selectedCategories.isNotEmpty) {
        for (final index in selectedCategories) {
          final category = recommendedCategories[index];
          await _repository.insertCategory(
            CategoryModel(
              name: (category['name']! as String).tr,
              icon: category['icon']! as String,
              color: category['color']! as int,
            ),
          );
        }
      }

      await _settingsService.setOnboardingComplete();
      await _refreshSettingsData();
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
    _validateSetup();
  }

  void _validateSetup() {
    final hasName = nameController.text.trim().isNotEmpty;
    final hasCurrencies = currencies.isNotEmpty;
    final hasCategories = selectedCategories.isNotEmpty;
    isSetupValid.value = hasName && hasCurrencies && hasCategories;
  }

  Future<void> _refreshSettingsData() async {
    if (!Get.isRegistered<SettingsController>()) return;
    final settingsController = Get.find<SettingsController>();
    await settingsController.loadCurrencies();
    await settingsController.loadCategories();
    await settingsController.loadUser();
  }

  @override
  void onClose() {
    pageController.dispose();
    nameController.dispose();
    super.onClose();
  }
}
