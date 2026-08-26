import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// TABLES
// ---------------------------------------------------------------------------

/// Categorías de transacciones
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 64)();
  IntColumn get iconCode => integer()(); // codePoint del Icon de Material
  TextColumn get colorHex => text().withLength(min: 7, max: 9)();
  RealColumn get budgetLimit => real().nullable()();
}

/// Transacciones (gastos e ingresos)
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get type => text().withDefault(const Constant('expense'))(); // 'expense' | 'income'
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))(); // 'pending' | 'synced'
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Presupuestos por categoría
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get amount => real()();
  TextColumn get period => text().withDefault(const Constant('monthly'))(); // 'weekly' | 'monthly' | 'yearly'
}

/// Metas de ahorro
class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get goalType => text().withDefault(const Constant('savings'))(); // 'savings' | 'vacation' | 'emergency'
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get deadline => dateTime().nullable()();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))(); // 0=secondary, 1=tertiary, 2=error
}

/// Deudas con método de pago
class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get interestRate => real()(); // APR en porcentaje
  RealColumn get remainingAmount => real()();
  RealColumn get minimumPayment => real()();
  RealColumn get extraPayment => real().withDefault(const Constant(0))();
  TextColumn get method => text().withDefault(const Constant('avalanche'))(); // 'avalanche' | 'snowball'
  IntColumn get iconCode => integer().withDefault(const Constant(0xe1bc))(); // credit_card
}

// ---------------------------------------------------------------------------
// DATABASE
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [Categories, Transactions, Budgets, SavingsGoals, Debts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedData();
        },
      );

  // ---------------------------------------------------------------------------
  // SEED DATA (datos de demostración)
  // ---------------------------------------------------------------------------
  Future<void> _seedData() async {
    // Categorías
    final catIds = <int>[];
    final categoryData = [
      ('Comida', 0xe56c, '#A7D1AF'),   // restaurant
      ('Transporte', 0xe531, '#C8C6C8'), // directions_car
      ('Compras', 0xf1cc, '#ECC246'),  // shopping_bag
      ('Servicios', 0xe0ba, '#FFB4AB'), // electrical_services
      ('Vivienda', 0xe88a, '#ECC246'), // home
      ('Ocio', 0xe63a, '#FFB4AB'),    // theater_comedy
      ('Nómina', 0xef63, '#A7D1AF'),  // payments
      ('Otros', 0xe574, '#919095'),   // category
    ];

    for (final (name, icon, color) in categoryData) {
      final id = await into(categories).insert(
        CategoriesCompanion.insert(
          name: name,
          iconCode: icon,
          colorHex: color,
        ),
      );
      catIds.add(id);
    }

    // Transacciones demo
    final now = DateTime.now();
    await batch((b) {
      b.insertAll(transactions, [
        TransactionsCompanion.insert(
          amount: 124.50,
          categoryId: catIds[0],
          type: const Value('expense'),
          date: now.subtract(const Duration(hours: 2)),
          note: const Value('Supermercado'),
        ),
        TransactionsCompanion.insert(
          amount: 65.00,
          categoryId: catIds[3],
          type: const Value('expense'),
          date: now.subtract(const Duration(days: 1)),
          note: const Value('Electricidad'),
        ),
        TransactionsCompanion.insert(
          amount: 4250.00,
          categoryId: catIds[6],
          type: const Value('income'),
          date: now.subtract(const Duration(days: 2)),
          note: const Value('Nómina'),
        ),
        TransactionsCompanion.insert(
          amount: 45.00,
          categoryId: catIds[1],
          type: const Value('expense'),
          date: now.subtract(const Duration(days: 3)),
          note: const Value('Gasolina'),
        ),
        TransactionsCompanion.insert(
          amount: 230.00,
          categoryId: catIds[2],
          type: const Value('expense'),
          date: now.subtract(const Duration(days: 4)),
          note: const Value('Ropa'),
        ),
        TransactionsCompanion.insert(
          amount: 1200.00,
          categoryId: catIds[4],
          type: const Value('expense'),
          date: now.subtract(const Duration(days: 5)),
          note: const Value('Alquiler'),
        ),
        TransactionsCompanion.insert(
          amount: 85.00,
          categoryId: catIds[5],
          type: const Value('expense'),
          date: now.subtract(const Duration(days: 6)),
          note: const Value('Cine y cena'),
        ),
        TransactionsCompanion.insert(
          amount: 250.00,
          categoryId: catIds[7],
          type: const Value('expense'),
          date: now.subtract(const Duration(days: 7)),
          note: const Value('Varios'),
        ),
      ]);
    });

    // Presupuestos demo
    await batch((b) {
      b.insertAll(budgets, [
        BudgetsCompanion.insert(categoryId: catIds[0], amount: 1000.0),
        BudgetsCompanion.insert(categoryId: catIds[1], amount: 400.0),
        BudgetsCompanion.insert(categoryId: catIds[2], amount: 300.0),
        BudgetsCompanion.insert(categoryId: catIds[4], amount: 1500.0),
      ]);
    });

    // Metas de ahorro demo
    await batch((b) {
      b.insertAll(savingsGoals, [
        SavingsGoalsCompanion.insert(
          name: 'Fondo de Emergencia',
          goalType: const Value('emergency'),
          targetAmount: 20000.0,
          currentAmount: const Value(12000.0),
          deadline: Value(DateTime(2024, 10, 1)),
          colorIndex: const Value(0),
        ),
        SavingsGoalsCompanion.insert(
          name: 'Viaje a Japón',
          goalType: const Value('vacation'),
          targetAmount: 8000.0,
          currentAmount: const Value(2800.0),
          deadline: Value(DateTime(2025, 3, 1)),
          colorIndex: const Value(1),
        ),
      ]);
    });

    // Deudas demo
    await batch((b) {
      b.insertAll(debts, [
        DebtsCompanion.insert(
          name: 'Chase Sapphire',
          interestRate: 22.99,
          remainingAmount: 4200.0,
          minimumPayment: 150.0,
          extraPayment: const Value(350.0),
          iconCode: const Value(0xe1bc), // credit_card
        ),
        DebtsCompanion.insert(
          name: 'Auto Loan',
          interestRate: 4.5,
          remainingAmount: 10300.0,
          minimumPayment: 350.0,
          iconCode: const Value(0xe531), // directions_car
        ),
      ]);
    });
  }

  // ---------------------------------------------------------------------------
  // QUERIES — Categories
  // ---------------------------------------------------------------------------
  Stream<List<Category>> watchAllCategories() =>
      select(categories).watch();

  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  // ---------------------------------------------------------------------------
  // QUERIES — Transactions
  // ---------------------------------------------------------------------------
  Stream<List<Transaction>> watchRecentTransactions({int limit = 20}) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch();
  }

  Stream<List<Transaction>> watchTransactionsByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Stream<double> watchMonthlyIncome(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final query = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(transactions.date.isBetweenValues(start, end) &
          transactions.type.equals('income'));
    return query
        .map((row) => row.read(transactions.amount.sum()) ?? 0.0)
        .watchSingle();
  }

  Stream<double> watchMonthlyExpenses(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final query = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(transactions.date.isBetweenValues(start, end) &
          transactions.type.equals('expense'));
    return query
        .map((row) => row.read(transactions.amount.sum()) ?? 0.0)
        .watchSingle();
  }

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<bool> updateTransaction(Transaction t) =>
      update(transactions).replace(t);

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // QUERIES — Budgets
  // ---------------------------------------------------------------------------
  Stream<List<Budget>> watchAllBudgets() => select(budgets).watch();

  // ---------------------------------------------------------------------------
  // QUERIES — Savings Goals
  // ---------------------------------------------------------------------------
  Stream<List<SavingsGoal>> watchAllGoals() => select(savingsGoals).watch();

  Future<bool> updateGoal(SavingsGoal goal) =>
      update(savingsGoals).replace(goal);

  Future<int> insertGoal(SavingsGoalsCompanion goal) =>
      into(savingsGoals).insert(goal);

  // ---------------------------------------------------------------------------
  // QUERIES — Debts
  // ---------------------------------------------------------------------------
  Stream<List<Debt>> watchAllDebts() {
    return (select(debts)
          ..orderBy([(d) => OrderingTerm.desc(d.interestRate)]))
        .watch();
  }
}

// ---------------------------------------------------------------------------
// DATABASE CONNECTION
// ---------------------------------------------------------------------------
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'aurea.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
