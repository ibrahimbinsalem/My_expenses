import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../routes/app_routes.dart';
import '../controllers/transactions_controller.dart';

class AddTransactionView extends GetView<TransactionsController> {
  const AddTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إضافة عملية'.tr)),
      body: Form(
        key: controller.formKey,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _AmountField(controller: controller),
              const SizedBox(height: 16),
              _DropdownField(
                label: 'المحفظة'.tr,
                value: controller.selectedWalletId.value,
                items: controller.wallets
                    .map(
                      (wallet) => DropdownMenuItem(
                        value: wallet.id,
                        child: Text(
                          '${wallet.name} (${Formatters.currency(wallet.balance, symbol: wallet.currency)})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => controller.selectedWalletId.value = value,
              ),
              if (controller.wallets.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.wallets),
                    child: Text('أضف محفظة جديدة من صفحة المحافظ'.tr),
                  ),
                ),
              const SizedBox(height: 16),
              _DropdownField(
                label: 'الفئة'.tr,
                value: controller.selectedCategoryId.value,
                items: controller.categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    controller.selectedCategoryId.value = value,
              ),
              if (controller.categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.settings),
                    child: Text('أضف فئات مخصصة من صفحة الإعدادات'.tr),
                  ),
                ),
              const SizedBox(height: 16),
              _DateSelector(controller: controller),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.noteController,
                decoration: InputDecoration(labelText: 'ملاحظة'.tr),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text('فاتورة'.tr),
                      onPressed: () =>
                          controller.autofillFromReceipt('local-path'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.mic_none_outlined),
                      label: Text('صوت'.tr),
                      onPressed: () =>
                          controller.handleVoiceCommand('local-audio'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.saveTransaction,
                child: controller.isSaving.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('حفظ العملية'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});

  final TransactionsController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller.amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'المبلغ'.tr,
        prefixIcon: const Icon(Icons.attach_money),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'أدخل المبلغ'.tr;
        }
        final parsed = double.tryParse(value);
        if (parsed == null || parsed <= 0) {
          return 'أدخل رقمًا صحيحًا'.tr;
        }
        return null;
      },
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<DropdownMenuItem<int>> items;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text('لا بيانات متاحة حاليًا'.tr),
      );
    }

    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.controller});

  final TransactionsController controller;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.date_range),
      title: Text('التاريخ'.tr),
      subtitle: Text(Formatters.shortDate(controller.selectedDate.value)),
      trailing: IconButton(
        icon: const Icon(Icons.edit_calendar),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: controller.selectedDate.value,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            controller.selectedDate.value = picked;
          }
        },
      ),
    );
  }
}
