import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

// Row UI for each transaction in the saving list. It highlights amounts and category metadata.
class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
  });

  /// Renders a transaction row with the amount, date, category, and direction icon.
  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final color = isExpense ? AppColors.expense : AppColors.income;
    final amountStr =
        MoneyFormatter.format(transaction.amount, withDecimal: false);
    final dateStr = DateFormat('d MMMM yyyy').format(transaction.date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description.isEmpty
                          ? transaction.subCategory ?? transaction.category
                          : transaction.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(dateStr,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        text: 'Category : ',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        children: [
                          TextSpan(
                            text: transaction.subCategory != null
                                ? '${transaction.category} > ${transaction.subCategory}'
                                : transaction.category,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    amountStr,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                  Icon(
                    isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
                    size: 18,
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
