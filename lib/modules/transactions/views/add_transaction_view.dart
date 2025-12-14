import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/transactions_controller.dart';

class AddTransactionView extends GetView<TransactionsController> {
  const AddTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة عملية')),
      body: Form(
        key: controller.formKey,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _AmountField(controller: controller),
              const SizedBox(height: 16),
              _TypeSelector(controller: controller),
              const SizedBox(height: 16),
              _DropdownField(
                label: 'المحفظة',
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
                    child: const Text('أضف محفظة جديدة من صفحة المحافظ'),
                  ),
                ),
              const SizedBox(height: 16),
              _DropdownField(
                label: 'الفئة',
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
                    child: const Text('أضف فئات مخصصة من صفحة الإعدادات'),
                  ),
                ),
              const SizedBox(height: 16),
              _DateSelector(controller: controller),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.noteController,
                decoration: const InputDecoration(labelText: 'ملاحظة'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('فاتورة'),
                      onPressed: () =>
                          controller.autofillFromReceipt('local-path'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.mic_none_outlined),
                      label: const Text('صوت'),
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
                    : const Text('حفظ العملية'),
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
      decoration: const InputDecoration(
        labelText: 'المبلغ',
        prefixIcon: Icon(Icons.attach_money),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'أدخل المبلغ';
        }
        final parsed = double.tryParse(value);
        if (parsed == null || parsed <= 0) {
          return 'أدخل رقمًا صحيحًا';
        }
        return null;
      },
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.controller});

  final TransactionsController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('مصروف'),
            selected: controller.selectedType.value == TransactionType.expense,
            selectedColor: AppColors.danger.withAlpha((0.2 * 255).round()),
            onSelected: (_) =>
                controller.selectedType.value = TransactionType.expense,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Text('دخل'),
            selected: controller.selectedType.value == TransactionType.income,
            selectedColor: AppColors.success.withAlpha((0.2 * 255).round()),
            onSelected: (_) =>
                controller.selectedType.value = TransactionType.income,
          ),
        ),
      ],
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
        child: const Text('لا بيانات متاحة حاليًا'),
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
      title: const Text('التاريخ'),
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
