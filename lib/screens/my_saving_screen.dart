import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import '../widgets/saving_chart.dart';
import '../widgets/transaction_tile.dart';
import 'add_entry_screen.dart';

class MySavingScreen extends StatefulWidget {
  const MySavingScreen({super.key});

  @override
  State<MySavingScreen> createState() => _MySavingScreenState();
}

class _MySavingScreenState extends State<MySavingScreen> {
  late Future<_SavingData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_SavingData> _load() async {
    final total = await DatabaseHelper.instance.getTotalSaving();
    final monthly = await DatabaseHelper.instance.getMonthlyTotals(DateTime.now().year);
    final transactions = await DatabaseHelper.instance.getAllTransactions();
    return _SavingData(total: total, monthly: monthly, transactions: transactions);
  }

  void _refresh() => setState(() => _dataFuture = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Saving')),
      body: FutureBuilder<_SavingData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final grouped = _groupByMonth(data.transactions);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Container(
                  decoration: AppTheme.cardDecoration,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('MY SAVING',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            NumberFormat('#,##,##0.00', 'en_IN').format(data.total),
                            style: const TextStyle(
                                color: AppColors.income,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SavingChart(
                        saving: data.monthly['saving']!,
                        income: data.monthly['income']!,
                        expense: data.monthly['expense']!,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (grouped.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text('No entries yet. Tap + to add one.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                for (final monthKey in grouped.keys) ...[
                  _MonthDivider(label: monthKey),
                  for (final t in grouped[monthKey]!)
                    TransactionTile(
                      transaction: t,
                      onTap: () async {
                        final saved = await showAddEntrySheet(context, existing: t);
                        if (saved == true) _refresh();
                      },
                      onLongPress: () => _confirmDelete(t),
                    ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await showAddEntrySheet(context);
          if (saved == true) _refresh();
        },
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Future<void> _confirmDelete(TransactionModel t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Delete "${t.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && t.id != null) {
      await DatabaseHelper.instance.deleteTransaction(t.id!);
      _refresh();
    }
  }

  /// Groups transactions by "Month Year" (e.g. "AUGUST 2026"), preserving
  /// most-recent-first order, exactly like the mockup's section headers.
  Map<String, List<TransactionModel>> _groupByMonth(List<TransactionModel> list) {
    final map = <String, List<TransactionModel>>{};
    for (final t in list) {
      final key = DateFormat('MMMM yyyy').format(t.date).toUpperCase();
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }
}

class _SavingData {
  final double total;
  final Map<String, List<double>> monthly;
  final List<TransactionModel> transactions;
  _SavingData({required this.total, required this.monthly, required this.transactions});
}

class _MonthDivider extends StatelessWidget {
  final String label;
  const _MonthDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }
}
