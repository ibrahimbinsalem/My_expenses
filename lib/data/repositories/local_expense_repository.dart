import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../models/reminder_model.dart';
import '../models/transaction_model.dart';
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

  Future<int> insertUser(UserModel user) async {
    final db = await _db;
    return db.insert('users', user.toMap());
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
}
