import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

/// Shows the "Add New Entry" bottom sheet. Returns true via Navigator.pop
/// if a transaction was saved, so the caller can refresh its list.
Future<bool?> showAddEntrySheet(BuildContext context,
    {TransactionModel? existing}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddEntrySheet(existing: existing),
  );
}

class AddEntrySheet extends StatefulWidget {
  final TransactionModel? existing;
  const AddEntrySheet({super.key, this.existing});

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  late String _type;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late DateTime _date;
  String? _category;
  String? _subCategory;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? 'expense';
    _amountCtrl.text = e != null ? e.amount.toStringAsFixed(2) : '';
    _descCtrl.text = e?.description ?? '';
    _date = e?.date ?? DateTime.now();
    _category = e?.category;
    _subCategory = e?.subCategory;
  }

  Map<String, List<String>> get _categoryMap =>
      _type == 'expense' ? kExpenseCategories : kIncomeCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }

    final tx = TransactionModel(
      id: widget.existing?.id,
      type: _type,
      amount: amount,
      date: _date,
      category: _category!,
      subCategory: _subCategory,
      description: _descCtrl.text.trim(),
    );

    if (widget.existing != null) {
      await DatabaseHelper.instance.updateTransaction(tx);
    } else {
      await DatabaseHelper.instance.insertTransaction(tx);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryMap.keys.toList();
    final subCategories =
        _category != null ? (_categoryMap[_category] ?? []) : <String>[];

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  widget.existing != null ? 'EDIT ENTRY' : 'ADD NEW ENTRY',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _typeButton('EXPENSE', 'expense', AppColors.expense),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _typeButton('INCOME', 'income', AppColors.income),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _labeledField(
                      'AMOUNT',
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(hintText: '0.00'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _labeledField(
                      'DATE',
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(DateFormat('dd/MM/yyyy').format(_date)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _labeledField(
                'CATEGORY',
                DropdownButtonFormField<String>(
                  initialValue:
                      categories.contains(_category) ? _category : null,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _category = v;
                    _subCategory = null;
                  }),
                  decoration: const InputDecoration(),
                ),
              ),
              const SizedBox(height: 14),
              _labeledField(
                'SUB - CATEGORY',
                DropdownButtonFormField<String>(
                  initialValue: subCategories.contains(_subCategory)
                      ? _subCategory
                      : null,
                  items: subCategories
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _subCategory = v),
                  decoration: const InputDecoration(),
                ),
              ),
              const SizedBox(height: 14),
              _labeledField(
                'DESCRIPTION',
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. T-shirt'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('SAVE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String label, String value, Color color) {
    final selected = _type == value;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? color.withValues(alpha: 0.12) : null,
        side: BorderSide(color: color, width: selected ? 2 : 1),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => setState(() {
        _type = value;
        _category = null;
        _subCategory = null;
      }),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
