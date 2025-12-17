import 'package:get/get.dart';

import '../../../core/config/api_keys.dart';
import '../../../core/services/network_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/local_expense_repository.dart';
import '../../../data/services/ai_insight_service.dart';
import '../../../data/services/gemini_insight_service.dart';

class InsightsController extends GetxController {
  InsightsController(
    this._repository,
    this._localInsightService,
    this._networkService,
    this._geminiInsightService,
  ) : _settingsService = Get.find<SettingsService>();

  final LocalExpenseRepository _repository;
  final LocalInsightService _localInsightService;
  final NetworkService _networkService;
  final GeminiInsightService _geminiInsightService;
  final SettingsService _settingsService;

  final spendingByCategory = <String, double>{}.obs;
  final monthlyBudget = 3000.0.obs;
  final budgetUsage = 0.0.obs;
  final totalIncome = 0.0.obs;
  final totalExpense = 0.0.obs;
  final aiInsights = <String>[].obs;
  final walletInsights = <WalletInsight>[].obs;
  final isOnline = true.obs;
  final isLoading = false.obs;
  final aiFeatureEnabled = false.obs;
  final _currentMonth = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    loadInsights();
  }

  Future<void> loadInsights() async {
    isLoading.value = true;
    try {
      aiFeatureEnabled.value = _settingsService.aiInsightsEnabled;
      isOnline.value = await _networkService.hasConnection();
      final now = DateTime(_currentMonth.year, _currentMonth.month);
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final transactions = await _repository.fetchTransactions(
        from: start,
        to: end,
      );
      spendingByCategory.assignAll(await _repository.spendingByCategory(now));
      budgetUsage.value = await _repository.monthlyBudgetUsage(
        _settingsService.monthlyBudget,
        now,
      );
      monthlyBudget.value = _settingsService.monthlyBudget;
      _calculateTotals(transactions);
      await _loadGeminiInsights(transactions);
      await _buildWalletInsights(transactions);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshConnectivity() async {
    isOnline.value = await _networkService.hasConnection();
  }

  void _calculateTotals(List<TransactionModel> transactions) {
    var income = 0.0;
    var expense = 0.0;
    for (final txn in transactions) {
      if (txn.type == TransactionType.income) {
        income += txn.amount;
      } else {
        expense += txn.amount;
      }
    }
    totalIncome.value = income;
    totalExpense.value = expense;
  }

  Future<void> _loadGeminiInsights(List<TransactionModel> transactions) async {
    final user = await _repository.getPrimaryUser();
    if (user == null || user.id == null) {
      aiInsights.clear();
      return;
    }
    if (!_settingsService.aiInsightsEnabled) {
      aiInsights.clear();
      return;
    }
    final cached = await _repository.fetchCachedInsights(user.id!);
    if (!isOnline.value || !ApiKeys.hasGeminiKey) {
      aiInsights.assignAll(cached);
      return;
    }
    try {
      final remoteInsights = await _geminiInsightService.generateInsights(
        transactions: transactions,
        username: user.name,
      );
      if (remoteInsights.isNotEmpty) {
        await _repository.cacheUserInsights(user.id!, remoteInsights);
        aiInsights.assignAll(remoteInsights);
      } else {
        aiInsights.assignAll(cached);
      }
    } catch (_) {
      aiInsights.assignAll(cached);
    }
  }

  Future<void> _buildWalletInsights(
    List<TransactionModel> monthTransactions,
  ) async {
    final grouped = <int, List<TransactionModel>>{};
    for (final txn in monthTransactions) {
      grouped.putIfAbsent(txn.walletId, () => []).add(txn);
    }
    final wallets = await _repository.fetchWallets();
    final results = <WalletInsight>[];
    for (final wallet in wallets) {
      if (wallet.id == null) continue;
      final walletTransactions = grouped[wallet.id!] ?? <TransactionModel>[];
      var income = 0.0;
      var expense = 0.0;
      for (final txn in walletTransactions) {
        if (txn.type == TransactionType.income) {
          income += txn.amount;
        } else {
          expense += txn.amount;
        }
      }
      final insights = await _localInsightService.generateInsights(
        walletTransactions,
      );
      final walletLimit = wallet.balance <= 0 ? expense : wallet.balance;
      final budgetUsage = walletLimit <= 0
          ? 0.0
          : (expense / walletLimit).clamp(0, 1).toDouble();
      results.add(
        WalletInsight(
          wallet: wallet,
          income: income,
          expense: expense,
          insights: insights,
          budgetUsage: budgetUsage,
          budgetLimit: walletLimit,
        ),
      );
    }
    walletInsights.assignAll(results);
  }
}

class WalletInsight {
  WalletInsight({
    required this.wallet,
    required this.income,
    required this.expense,
    required this.insights,
    required this.budgetUsage,
    required this.budgetLimit,
  });

  final WalletModel wallet;
  final double income;
  final double expense;
  final List<String> insights;
  final double budgetUsage;
  final double budgetLimit;

  double get net => income - expense;
}
