import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/local_expense_repository.dart';

class SettingsController extends GetxController {
  SettingsController(this._repository, this._themeController);

  final LocalExpenseRepository _repository;
  final ThemeController _themeController;

  final categories = <CategoryModel>[].obs;
  final isLoading = false.obs;
  final categoryNameController = TextEditingController();
  final selectedColor = const Color(0xFF007C91).obs;
  final selectedIcon = ''.obs;

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

  @override
  void onInit() {
    super.onInit();
    if (selectedIcon.value.isEmpty && iconOptions.isNotEmpty) {
      selectedIcon.value = iconOptions.first;
    }
    loadCategories();
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    try {
      categories.assignAll(await _repository.fetchCategories());
    } finally {
      isLoading.value = false;
    }
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

  void toggleTheme(bool value) {
    _themeController.toggleTheme(value);
  }

  @override
  void onClose() {
    categoryNameController.dispose();
    super.onClose();
  }
}
