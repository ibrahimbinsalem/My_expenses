import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/controllers/locale_controller.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/currency_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/local_expense_repository.dart';
import '../../insights/controllers/insights_controller.dart';

class SettingsController extends GetxController {
  SettingsController(
    this._repository,
    this._themeController,
    this._localeController,
  ) : _settingsService = Get.find<SettingsService>();

  final LocalExpenseRepository _repository;
  final ThemeController _themeController;
  final LocaleController _localeController;
  final SettingsService _settingsService;
  final NotificationService _notificationService = Get.find();

  final categories = <CategoryModel>[].obs;
  final currencies = <CurrencyModel>[].obs;
  final user = Rxn<UserModel>();
  final isLoading = false.obs;
  final categoryNameController = TextEditingController();
  final budgetController = TextEditingController();
  final selectedColor = const Color(0xFF007C91).obs;
  final selectedIcon = ''.obs;
  final monthlyBudget = 3000.0.obs;
  final aiInsightsEnabled = true.obs;
  final notificationsEnabled = true.obs;
  static const List<String> _avatarEmojis = [
    '🙂',
    '🤩',
    '🚀',
    '💼',
    '🌙',
    '💰',
    '🎯',
    '🧾',
  ];
  static const List<Color> _avatarColors = [
    Color(0xFF007C91),
    Color(0xFFFFC857),
    Color(0xFF34C38F),
    Color(0xFF6C5CE7),
    Color(0xFFe17055),
    Color(0xFF2D98DA),
    Color(0xFF8D6E63),
    Color(0xFFFD9644),
  ];

  final colorOptions = const [
    Color(0xFF007C91),
    Color(0xFFFFC857),
    Color(0xFF34C38F),
    Color(0xFFFD9644),
    Color(0xFF6C5CE7),
    Color(0xFFe17055),
  ];

  final List<String> iconOptions = categoryIconMap.keys.toList();

  Rx<ThemeMode> get themeMode => _themeController.themeMode;
  bool get isDarkMode => themeMode.value == ThemeMode.dark;
  Locale get currentLocale => _localeController.locale.value;
  Rx<Locale> get localeNotifier => _localeController.locale;
  List<Locale> get supportedLocales => _localeController.supportedLocales;
  List<String> get avatarEmojis => _avatarEmojis;

  String avatarEmoji(int index) {
    return _avatarEmojis[index % _avatarEmojis.length];
  }

  Color avatarColor(int index) {
    return _avatarColors[index % _avatarColors.length];
  }

  @override
  void onInit() {
    super.onInit();
    if (selectedIcon.value.isEmpty && iconOptions.isNotEmpty) {
      selectedIcon.value = iconOptions.first;
    }
    loadCategories();
    loadCurrencies();
    loadUser();
    monthlyBudget.value = _settingsService.monthlyBudget;
    budgetController.text = monthlyBudget.value.toStringAsFixed(0);
    aiInsightsEnabled.value = _settingsService.aiInsightsEnabled;
    notificationsEnabled.value = _settingsService.notificationsEnabled;
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    try {
      categories.assignAll(await _repository.fetchCategories());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCurrencies() async {
    currencies.assignAll(await _repository.fetchCurrencies());
  }

  Future<void> loadUser() async {
    user.value = await _repository.getPrimaryUser();
  }

  Future<void> addCategory() async {
    if (categoryNameController.text.trim().isEmpty) return;
    await _repository.insertCategory(
      CategoryModel(
        name: categoryNameController.text.trim(),
        icon: selectedIcon.value,
        color: selectedColor.value.toARGB32(),
      ),
    );
    categoryNameController.clear();
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _repository.deleteCategory(id);
    await loadCategories();
  }

  Future<void> updateCategory(CategoryModel category) async {
    if (category.id == null) return;
    await _repository.updateCategory(category);
    await loadCategories();
  }

  Future<bool> addCurrenciesBulk(
    List<Map<String, String>> currencyOptions,
  ) async {
    if (currencyOptions.isEmpty) return false;
    var added = false;
    for (final option in currencyOptions) {
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
    return added;
  }

  Future<bool> updateCurrency(CurrencyModel currency, String newName) async {
    final trimmed = newName.trim();
    if (currency.id == null || trimmed.isEmpty) return false;
    await _repository.updateCurrency(
      currency.copyWith(name: trimmed),
    );
    await loadCurrencies();
    return true;
  }

  Future<void> deleteCurrency(int id) async {
    await _repository.deleteCurrency(id);
    await loadCurrencies();
  }

  Future<void> toggleAiInsights(bool value) async {
    aiInsightsEnabled.value = value;
    await _settingsService.setAiInsightsEnabled(value);
    if (Get.isRegistered<InsightsController>()) {
      await Get.find<InsightsController>().loadInsights();
    }
  }

  Future<void> toggleNotifications(bool value) async {
    notificationsEnabled.value = value;
    await _settingsService.setNotificationsEnabled(value);
    if (value) {
      await _notificationService.rescheduleAllReminders();
    } else {
      await _notificationService.cancelAllReminderNotifications();
    }
  }

  Future<bool> updateUserProfile(String name, int avatarIndex) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final current = user.value;
    final updated = UserModel(
      id: current?.id,
      name: trimmed,
      createdAt: current?.createdAt ?? DateTime.now(),
      avatarIndex: avatarIndex,
    );
    await _repository.saveUser(updated);
    user.value = updated;
    return true;
  }

  void toggleTheme(bool value) {
    _themeController.toggleTheme(value);
  }

  void changeLanguage(Locale locale) {
    _localeController.changeLocale(locale);
  }

  Future<void> updateMonthlyBudget(double value) async {
    final sanitized = value.clamp(500, 100000).toDouble();
    monthlyBudget.value = sanitized;
    budgetController.text = sanitized.toStringAsFixed(0);
    await _settingsService.setMonthlyBudget(sanitized);
  }

  Future<void> submitBudgetFromText() async {
    final raw = double.tryParse(budgetController.text.trim());
    if (raw == null) {
      budgetController.text = monthlyBudget.value.toStringAsFixed(0);
      return;
    }
    await updateMonthlyBudget(raw);
  }

  @override
  void onClose() {
    categoryNameController.dispose();
    budgetController.dispose();
    super.onClose();
  }
}
