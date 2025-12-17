import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/bill_group_model.dart';
import '../models/category_model.dart';
import '../models/recurring_task_model.dart';
import '../models/currency_model.dart';
import '../models/goal_model.dart';
import '../models/goal_contribution_model.dart';
import '../models/reminder_model.dart';
import '../models/notification_log_model.dart';
import '../models/transaction_model.dart';
import '../models/user_insight_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';

class LocalExpenseRepository {
  LocalExpenseRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db async => _database.database;

  Future<UserModel?> getPrimaryUser() async {
    final db = await _db;
    final result = await db.query('users', limit: 1);
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<void> saveUser(UserModel user) async {
    final db = await _db;
    final existing = await db.query('users', limit: 1);
    if (existing.isEmpty) {
      await db.insert('users', user.toMap());
    } else {
      final id = existing.first['id'] as int;
      await db.update(
        'users',
        user.copyWith(id: id).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<List<WalletModel>> fetchWallets({bool includeGoal = false}) async {
    final db = await _db;
    final data = await db.query(
      'wallets',
      where: includeGoal ? null : 'is_goal = 0',
      orderBy: 'created_at DESC',
    );
    return data.map(WalletModel.fromMap).toList();
  }

  Future<int> insertWallet(WalletModel wallet) async {
    final db = await _db;
    return db.insert('wallets', wallet.toMap());
  }

  Future<void> updateWallet(WalletModel wallet) async {
    if (wallet.id == null) return;
    final db = await _db;
    await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> deleteWallet(int id) async {
    final db = await _db;
    await db.delete('transactions', where: 'wallet_id = ?', whereArgs: [id]);
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<WalletModel?> fetchWalletById(int id) async {
    final db = await _db;
    final data = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (data.isEmpty) return null;
    return WalletModel.fromMap(data.first);
  }

  Future<List<CurrencyModel>> fetchCurrencies() async {
    final db = await _db;
    await _ensureCurrenciesTable(db);
    final data = await db.query('currencies', orderBy: 'name ASC');
    return data.map(CurrencyModel.fromMap).toList();
  }

  Future<int> insertCurrency(CurrencyModel currency) async {
    final db = await _db;
    await _ensureCurrenciesTable(db);
    return db.insert('currencies', currency.toMap());
  }

  Future<void> updateCurrency(CurrencyModel currency) async {
    if (currency.id == null) return;
    final db = await _db;
    await _ensureCurrenciesTable(db);
    await db.update(
      'currencies',
      currency.toMap(),
      where: 'id = ?',
      whereArgs: [currency.id],
    );
  }

  Future<void> deleteCurrency(int id) async {
    final db = await _db;
    await _ensureCurrenciesTable(db);
    await db.delete('currencies', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> currencyCodeExists(String code, {int? excludeId}) async {
    final db = await _db;
    await _ensureCurrenciesTable(db);
    final result = await db.query(
      'currencies',
      where: excludeId != null ? 'code = ? AND id != ?' : 'code = ?',
      whereArgs: excludeId != null ? [code, excludeId] : [code],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> _ensureCurrenciesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      );
    ''');
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final db = await _db;
    final data = await db.query('categories');
    return data.map(CategoryModel.fromMap).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await _db;
    return db.insert('categories', category.toMap());
  }

  Future<void> deleteCategory(int id) async {
    final db = await _db;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCategory(CategoryModel category) async {
    if (category.id == null) return;
    final db = await _db;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> ensureSystemCategory({
    required String name,
    required String icon,
    required int color,
  }) async {
    final db = await _db;
    final existing = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    return db.insert('categories', {
      'name': name,
      'icon': icon,
      'color': color,
    });
  }

  Future<List<TransactionModel>> fetchTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <dynamic>[];

    if (from != null) {
      where.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.toIso8601String());
    }

    final data = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
    );
    return data.map(TransactionModel.fromMap).toList();
  }

  Future<List<BillGroupModel>> fetchBillGroups() async {
    final db = await _db;
    final groupsData = await db.query(
      'bill_groups',
      orderBy: 'event_date DESC',
    );
    final participantsData = await db.query('bill_participants');
    final participantsByGroup = <int, List<BillParticipantModel>>{};
    for (final map in participantsData) {
      final participant = BillParticipantModel.fromMap(map);
      participantsByGroup
          .putIfAbsent(participant.billId, () => [])
          .add(participant);
    }
    return groupsData.map((groupMap) {
      final group = BillGroupModel.fromMap(groupMap);
      return group.copyWith(
        participants: participantsByGroup[group.id ?? -1] ?? const [],
      );
    }).toList();
  }

  Future<BillGroupModel?> insertBillGroup(BillGroupModel group) async {
    final db = await _db;
    final id = await db.insert('bill_groups', group.toMap());
    for (final participant in group.participants) {
      await db.insert(
        'bill_participants',
        participant.copyWith(billId: id).toMap(),
      );
    }
    final savedGroup = await db.query(
      'bill_groups',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (savedGroup.isEmpty) return null;
    final participantsMaps = await db.query(
      'bill_participants',
      where: 'bill_id = ?',
      whereArgs: [id],
    );
    return BillGroupModel.fromMap(savedGroup.first).copyWith(
      participants:
          participantsMaps.map(BillParticipantModel.fromMap).toList(),
    );
  }

  Future<void> deleteBillGroup(int id) async {
    final db = await _db;
    await db.delete('bill_participants', where: 'bill_id = ?', whereArgs: [id]);
    await db.delete('bill_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateBillParticipantPaid(int participantId, double paid) async {
    final db = await _db;
    await db.update(
      'bill_participants',
      {'paid': paid},
      where: 'id = ?',
      whereArgs: [participantId],
    );
  }

  Future<List<RecurringTaskModel>> fetchRecurringTasks() async {
    final db = await _db;
    final data = await db.query(
      'recurring_tasks',
      orderBy: 'next_date ASC',
    );
    return data.map(RecurringTaskModel.fromMap).toList();
  }

  Future<int> insertRecurringTask(RecurringTaskModel task) async {
    final db = await _db;
    return db.insert('recurring_tasks', task.toMap());
  }

  Future<void> deleteRecurringTask(int id) async {
    final db = await _db;
    await db.delete('recurring_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateRecurringTask(RecurringTaskModel task) async {
    if (task.id == null) return;
    final db = await _db;
    await db.update(
      'recurring_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> addTransaction(TransactionModel transaction) async {
    final db = await _db;
    return db.transaction<int>((txn) async {
      final id = await txn.insert('transactions', transaction.toMap());
      await _updateWalletBalance(txn, transaction);
      return id;
    });
  }

  Future<void> _updateWalletBalance(
    DatabaseExecutor db,
    TransactionModel transaction,
  ) async {
    final wallet = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [transaction.walletId],
      limit: 1,
    );
    if (wallet.isEmpty) return;
    final currentBalance = (wallet.first['balance'] as num).toDouble();
    double newBalance = currentBalance;
    switch (transaction.type) {
      case TransactionType.income:
        newBalance = currentBalance + transaction.amount;
        break;
      case TransactionType.expense:
      case TransactionType.saving:
        newBalance = currentBalance - transaction.amount;
        break;
    }

    await db.update(
      'wallets',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [transaction.walletId],
    );
  }

  Future<List<GoalContributionModel>> fetchGoalContributions(
    int goalId,
  ) async {
    final db = await _db;
    final data = await db.query(
      'goal_contributions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'datetime(created_at) DESC',
    );
    return data.map(GoalContributionModel.fromMap).toList();
  }

  Future<int> insertGoalContribution(
    GoalContributionModel contribution,
  ) async {
    final db = await _db;
    return db.transaction<int>((txn) async {
      final id = await txn.insert('goal_contributions', contribution.toMap());
      await txn.rawUpdate(
        'UPDATE goals SET current_amount = current_amount + ? WHERE id = ?',
        [contribution.amount, contribution.goalId],
      );
      final goal = await txn.query(
        'goals',
        where: 'id = ?',
        whereArgs: [contribution.goalId],
        limit: 1,
      );
      return id;
    });
  }

  Future<bool> transferGoalSavings(
    int goalId,
    int walletId,
  ) async {
    final db = await _db;
    return db.transaction<bool>((txn) async {
      final goalRows = await txn.query(
        'goals',
        where: 'id = ?',
        whereArgs: [goalId],
        limit: 1,
      );
      if (goalRows.isEmpty) return false;
      final goalRow = goalRows.first;
      final current = (goalRow['current_amount'] as num).toDouble();
      final target = (goalRow['target_amount'] as num).toDouble();
      final existingWallet = goalRow['wallet_id'] as int?;
      if (current < target || existingWallet != null) {
        return false;
      }
      final walletRows = await txn.query(
        'wallets',
        where: 'id = ?',
        whereArgs: [walletId],
        limit: 1,
      );
      if (walletRows.isEmpty) return false;
      final walletCurrency =
          (walletRows.first['currency'] as String?) ?? '';
      final goalCurrency = (goalRow['currency'] as String?) ?? '';
      if (walletCurrency != goalCurrency) {
        return false;
      }
      final goalName = goalRow['name'] as String? ?? 'Goal';
      final categoryId = await _ensureTransferCategory(txn);
      final transaction = TransactionModel(
        walletId: walletId,
        categoryId: categoryId,
        amount: current,
        type: TransactionType.income,
        note: 'goals.transfer.transaction_note'.trParams({'name': goalName}),
        date: DateTime.now(),
        goalId: goalId,
      );
      await txn.insert('transactions', transaction.toMap());
      await _updateWalletBalance(txn, transaction);
      await txn.update(
        'goals',
        {'wallet_id': walletId},
        where: 'id = ?',
        whereArgs: [goalId],
      );
      await txn.insert(
        'notifications_log',
        NotificationLogModel(
          title: 'goals.status.completed'.tr,
          body: 'transactions.goal.completed'
              .trParams({'name': goalName}),
          type: 'goal',
          createdAt: DateTime.now(),
        ).toMap(),
      );
      return true;
    });
  }

  Future<int> _ensureTransferCategory(DatabaseExecutor db) async {
    final existing = await db.query(
      'categories',
      where: 'name IN (?, ?)',
      whereArgs: ['Goal Transfer', 'تحويل هدف'],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    final locale = Get.locale?.languageCode ?? 'ar';
    final name = locale == 'en' ? 'Goal Transfer' : 'تحويل هدف';
    return db.insert('categories', {
      'name': name,
      'icon': 'savings',
      'color': 0xFF4CAF50,
    });
  }

  Future<List<GoalModel>> fetchGoals() async {
    final db = await _db;
    final data = await db.query('goals', orderBy: 'deadline ASC');
    return data.map(GoalModel.fromMap).toList();
  }

  Future<GoalModel?> fetchGoalById(int id) async {
    final db = await _db;
    final data = await db.query(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (data.isEmpty) return null;
    return GoalModel.fromMap(data.first);
  }

  Future<int> upsertGoal(GoalModel goal) async {
    final db = await _db;
    if (goal.id != null) {
      await db.update(
        'goals',
        goal.toMap(),
        where: 'id = ?',
        whereArgs: [goal.id],
      );
      return goal.id!;
    }
    return db.insert('goals', goal.toMap());
  }

  Future<List<ReminderModel>> fetchReminders() async {
    final db = await _db;
    final data = await db.query('reminders', orderBy: 'date ASC');
    return data.map(ReminderModel.fromMap).toList();
  }

  Future<int> insertReminder(ReminderModel reminder) async {
    final db = await _db;
    return db.insert('reminders', reminder.toMap());
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    if (reminder.id == null) return;
    final db = await _db;
    await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<void> deleteReminder(int id) async {
    final db = await _db;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertNotificationLog(NotificationLogModel log) async {
    final db = await _db;
    return db.insert('notifications_log', log.toMap());
  }

  Future<List<NotificationLogModel>> fetchNotificationLogs() async {
    final db = await _db;
    final data = await db.query(
      'notifications_log',
      orderBy: 'datetime(created_at) DESC',
    );
    return data.map(NotificationLogModel.fromMap).toList();
  }

  Future<void> markNotificationAsRead(int id) async {
    final db = await _db;
    await db.update(
      'notifications_log',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteNotification(int id) async {
    final db = await _db;
    await db.delete(
      'notifications_log',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllNotificationsAsRead() async {
    final db = await _db;
    await db.update('notifications_log', {'is_read': 1});
  }

  Future<void> clearNotificationLogs() async {
    final db = await _db;
    await db.delete('notifications_log');
  }

  Future<Map<String, double>> spendingByCategory(DateTime month) async {
    final db = await _db;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery(
      '''
      SELECT categories.name as category, SUM(transactions.amount) as total
      FROM transactions
      INNER JOIN categories ON transactions.category_id = categories.id
      WHERE transactions.type = 'expense'
        AND date BETWEEN ? AND ?
      GROUP BY categories.name
      ORDER BY total DESC
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return {
      for (final row in result)
        row['category'] as String: (row['total'] as num).toDouble(),
    };
  }

  Future<double> monthlyBudgetUsage(
    double monthlyBudget,
    DateTime month,
  ) async {
    final spendings = await spendingByCategory(month);
    final totalSpending = spendings.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    if (monthlyBudget <= 0) return 0;
    return (totalSpending / monthlyBudget).clamp(0, 1);
  }

  Future<double> totalBalance() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(balance) as balance FROM wallets',
    );
    final value = result.first['balance'] as num?;
    return value?.toDouble() ?? 0;
  }

  Future<List<TransactionModel>> fetchTransactionsByWallet(
    int walletId, {
    int? limit,
  }) async {
    final db = await _db;
    final data = await db.query(
      'transactions',
      where: 'wallet_id = ?',
      whereArgs: [walletId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return data.map(TransactionModel.fromMap).toList();
  }

  Future<void> cacheUserInsights(int userId, List<String> insights) async {
    final db = await _db;
    await db.delete('user_insights', where: 'user_id = ?', whereArgs: [userId]);
    for (final insight in insights) {
      await db.insert(
        'user_insights',
        UserInsightModel(
          userId: userId,
          content: insight,
          createdAt: DateTime.now(),
        ).toMap(),
      );
    }
  }

  Future<List<String>> fetchCachedInsights(int userId) async {
    final db = await _db;
    final data = await db.query(
      'user_insights',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return data.map((row) => row['content'] as String).toList();
  }
}
