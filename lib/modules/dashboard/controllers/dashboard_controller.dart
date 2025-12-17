import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/gulf_currencies.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/currency_model.dart';
import '../../../data/models/reminder_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/local_expense_repository.dart';
import '../../../data/services/ai_insight_service.dart';
import '../../../routes/app_routes.dart';

class DashboardController extends GetxController {
  DashboardController(this._repository, this._insightService);
  

  final LocalExpenseRepository _repository;
  final LocalInsightService _insightService;

  final isLoading = false.obs;
  final totalBalance = 0.0.obs;
  final monthlySpending = <String, double>{}.obs;
  final insights = <String>[].obs;
  final recentTransactions = <TransactionModel>[].obs;
  final walletSummaries = <WalletSummary>[].obs;
  final navIndex = 0.obs;
  final isBalanceHidden = true.obs;
  final primaryCurrencyName = 'ريال سعودي'.obs;
  final primaryCurrencyCode = 'SAR'.obs;
  final _currencyLookup = <String, String>{};
  final isQuickFabOpen = false.obs;

  final navItems = const [
    DashboardNavItem(
      labelKey: 'nav.home',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
      route: AppRoutes.dashboard,
    ),
    DashboardNavItem(
      labelKey: 'nav.wallets',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      route: AppRoutes.wallets,
    ),
    DashboardNavItem(
      labelKey: 'nav.goals',
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
      route: AppRoutes.goals,
    ),
    DashboardNavItem(
      labelKey: 'nav.insights',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      route: AppRoutes.insights,
    ),
    DashboardNavItem(
      labelKey: 'nav.settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: AppRoutes.settings,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      totalBalance.value = await _repository.totalBalance();
      final customCurrencies = await _repository.fetchCurrencies();
      _currencyLookup
        ..clear()
        ..addEntries(
          customCurrencies.map(
            (CurrencyModel currency) => MapEntry(
              currency.code.toUpperCase(),
              currency.name,
            ),
          ),
        );
      final wallets = await _repository.fetchWallets();
      walletSummaries.assignAll(await _buildWalletSummaries(wallets));
      if (wallets.isNotEmpty) {
        primaryCurrencyCode.value = wallets.first.currency;
        primaryCurrencyName.value = _resolveCurrencyName(
          wallets.first.currency,
        );
      } else {
        primaryCurrencyCode.value = 'SAR';
        primaryCurrencyName.value = 'ريال سعودي'.tr;
      }
      final now = DateTime.now();
      monthlySpending.assignAll(await _repository.spendingByCategory(now));
      final txns = await _repository.fetchTransactions(
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month + 1, 0),
      );
      recentTransactions.assignAll(txns.take(5));
      insights.assignAll(await _insightService.generateInsights(txns));
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<WalletSummary>> _buildWalletSummaries(
    List<WalletModel> wallets,
  ) async {
    if (wallets.isEmpty) return [];
    final futures = wallets.map((wallet) async {
      final txns = wallet.id == null
          ? <TransactionModel>[]
          : await _repository.fetchTransactionsByWallet(wallet.id!);
      return WalletSummary(
        wallet: wallet,
        currencyName: _resolveCurrencyName(wallet.currency),
        transactions: txns,
      );
    }).toList();
    return Future.wait(futures);
  }

  Future<void> onNavDestinationSelected(int index) async {
    navIndex.value = index;
    final destination = navItems[index];
    if (destination.route == AppRoutes.dashboard) return;
    await Get.toNamed(destination.route);
    navIndex.value = 0;
  }

  void toggleBalanceVisibility() {
    isBalanceHidden.toggle();
  }

  void toggleQuickFab() {
    isQuickFabOpen.toggle();
  }

  String _resolveCurrencyName(String code) {
    final normalized = code.toUpperCase();
    final lookupName = _currencyLookup[normalized];
    if (lookupName != null) return lookupName;
    for (final entry in gulfCurrencies) {
      final entryCode = (entry['code'] as String).toUpperCase();
      if (entryCode == normalized) {
        return localizedCurrencyName(entry.cast<String, String>());
      }
    }
    return 'عملة @code'.trParams({'code': code});
  }

  Future<void> openQuickNoteSheet(BuildContext context) async {
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(DateTime.now());
    if (!context.mounted) return;
    await showModalBottomSheet(
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
              Future<void> pickDate() async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now()
                      .subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              }

              Future<void> pickTime() async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (picked != null) {
                  setState(() => selectedTime = picked);
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'quickNote.title'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'quickNote.placeholder'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event_note),
                          title: Text(DateFormat('dd MMM yyyy')
                              .format(selectedDate)),
                          onTap: pickDate,
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule),
                          title: Text(selectedTime.format(context)),
                          onTap: pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final text = noteController.text.trim();
                        if (text.isEmpty) {
                          Get.snackbar(
                            'common.alert'.tr,
                            'quickNote.required'.tr,
                          );
                          return;
                        }
                        final reminder = ReminderModel(
                          message: text,
                          date: selectedDate,
                          time:
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        );
                        await _repository.insertReminder(reminder);
                        if (context.mounted) Navigator.of(context).pop();
                        Get.snackbar(
                          'common.success'.tr,
                          'quickNote.saved'.tr,
                        );
                      },
                      child: Text('common.save'.tr),
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

  Future<void> openBillBook() async {
    await Get.toNamed(AppRoutes.billBook);
  }

  Future<void> openAddTransaction() async {
    await Get.toNamed(AppRoutes.addTransaction);
    await loadDashboard();
  }

  Future<void> openTasks() async {
    await Get.toNamed(AppRoutes.tasks);
  }

  Future<void> openAddFundsSheet(BuildContext context) async {
    final wallets = await _repository.fetchWallets();
    if (wallets.isEmpty) {
      Get.snackbar('common.alert'.tr, 'أضف محفظة قبل شحن الرصيد'.tr);
      return;
    }

    int? selectedWallet = wallets.first.id;
    final amountController = TextEditingController();
    final noteController = TextEditingController(text: 'شحن رصيد'.tr);

    if (!context.mounted) return;
    await showModalBottomSheet(
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
                  Text(
                    'شحن محفظة'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'المحفظة'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedWallet,
                        isExpanded: true,
                        items: wallets
                            .map(
                              (wallet) => DropdownMenuItem(
                                value: wallet.id,
                                child: Text(
                                  '${wallet.name} (${wallet.currency})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedWallet = value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'المبلغ'.tr,
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'ملاحظة'.tr,
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final amount = double.tryParse(
                          amountController.text.trim(),
                        );
                        if (selectedWallet == null ||
                            amount == null ||
                            amount <= 0) {
                          Get.snackbar(
                            'common.alert'.tr,
                            'أدخل بيانات صحيحة'.tr,
                          );
                          return;
                        }
                        final navigator = Navigator.of(context);
                        await addFunds(
                          walletId: selectedWallet!,
                          amount: amount,
                          note: noteController.text.trim(),
                        );
                        navigator.pop();
                      },
                      icon: const Icon(Icons.check),
                      label: Text('تأكيد الشحن'.tr),
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

  Future<void> addFunds({
    required int walletId,
    required double amount,
    String? note,
  }) async {
    final depositCategoryId = await _repository.ensureSystemCategory(
      name: 'شحن رصيد'.tr,
      icon: 'savings',
      color: 0xFF4CAF50,
    );
    final transaction = TransactionModel(
      walletId: walletId,
      categoryId: depositCategoryId,
      amount: amount,
      type: TransactionType.income,
      note: note?.isEmpty ?? true ? 'شحن رصيد'.tr : note,
      date: DateTime.now(),
    );
    await _repository.addTransaction(transaction);
    await loadDashboard();
    Get.snackbar(
      'common.success'.tr,
      'تم شحن المحفظة وتسجيل العملية'.tr,
    );
  }
}

class DashboardNavItem {
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const DashboardNavItem({
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

class WalletSummary {
  final WalletModel wallet;
  final String currencyName;
  final List<TransactionModel> transactions;

  const WalletSummary({
    required this.wallet,
    required this.currencyName,
    required this.transactions,
  });
}
