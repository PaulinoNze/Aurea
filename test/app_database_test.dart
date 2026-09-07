import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:aurea/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Database starts with base categories and 0 user records', () async {
    final categories = await db.getAllCategories();
    expect(categories.isNotEmpty, isTrue);

    final transactions = await db.watchAllTransactions().first;
    expect(transactions.isEmpty, isTrue);

    final goals = await db.watchAllGoals().first;
    expect(goals.isEmpty, isTrue);

    final debts = await db.watchAllDebts().first;
    expect(debts.isEmpty, isTrue);
  });

  test('Insert goal contribution and debt payment', () async {
    final goalId = await db.insertGoal(SavingsGoalsCompanion.insert(
      name: 'Vacaciones Test',
      targetAmount: 500.0,
      deadline: Value(DateTime.now().add(const Duration(days: 60))),
    ));

    expect(goalId, greaterThan(0));

    await db.insertGoalContribution(GoalContributionsCompanion.insert(
      goalId: goalId,
      amount: 150.0,
      date: DateTime.now(),
    ));

    final totalContrib = await db.watchTotalContributedForGoal(goalId).first;
    expect(totalContrib, equals(150.0));

    final debtId = await db.insertDebt(DebtsCompanion.insert(
      name: 'Tarjeta Test',
      remainingAmount: 1000.0,
      interestRate: 15.0,
      minimumPayment: 50.0,
    ));

    expect(debtId, greaterThan(0));

    await db.insertDebtPayment(DebtPaymentsCompanion.insert(
      debtId: debtId,
      amount: 200.0,
      date: DateTime.now(),
    ));

    final totalPaid = await db.watchTotalPaidForDebt(debtId).first;
    expect(totalPaid, equals(200.0));
  });
}
