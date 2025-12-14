import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/category_icons.dart';
import '../../../data/models/category_model.dart';
import '../controllers/settings_controller.dart';

class CategorySettingsView extends GetView<SettingsController> {
  const CategorySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الفئات')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _CategoryForm(controller: controller),
            const SizedBox(height: 24),
            if (controller.isLoading.value && controller.categories.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (controller.categories.isEmpty)
              const Center(child: Text('لا توجد فئات حتى الآن'))
            else
              ...controller.categories.map(
                (category) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(category.color),
                      child: Icon(
                        categoryIconMap[category.icon] ?? Icons.category,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(category.name),
                    subtitle: Text(
                      categoryIconLabels[category.icon] ?? 'فئة مخصصة',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditCategorySheet(context, controller, category);
                        } else if (value == 'delete' && category.id != null) {
                          controller.deleteCategory(category.id!);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('تعديل'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('حذف'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _showEditCategorySheet(
  BuildContext context,
  SettingsController controller,
  CategoryModel category,
) {
  final nameController = TextEditingController(text: category.name);
  var tempColor = Color(category.color);
  var tempIcon = category.icon.isNotEmpty
      ? category.icon
      : (controller.iconOptions.isNotEmpty ? controller.iconOptions.first : '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'تعديل الفئة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'لون الفئة',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: controller.colorOptions
                      .map(
                        (color) => GestureDetector(
                          onTap: () => setState(() => tempColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: tempColor == color
                                  ? Border.all(
                                      color: AppColors.secondary,
                                      width: 3,
                                    )
                                  : Border.all(color: Colors.transparent),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'أيقونة الفئة',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(tempIcon),
                  initialValue: tempIcon.isEmpty ? null : tempIcon,
                  decoration: InputDecoration(
                    labelText: 'أيقونة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: controller.iconOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Row(
                            children: [
                              Icon(
                                categoryIconMap[option] ?? Icons.category,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(categoryIconLabels[option] ?? option),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => tempIcon = value);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      final navigator = Navigator.of(context);
                      await controller.updateCategory(
                        category.copyWith(
                          name: nameController.text.trim(),
                          color: tempColor.toARGB32(),
                          icon: tempIcon,
                        ),
                      );
                      navigator.pop();
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('حفظ التعديلات'),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

class _CategoryForm extends StatelessWidget {
  const _CategoryForm({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أضف فئة جديدة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.categoryNameController,
              decoration: const InputDecoration(
                labelText: 'اسم الفئة',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 12),
            Text('اختر اللون', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Obx(
              () => Wrap(
                spacing: 8,
                children: controller.colorOptions
                    .map(
                      (color) => GestureDetector(
                        onTap: () => controller.selectedColor.value = color,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: controller.selectedColor.value == color
                                ? Border.all(
                                    color: AppColors.secondary,
                                    width: 3,
                                  )
                                : Border.all(color: Colors.transparent),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            Text('اختر الرمز', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField<String>(
                key: ValueKey(controller.selectedIcon.value),
                initialValue: controller.selectedIcon.value.isEmpty
                    ? null
                    : controller.selectedIcon.value,
                decoration: InputDecoration(
                  labelText: 'أيقونة الفئة',
                  prefixIcon: controller.selectedIcon.value.isEmpty
                      ? const Icon(Icons.category_outlined)
                      : Icon(
                          categoryIconMap[controller.selectedIcon.value] ??
                              Icons.category,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                ),
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Theme.of(context).cardColor,
                menuMaxHeight: 280,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: controller.iconOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withAlpha(
                                  (0.15 * 255).round(),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                categoryIconMap[option] ?? Icons.category,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              categoryIconLabels[option] ?? option,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) controller.selectedIcon.value = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.addCategory,
                icon: const Icon(Icons.add),
                label: const Text('إضافة الفئة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
