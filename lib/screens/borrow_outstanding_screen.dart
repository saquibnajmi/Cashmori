import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/borrow_model.dart';
import '../theme/app_theme.dart';

class BorrowOutstandingScreen extends StatefulWidget {
  const BorrowOutstandingScreen({super.key});

  @override
  State<BorrowOutstandingScreen> createState() => _BorrowOutstandingScreenState();
}

class _BorrowOutstandingScreenState extends State<BorrowOutstandingScreen> {
  late Future<List<BorrowModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.getAllBorrowRecords();
  }

  void _refresh() => setState(() => _future = DatabaseHelper.instance.getAllBorrowRecords());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow & Outstanding')),
      body: FutureBuilder<List<BorrowModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final records = snapshot.data!;

          final lent = records.where((r) => r.type == 'lent' && r.status == 'outstanding');
          final borrowed = records.where((r) => r.type == 'borrowed' && r.status == 'outstanding');
          final netOwedToYou = lent.fold<double>(0, (s, r) => s + r.amount) -
              borrowed.fold<double>(0, (s, r) => s + r.amount);

          if (records.isEmpty) {
            return const Center(
              child: Text('No records yet. Tap + to add one.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NET BALANCE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(
                      '${netOwedToYou >= 0 ? '+' : ''}${NumberFormat('#,##,##0.00', 'en_IN').format(netOwedToYou)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: netOwedToYou >= 0 ? AppColors.income : AppColors.expense,
                      ),
                    ),
                    Text(
                      netOwedToYou >= 0 ? 'Owed to you overall' : 'You owe overall',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              for (final r in records) _BorrowTile(record: r, onChanged: _refresh),
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
            builder: (_) => const _AddBorrowSheet(),
          );
          if (saved == true) _refresh();
        },
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}

class _BorrowTile extends StatelessWidget {
  final BorrowModel record;
  final VoidCallback onChanged;
  const _BorrowTile({required this.record, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isLent = record.type == 'lent'; // money owed TO you
    final color = isLent ? AppColors.income : AppColors.expense;
    final settled = record.status == 'settled';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: AppTheme.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.personName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    isLent ? 'You lent' : 'You borrowed',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (record.dueDate != null)
                    Text('Due: ${DateFormat('d MMM yyyy').format(record.dueDate!)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (settled)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('SETTLED',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat('#,##,##0', 'en_IN').format(record.amount),
                  style: TextStyle(
                    color: settled ? AppColors.textSecondary : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    decoration: settled ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!settled)
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    onPressed: () async {
                      await DatabaseHelper.instance
                          .updateBorrow(record.copyWith(status: 'settled'));
                      onChanged();
                    },
                    child: const Text('Mark settled', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBorrowSheet extends StatefulWidget {
  const _AddBorrowSheet();

  @override
  State<_AddBorrowSheet> createState() => _AddBorrowSheetState();
}

class _AddBorrowSheetState extends State<_AddBorrowSheet> {
  String _type = 'lent';
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _dueDate;

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (_nameCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a name and valid amount')));
      return;
    }
    await DatabaseHelper.instance.insertBorrow(BorrowModel(
      type: _type,
      personName: _nameCtrl.text.trim(),
      amount: amount,
      date: _date,
      dueDate: _dueDate,
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
              child: Text('ADD BORROW / LENT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          _type == 'lent' ? AppColors.income.withOpacity(0.12) : null,
                      side: BorderSide(color: AppColors.income),
                    ),
                    onPressed: () => setState(() => _type = 'lent'),
                    child: const Text('I LENT', style: TextStyle(color: AppColors.income)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          _type == 'borrowed' ? AppColors.expense.withOpacity(0.12) : null,
                      side: BorderSide(color: AppColors.expense),
                    ),
                    onPressed: () => setState(() => _type = 'borrowed'),
                    child: const Text('I BORROWED', style: TextStyle(color: AppColors.expense)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Person name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime(2015),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Due date (optional)'),
                child: Text(_dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : '—'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('SAVE')),
          ],
        ),
      ),
    );
  }
}
