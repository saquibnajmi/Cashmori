import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import '../widgets/saving_chart.dart';
import '../widgets/transaction_tile.dart';
import 'add_entry_screen.dart';

const String _mySavingSummaryVisibleKey = 'my_saving_summary_visible';

// Screen that shows the total saving, monthly chart, and all transactions in grouped months.
class MySavingScreen extends StatefulWidget {
  const MySavingScreen({super.key});

  @override
  State<MySavingScreen> createState() => _MySavingScreenState();
}

class _MySavingScreenState extends State<MySavingScreen> {
  late Future<_SavingData> _dataFuture;
  late final ValueNotifier<int> _refreshToken;
  bool _showSummary = true;

  @override
  void initState() {
    super.initState();
    _refreshToken = DatabaseHelper.instance.refreshNotifier;
    _refreshToken.addListener(_onDatabaseChanged);
    _loadSummaryVisibilityPreference();
    _dataFuture = _load();
  }

  /// Loads the saved preference for whether the summary card should be visible by default.
  Future<void> _loadSummaryVisibilityPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
        () => _showSummary = prefs.getBool(_mySavingSummaryVisibleKey) ?? true);
  }

  @override
  void dispose() {
    _refreshToken.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  /// Refreshes the data when the shared database notifier triggers an update.
  void _onDatabaseChanged() {
    if (!mounted) return;
    _refresh();
  }

  /// Loads totals, monthly statistics, and transaction rows for the dashboard summary.
  Future<_SavingData> _load() async {
    final total = await DatabaseHelper.instance.getTotalSaving();
    final monthly =
        await DatabaseHelper.instance.getMonthlyTotals(DateTime.now().year);
    final transactions = await DatabaseHelper.instance.getAllTransactions();
    return _SavingData(
        total: total, monthly: monthly, transactions: transactions);
  }

  /// Rebuilds the screen with the latest database data.
  void _refresh() => setState(() => _dataFuture = _load());

  /// Renders the saving screen with the summary card, chart, and month-based transaction list.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Saving'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: _showSummary ? 'Hide summary' : 'Show summary',
              onPressed: () => setState(() => _showSummary = !_showSummary),
              icon: Icon(
                _showSummary ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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
                Offstage(
                  offstage: !_showSummary,
                  child: AnimatedOpacity(
                    opacity: _showSummary ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('MY SAVING',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(
                                MoneyFormatter.format(data.total),
                                style: TextStyle(
                                    color: data.total >= 0
                                        ? AppColors.income
                                        : AppColors.expense,
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
                        final saved =
                            await showAddEntrySheet(context, existing: t);
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

  /// Returns a readable label for a transaction when showing delete confirmation.
  String _entryLabel(TransactionModel t) {
    final cleaned = t.description.trim();
    if (cleaned.isNotEmpty) return cleaned;
    if (t.subCategory != null && t.subCategory!.trim().isNotEmpty) {
      return t.subCategory!;
    }
    return t.category;
  }

  /// Confirms and deletes a transaction entry from the database.
  Future<void> _confirmDelete(TransactionModel t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Delete "${_entryLabel(t)}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
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
  /// Groups transactions by month and year so the screen can display chronological sections.
  Map<String, List<TransactionModel>> _groupByMonth(
      List<TransactionModel> list) {
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
  _SavingData(
      {required this.total, required this.monthly, required this.transactions});
}

class _MonthDivider extends StatelessWidget {
  final String label;
  const _MonthDivider({required this.label});

  /// Draws a divider with the month name between transaction groups.
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }
}
