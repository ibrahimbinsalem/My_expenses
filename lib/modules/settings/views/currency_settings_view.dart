import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/world_currencies.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/currency_model.dart';
import '../controllers/settings_controller.dart';

class CurrencySettingsView extends StatefulWidget {
  const CurrencySettingsView({super.key});

  @override
  State<CurrencySettingsView> createState() => _CurrencySettingsViewState();
}

class _CurrencySettingsViewState extends State<CurrencySettingsView> {
  final SettingsController controller = Get.find<SettingsController>();
  late final bool _autoPicker;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _autoPicker = args is Map && args['autoPicker'] == true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.loadCurrencies();
      if (mounted && _autoPicker) {
        _showGlobalCurrenciesPicker(context, controller);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إدارة العملات'.tr)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${'حدد العملات التي تريد استخدامها'.tr} '
              '${'يمكنك إضافة أكثر من عملة دفعة واحدة عبر النافذة المنسدلة.'.tr}',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showGlobalCurrenciesPicker(context, controller),
                icon: const Icon(Icons.public),
                label: Text('اختيار من العملات العالمية'.tr),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Obx(() {
                final currencies = controller.currencies;
                if (currencies.isEmpty) {
                  return Center(
                    child: Text(
                      'settings.currencies.empty_list'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: currencies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final currency = currencies[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondary.withValues(
                            alpha: 0.2,
                          ),
                          foregroundColor: AppColors.primary,
                          child: Text(currency.code),
                        ),
                        title: Text(currency.name),
                        subtitle: Text(
                          'الرمز: @code'.trParams({'code': currency.code}),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _handleMenuAction(
                            context,
                            controller,
                            currency,
                            value,
                          ),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'rename',
                              child: Text('تعديل الاسم'.tr),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('حذف'.tr),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

void _handleMenuAction(
  BuildContext context,
  SettingsController controller,
  CurrencyModel currency,
  String value,
) {
  if (value == 'rename') {
    _showEditCurrencyDialog(context, controller, currency);
  } else if (value == 'delete') {
    _confirmDeleteCurrency(context, controller, currency);
  }
}

Future<void> _showEditCurrencyDialog(
  BuildContext context,
  SettingsController controller,
  CurrencyModel currency,
) async {
  final nameController = TextEditingController(text: currency.name);
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: Text('تعديل اسم العملة'.tr),
      content: TextField(
        controller: nameController,
        decoration: InputDecoration(labelText: 'اسم جديد'.tr),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('common.cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: true),
          child: Text('common.save'.tr),
        ),
      ],
    ),
  );
  if (result == true) {
    final success = await controller.updateCurrency(
      currency,
      nameController.text,
    );
    if (!success) {
      Get.snackbar('common.alert'.tr, 'تأكد من إدخال اسم صحيح.'.tr);
    } else {
      Get.snackbar('تم التحديث'.tr, 'تم تعديل اسم العملة.'.tr);
    }
  }
  nameController.dispose();
}

Future<void> _confirmDeleteCurrency(
  BuildContext context,
  SettingsController controller,
  CurrencyModel currency,
) async {
  final confirmed = await Get.dialog<bool>(
    AlertDialog(
      title: Text('حذف العملة'.tr),
      content: Text('هل تريد حذف @name؟'.trParams({'name': currency.name})),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('common.cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: true),
          child: Text('حذف'.tr),
        ),
      ],
    ),
  );
  if (confirmed == true && currency.id != null) {
    await controller.deleteCurrency(currency.id!);
    Get.snackbar('تم الحذف'.tr, 'تم حذف العملة بنجاح.'.tr);
  }
}

Future<void> _showGlobalCurrenciesPicker(
  BuildContext context,
  SettingsController controller,
) async {
  final existingCodes = controller.currencies
      .map((currency) => currency.code.toUpperCase())
      .toSet();
  final available = worldCurrencies
      .where(
        (currency) =>
            !existingCodes.contains((currency['code'] as String).toUpperCase()),
      )
      .toList();
  if (available.isEmpty) {
    Get.snackbar(
      'common.warning'.tr,
      'جميع العملات العالمية تمت إضافتها مسبقًا.'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }

  final selected = <String>{};
  final searchController = TextEditingController();

  try {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
          final query = searchController.text.trim().toLowerCase();
          final filtered = available.where((currency) {
            if (query.isEmpty) return true;
            final nameAr =
                (currency['nameAr'] ?? currency['name'] ?? '').toLowerCase();
            final nameEn =
                (currency['nameEn'] ?? currency['name'] ?? '').toLowerCase();
            final code = (currency['code'] as String).toLowerCase();
            return nameAr.contains(query) ||
                nameEn.contains(query) ||
                code.contains(query);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  'اختر العملات المراد إضافتها'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'بحث عن العملة'.tr,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text('لا يوجد عملات مطابقة للبحث.'.tr),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final currency = filtered[index];
                        final code = currency['code'] as String;
                        final name = localizedCurrencyName(
                          currency.cast<String, String>(),
                        );
                        final isSelected = selected.contains(code);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selected.add(code);
                              } else {
                                selected.remove(code);
                              }
                            });
                          },
                          title: Text(name),
                          subtitle: Text(code),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('common.cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selected.isEmpty
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                final selectedOptions = available
                                    .where(
                                      (currency) => selected.contains(
                                        currency['code'] as String,
                                      ),
                                    )
                                    .map(
                                      (currency) => {
                                        'code': currency['code'] as String,
                                        'name': localizedCurrencyName(
                                          currency.cast<String, String>(),
                                        ),
                                      },
                                    )
                                    .toList();
                                final success = await controller
                                    .addCurrenciesBulk(selectedOptions);
                                navigator.pop();
                                if (success) {
                                  Get.snackbar(
                                    'common.added'.tr,
                                    'تمت إضافة العملات المحددة.'.tr,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                } else {
                                  Get.snackbar(
                                    'common.alert'.tr,
                                    'لم يتم إضافة أي عملة جديدة.'.tr,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                        child: Text('تأكيد الإضافة'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          },
        );
      },
    );
  } finally {
    searchController.dispose();
  }
}
