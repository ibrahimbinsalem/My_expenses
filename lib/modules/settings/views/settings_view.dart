import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات الشخصية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ThemeCard(controller: controller),
          const SizedBox(height: 16),
          const _CategoryLink(),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.dark_mode, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('الوضع الليلي'),
                SizedBox(height: 4),
                Text(
                  'بدل بين الوضع الفاتح والداكن في أي وقت.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Obx(() {
            final isDark = controller.themeMode.value == ThemeMode.dark;
            return Switch(value: isDark, onChanged: controller.toggleTheme);
          }),
        ],
      ),
    );
  }
}

class _CategoryLink extends StatelessWidget {
  const _CategoryLink();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.secondary,
          child: Icon(Icons.category, color: Colors.black87),
        ),
        title: const Text('إدارة الفئات'),
        subtitle: const Text('تحكم في الفئات من شاشة مخصصة'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed(AppRoutes.categorySettings),
      ),
    );
  }
}
