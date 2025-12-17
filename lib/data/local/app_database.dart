import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;
  String? _databasePath;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = join(directory.path, 'my_expenses.db');
    _databasePath = dbPath;

    return openDatabase(
      dbPath,
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        avatar_index INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        currency TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_goal INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wallet_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        image_path TEXT,
        goal_id INTEGER,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id),
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (goal_id) REFERENCES goals (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL,
        deadline TEXT NOT NULL,
        wallet_id INTEGER,
        currency TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (wallet_id) REFERENCES wallets (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        message TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE user_insights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE goal_contributions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE notifications_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE bill_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        event_date TEXT NOT NULL,
        total REAL NOT NULL,
        currency TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE bill_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        share REAL NOT NULL,
        paid REAL NOT NULL DEFAULT 0,
        wallet_id INTEGER,
        FOREIGN KEY (bill_id) REFERENCES bill_groups (id) ON DELETE CASCADE,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE recurring_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL,
        currency TEXT,
        frequency TEXT NOT NULL,
        next_date TEXT NOT NULL,
        wallet_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id)
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS currencies (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0
        );
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_insights (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        );
      ''');
    }
    if (oldVersion < 4) {
      final columns = await db.rawQuery(
        "PRAGMA table_info('users')",
      );
      final hasAvatarColumn = columns.any(
        (column) => column['name'] == 'avatar_index',
      );
      if (!hasAvatarColumn) {
        await db.execute(
          "ALTER TABLE users ADD COLUMN avatar_index INTEGER NOT NULL DEFAULT 0",
        );
      }
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          type TEXT NOT NULL,
          created_at TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0
        );
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bill_groups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          event_date TEXT NOT NULL,
          total REAL NOT NULL,
          currency TEXT NOT NULL,
          created_at TEXT NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bill_participants (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bill_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          share REAL NOT NULL,
          paid REAL NOT NULL DEFAULT 0,
          wallet_id INTEGER,
          FOREIGN KEY (bill_id) REFERENCES bill_groups (id) ON DELETE CASCADE,
          FOREIGN KEY (wallet_id) REFERENCES wallets (id)
        );
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          amount REAL,
          currency TEXT,
          frequency TEXT NOT NULL,
          next_date TEXT NOT NULL,
          wallet_id INTEGER,
          created_at TEXT NOT NULL,
          FOREIGN KEY (wallet_id) REFERENCES wallets (id)
        );
      ''');
    }
    if (oldVersion < 8) {
      final transactionInfo = await db.rawQuery(
        "PRAGMA table_info('transactions')",
      );
      final hasGoalColumn =
          transactionInfo.any((column) => column['name'] == 'goal_id');
      if (!hasGoalColumn) {
        await db.execute(
          "ALTER TABLE transactions ADD COLUMN goal_id INTEGER",
        );
      }

      final goalsInfo = await db.rawQuery("PRAGMA table_info('goals')");
      final hasWalletColumn =
          goalsInfo.any((column) => column['name'] == 'wallet_id');
      if (!hasWalletColumn) {
        await db.execute(
          "ALTER TABLE goals ADD COLUMN wallet_id INTEGER",
        );
      }
      final hasCurrencyColumn =
          goalsInfo.any((column) => column['name'] == 'currency');
      if (!hasCurrencyColumn) {
        await db.execute(
          "ALTER TABLE goals ADD COLUMN currency TEXT",
        );
      }
    }
    if (oldVersion < 9) {
      final walletInfo = await db.rawQuery("PRAGMA table_info('wallets')");
      final hasIsGoalColumn =
          walletInfo.any((column) => column['name'] == 'is_goal');
      if (!hasIsGoalColumn) {
        await db.execute(
          "ALTER TABLE wallets ADD COLUMN is_goal INTEGER NOT NULL DEFAULT 0",
        );
      }

      final goals = await db.query('goals');
      for (final goal in goals) {
        final goalId = goal['id'] as int?;
        if (goalId == null) continue;
        final existingWalletId = goal['wallet_id'] as int?;
        var currency = goal['currency'] as String? ?? 'SAR';
        var needsNewWallet = true;
        if (existingWalletId != null) {
          final existingWallet = await db.query(
            'wallets',
            where: 'id = ?',
            whereArgs: [existingWalletId],
            limit: 1,
          );
          if (existingWallet.isNotEmpty) {
            final isGoalWallet =
                (existingWallet.first['is_goal'] as int? ?? 0) == 1;
            currency =
                existingWallet.first['currency'] as String? ?? currency;
            if (isGoalWallet) {
              needsNewWallet = false;
            }
          }
        }

        if (needsNewWallet) {
          final now = DateTime.now().toIso8601String();
          final goalName = goal['name'] as String? ?? 'Goal';
          final currentAmount =
              (goal['current_amount'] as num?)?.toDouble() ?? 0;
          final savingsWalletId = await db.insert('wallets', {
            'user_id': null,
            'name': 'Saving - $goalName',
            'type': 'goal',
            'balance': currentAmount,
            'currency': currency,
            'created_at': now,
            'is_goal': 1,
          });
          await db.update(
            'goals',
            {
              'wallet_id': savingsWalletId,
              'currency': currency,
            },
            where: 'id = ?',
            whereArgs: [goalId],
          );
        }
      }
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goal_contributions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goal_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
        );
      ''');
    }
  }

  Future<String> get databasePath async {
    if (_databasePath != null) return _databasePath!;
    final directory = await getApplicationDocumentsDirectory();
    _databasePath = join(directory.path, 'my_expenses.db');
    return _databasePath!;
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> reopenDatabase() async {
    await closeDatabase();
    await database;
  }
}
