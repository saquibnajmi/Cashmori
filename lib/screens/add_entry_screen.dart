import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../services/custom_subcategory_service.dart';
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
  List<String> _customSubcategories = const [];
  bool _isLoadingSubcategories = false;

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
    _refreshCustomSubcategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_category != null) {
      _refreshCustomSubcategories();
    }
  }

  Map<String, List<String>> get _categoryMap =>
      _type == 'expense' ? kExpenseCategories : kIncomeCategories;

  Future<void> _refreshCustomSubcategories() async {
    if (_category == null) {
      setState(() => _customSubcategories = const []);
      return;
    }

    setState(() => _isLoadingSubcategories = true);
    final custom = await CustomSubcategoryService.load(_category!);
    if (!mounted) return;
    setState(() {
      _customSubcategories = custom;
      _isLoadingSubcategories = false;
    });
  }

  List<String> get _combinedSubcategories {
    final defaults = _category != null
        ? (_categoryMap[_category] ?? <String>[])
        : <String>[];
    final items = [...defaults, ..._customSubcategories];
    return items.toSet().toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _onCategoryChanged(String? value) {
    setState(() {
      _category = value;
      _subCategory = null;
    });
    if (value != null) {
      _refreshCustomSubcategories();
    }
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

  Future<void> _addSubcategory() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add sub-category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'e.g. Share Auto Rikshaw'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category first')),
      );
      return;
    }

    await CustomSubcategoryService.add(_category!, result);
    await _refreshCustomSubcategories();
    if (mounted) setState(() => _subCategory = result);
  }

  Future<void> _editSubcategory(String value) async {
    final controller = TextEditingController(text: value);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit sub-category'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || _category == null) return;
    if (_categoryMap[_category] != null &&
        _categoryMap[_category]!.contains(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Default sub-categories cannot be edited')),
      );
      return;
    }

    await CustomSubcategoryService.update(_category!, value, result);
    await _refreshCustomSubcategories();
    if (mounted) setState(() => _subCategory = result);
  }

  Future<void> _deleteCustomSubcategory(String value) async {
    if (_category == null) return;
    if (_categoryMap[_category] != null &&
        _categoryMap[_category]!.contains(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Default sub-categories cannot be deleted')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete sub-category?'),
        content: Text('Delete "$value"?'),
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

    if (confirm != true) return;
    await CustomSubcategoryService.remove(_category!, value);
    await _refreshCustomSubcategories();
    if (_subCategory == value) {
      if (mounted) setState(() => _subCategory = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryMap.keys.toList();
    final subCategories = _combinedSubcategories;

    if (_category != null && !_isLoadingSubcategories) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_subCategory != null && !subCategories.contains(_subCategory)) {
          setState(() => _subCategory = null);
        }
      });
    }

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
                  onChanged: _onCategoryChanged,
                  decoration: const InputDecoration(),
                ),
              ),
              if (_category != null) ...[
                const SizedBox(height: 14),
                _labeledField(
                  'SUB - CATEGORY',
                  Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: subCategories.contains(_subCategory)
                            ? _subCategory
                            : null,
                        items: subCategories.map((s) {
                          final bool showActions =
                              !_categoryMap[_category]!.contains(s) &&
                                  s != _subCategory;

                          return DropdownMenuItem(
                            value: s,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(s)),
                                if (showActions)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _editSubcategory(s),
                                        icon: const Icon(Icons.edit, size: 22),
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        splashRadius: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        onPressed: () =>
                                            _deleteCustomSubcategory(s),
                                        icon: const Icon(Icons.delete_outline,
                                            size: 22),
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        splashRadius: 18,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _subCategory = v),
                        decoration: const InputDecoration(),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _addSubcategory,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add, size: 18),
                                SizedBox(width: 4),
                                Text('Add sub-category'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(52, 52),
                        shape: const CircleBorder(),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 22),
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
