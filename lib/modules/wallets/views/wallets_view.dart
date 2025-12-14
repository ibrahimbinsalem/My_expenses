import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../controllers/wallets_controller.dart';
import '../../../widgets/currency_picker_field.dart';

class WalletsView extends GetView<WalletsController> {
  const WalletsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحافظ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWalletSheet(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('محفظة جديدة'),
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: controller.fetchWallets,
          child: controller.isLoading.value && controller.wallets.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = controller.wallets[index];
                    return Card(
                      child: ListTile(
                        title: Text(wallet.name),
                        subtitle: Text(
                          'النوع: ${wallet.type} • العملة: ${wallet.currency}',
                        ),
                        trailing: Text(
                          Formatters.currency(
                            wallet.balance,
                            symbol: wallet.currency,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

Future<void> _showAddWalletSheet(
  BuildContext context,
  WalletsController controller,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إضافة محفظة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: 'اسم المحفظة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الرصيد الابتدائي'),
            ),
            const SizedBox(height: 12),
            CurrencyPickerField(controller: controller.currencyController),
            const SizedBox(height: 12),
            Obx(
              () => InputDecorator(
                decoration: const InputDecoration(labelText: 'النوع'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: controller.selectedType.value,
                    items: controller.walletTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) controller.selectedType.value = value;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await controller.addWallet();
                  Get.back();
                },
                child: const Text('حفظ'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
