import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/share_model.dart';
import '../theme/app_theme.dart';

class MySharesScreen extends StatefulWidget {
  const MySharesScreen({super.key});

  @override
  State<MySharesScreen> createState() => _MySharesScreenState();
}

class _MySharesScreenState extends State<MySharesScreen> {
  late Future<List<ShareModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.getAllShares();
  }

  void _refresh() => setState(() => _future = DatabaseHelper.instance.getAllShares());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Shares')),
      body: FutureBuilder<List<ShareModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final shares = snapshot.data!;

          if (shares.isEmpty) {
            return const Center(
              child: Text('No shares yet. Tap + to add one.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          final totalInvested = shares.fold<double>(0, (s, x) => s + x.investedValue);
          final totalCurrent = shares.fold<double>(0, (s, x) => s + x.currentValue);
          final totalGain = totalCurrent - totalInvested;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PORTFOLIO VALUE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(NumberFormat('#,##,##0.00', 'en_IN').format(totalCurrent),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${totalGain >= 0 ? '+' : ''}${NumberFormat('#,##,##0.00', 'en_IN').format(totalGain)} overall',
                      style: TextStyle(
                        color: totalGain >= 0 ? AppColors.income : AppColors.expense,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              for (final s in shares) _ShareTile(share: s, onDeleted: _refresh),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _AddShareSheet(),
          );
          if (saved == true) _refresh();
        },
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  final ShareModel share;
  final VoidCallback onDeleted;
  const _ShareTile({required this.share, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final gainColor = share.gainLoss >= 0 ? AppColors.income : AppColors.expense;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onLongPress: () async {
          if (share.id != null) {
            await DatabaseHelper.instance.deleteShare(share.id!);
            onDeleted();
          }
        },
        child: Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(share.companyName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${share.quantity.toStringAsFixed(0)} qty @ ${share.buyPrice.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(NumberFormat('#,##,##0.00', 'en_IN').format(share.currentValue),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '${share.gainLoss >= 0 ? '+' : ''}${share.gainLossPercent.toStringAsFixed(1)}%',
                    style: TextStyle(color: gainColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddShareSheet extends StatefulWidget {
  const _AddShareSheet();

  @override
  State<_AddShareSheet> createState() => _AddShareSheetState();
}

class _AddShareSheetState extends State<_AddShareSheet> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _buyCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  Future<void> _save() async {
    final qty = double.tryParse(_qtyCtrl.text.trim());
    final buy = double.tryParse(_buyCtrl.text.trim());
    final current = double.tryParse(_currentCtrl.text.trim());
    if (_nameCtrl.text.trim().isEmpty || qty == null || buy == null || current == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill all fields correctly')));
      return;
    }
    await DatabaseHelper.instance.insertShare(ShareModel(
      companyName: _nameCtrl.text.trim(),
      quantity: qty,
      buyPrice: buy,
      currentPrice: current,
      purchaseDate: _date,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text('ADD SHARE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 18),
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Company name')),
            const SizedBox(height: 14),
            TextField(
              controller: _qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _buyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Buy price (per share)'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _currentCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Current price (per share)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('SAVE')),
          ],
        ),
      ),
    );
  }
}
