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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            // Wipe legacy seed data from previous versions
            await customStatement('DELETE FROM transactions;');
            await customStatement('DELETE FROM budgets;');
            await customStatement('DELETE FROM savings_goals;');
            await customStatement('DELETE FROM debts;');
          }
        },
      );

  // ---------------------------------------------------------------------------
  // SEED — Solo categorías base (no datos de usuario)
  // ---------------------------------------------------------------------------
  Future<void> _seedCategories() async {
    final categoryData = [
      ('Comida', 0xe56c, '#A7D1AF'),      // restaurant
      ('Transporte', 0xe531, '#C8C6C8'),  // directions_car
      ('Compras', 0xf1cc, '#ECC246'),     // shopping_bag
      ('Servicios', 0xe0ba, '#FFB4AB'),   // electrical_services
      ('Vivienda', 0xe88a, '#ECC246'),    // home
      ('Ocio', 0xe63a, '#FFB4AB'),        // theater_comedy
      ('Nómina', 0xef63, '#A7D1AF'),      // payments
      ('Otros', 0xe574, '#919095'),       // category
    ];

    for (final (name, icon, color) in categoryData) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: name,
          iconCode: icon,
          colorHex: color,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // QUERIES — Categories
  // ---------------------------------------------------------------------------
  Stream<List<Category>> watchAllCategories() =>
      select(categories).watch();

  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<List<Category>> getAllCategories() =>
      select(categories).get();

  // ---------------------------------------------------------------------------
  // QUERIES — Transactions
  // ---------------------------------------------------------------------------
  Stream<List<Transaction>> watchRecentTransactions({int limit = 20}) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch();
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
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

  Stream<List<Transaction>> watchTransactionsByRange(
      DateTime start, DateTime end) {
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

  /// Suma total de TODOS los ingresos (all-time) para patrimonio neto
  Stream<double> watchTotalIncome() {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(transactions.type.equals('income'));
    return query
        .map((row) => row.read(transactions.amount.sum()) ?? 0.0)
        .watchSingle();
  }

  /// Suma total de TODOS los gastos (all-time) para patrimonio neto
  Stream<double> watchTotalExpenses() {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(transactions.type.equals('expense'));
    return query
        .map((row) => row.read(transactions.amount.sum()) ?? 0.0)
        .watchSingle();
  }

  /// Gastos por rango de fechas filtrados por tipo
  Stream<double> watchRangeTotal(DateTime start, DateTime end, String type) {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(transactions.date.isBetweenValues(start, end) &
          transactions.type.equals(type));
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

  Future<int> insertBudget(BudgetsCompanion entry) =>
      into(budgets).insert(entry);

  Future<bool> updateBudget(Budget b) => update(budgets).replace(b);

  Future<int> deleteBudget(int id) =>
      (delete(budgets)..where((b) => b.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // QUERIES — Savings Goals
  // ---------------------------------------------------------------------------
  Stream<List<SavingsGoal>> watchAllGoals() => select(savingsGoals).watch();

  Future<bool> updateGoal(SavingsGoal goal) =>
      update(savingsGoals).replace(goal);

  Future<int> insertGoal(SavingsGoalsCompanion goal) =>
      into(savingsGoals).insert(goal);

  Future<int> deleteGoal(int id) =>
      (delete(savingsGoals)..where((g) => g.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // QUERIES — Debts
  // ---------------------------------------------------------------------------
  Stream<List<Debt>> watchAllDebts() {
    return (select(debts)
          ..orderBy([(d) => OrderingTerm.desc(d.interestRate)]))
        .watch();
  }

  Future<int> insertDebt(DebtsCompanion entry) =>
      into(debts).insert(entry);

  Future<bool> updateDebt(Debt d) => update(debts).replace(d);

  Future<int> deleteDebt(int id) =>
      (delete(debts)..where((d) => d.id.equals(id))).go();
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
