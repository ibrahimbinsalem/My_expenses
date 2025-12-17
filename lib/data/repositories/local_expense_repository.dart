import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/category_model.dart';
import '../models/currency_model.dart';
import '../models/goal_model.dart';
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

  Future<List<WalletModel>> fetchWallets() async {
    final db = await _db;
    final data = await db.query('wallets', orderBy: 'created_at DESC');
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

  Future<int> addTransaction(TransactionModel transaction) async {
    final db = await _db;
    final id = await db.insert('transactions', transaction.toMap());
    await _updateWalletBalance(db, transaction);
    return id;
  }

  Future<void> _updateWalletBalance(
    Database db,
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
    final newBalance = transaction.type == TransactionType.income
        ? currentBalance + transaction.amount
        : currentBalance - transaction.amount;

    await db.update(
      'wallets',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [transaction.walletId],
    );
  }

  Future<List<GoalModel>> fetchGoals() async {
    final db = await _db;
    final data = await db.query('goals', orderBy: 'deadline ASC');
    return data.map(GoalModel.fromMap).toList();
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
