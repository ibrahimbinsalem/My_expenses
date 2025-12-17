import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../controllers/receipts_controller.dart';

class ReceiptsView extends GetView<ReceiptsController> {
  const ReceiptsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إيصالات المصروفات'.tr)),
      body: Obx(
        () => controller.isLoading.value && controller.receipts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.receipts.length,
                itemBuilder: (context, index) {
                  final receipt = controller.receipts[index];
                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long),
                      ),
                      title: Text(
                        Formatters.currency(
                          receipt.amount,
                          symbol: 'ريال'.tr,
                        ),
                      ),
                      subtitle: Text(
                        receipt.note ?? Formatters.shortDate(receipt.date),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
