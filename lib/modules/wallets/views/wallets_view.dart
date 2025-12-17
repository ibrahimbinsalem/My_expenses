import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/wallet_model.dart';
import '../../../widgets/currency_picker_field.dart';
import '../controllers/wallets_controller.dart';

class WalletsView extends GetView<WalletsController> {
  const WalletsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('المحافظ'.tr)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWalletSheet(context, controller),
        icon: const Icon(Icons.add),
        label: Text('محفظة جديدة'.tr),
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
                          'النوع: @type • العملة: @currency'.trParams({
                            'type': _walletTypeLabel(wallet.type).tr,
                            'currency': wallet.currency,
                          }),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.currency(
                                wallet.balance,
                                symbol: wallet.currency,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<_WalletMenuAction>(
                              tooltip: 'خيارات المحفظة'.tr,
                              onSelected: (action) async {
                                switch (action) {
                                  case _WalletMenuAction.rename:
                                    await _showRenameWalletDialog(
                                      context,
                                      controller,
                                      wallet,
                                    );
                                    break;
                                  case _WalletMenuAction.delete:
                                    await _confirmDeleteWallet(
                                      context,
                                      controller,
                                      wallet,
                                    );
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: _WalletMenuAction.rename,
                                  child: Text('تعديل الاسم'.tr),
                                ),
                                PopupMenuItem(
                                  value: _WalletMenuAction.delete,
                                  child: Text('حذف المحفظة'.tr),
                                ),
                              ],
                            ),
                          ],
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
    builder: (context) => _AddWalletSheet(controller: controller),
  );
}

class _AddWalletSheet extends StatefulWidget {
  const _AddWalletSheet({required this.controller});

  final WalletsController controller;

  @override
  State<_AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends State<_AddWalletSheet> {
  late final TextEditingController nameController;
  late final TextEditingController balanceController;
  late final TextEditingController currencyController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    balanceController = TextEditingController();
    currencyController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    currencyController.dispose();
    super.dispose();
  }

  WalletsController get controller => widget.controller;

  Future<void> _save() async {
    final name = nameController.text.trim();
    final currencyCode = currencyController.text.trim().toUpperCase();
    final balanceText = balanceController.text.trim();
    if (name.isEmpty || currencyCode.isEmpty || balanceText.isEmpty) {
      Get.snackbar(
        'common.alert'.tr,
        'جميع الحقول إلزامية لإضافة المحفظة.'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final initialBalance = double.tryParse(balanceText) ?? 0;
    final success = await controller.addWallet(
      name: name,
      currencyCode: currencyCode,
      initialBalance: initialBalance,
      type: controller.selectedType.value,
    );
    if (success) {
      await controller.fetchWallets();
      Get.snackbar(
        'تمت العملية بنجاح'.tr,
        'تم اعتماد العملة @code وتحديث قائمة المحافظ.'
            .trParams({'code': currencyCode}),
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            'إضافة محفظة'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'اسم المحفظة'.tr),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: balanceController,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: 'الرصيد الابتدائي'.tr),
          ),
          const SizedBox(height: 12),
          CurrencyPickerField(controller: currencyController),
          const SizedBox(height: 12),
          Obx(
            () => InputDecorator(
              decoration: InputDecoration(labelText: 'النوع'.tr),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: controller.selectedType.value,
                  items: controller.walletTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_walletTypeLabel(type).tr),
                        ),
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
              onPressed: _save,
              child: Text('common.save'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

String _walletTypeLabel(String type) {
  switch (type) {
    case 'bank':
      return 'wallet.type.bank';
    case 'digital':
      return 'wallet.type.digital';
    default:
      return 'wallet.type.cash';
  }
}

Future<void> _showRenameWalletDialog(
  BuildContext context,
  WalletsController controller,
  WalletModel wallet,
) async {
  final textController = TextEditingController(text: wallet.name);
  await Get.dialog(
    AlertDialog(
      title: Text('تعديل اسم المحفظة'.tr),
      content: TextField(
        controller: textController,
        decoration: InputDecoration(labelText: 'الاسم الجديد'.tr),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('common.cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () async {
            final success = await controller.renameWallet(
              wallet,
              textController.text,
            );
            if (!success) {
              Get.snackbar('common.alert'.tr, 'أدخل اسمًا صالحًا.'.tr);
              return;
            }
            Get.back();
            Get.snackbar(
              'تم التحديث'.tr,
              'تم تعديل اسم المحفظة بنجاح.'.tr,
            );
          },
          child: Text('common.save'.tr),
        ),
      ],
    ),
  );
  textController.dispose();
}

Future<void> _confirmDeleteWallet(
  BuildContext context,
  WalletsController controller,
  WalletModel wallet,
) async {
  final confirmed = await Get.dialog<bool>(
    AlertDialog(
      title: Text('تأكيد الحذف'.tr),
      content: Text(
        'سيتم حذف جميع العمليات والبيانات المرتبطة بهذه المحفظة نهائيًا. هل أنت متأكد من الحذف؟'
            .tr,
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('common.cancel'.tr),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Get.back(result: true),
          child: Text('نعم، احذف'.tr),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.deleteWallet(wallet);
    Get.snackbar('تم الحذف'.tr, 'تم حذف المحفظة وكل بياناتها.'.tr);
  }
}

enum _WalletMenuAction { rename, delete }
