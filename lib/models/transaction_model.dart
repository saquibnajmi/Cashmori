class TransactionModel {
  final int? id;
  final String type; // 'expense' or 'income'
  final double amount;
  final DateTime date;
  final String category;
  final String? subCategory;
  final String description;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
    this.subCategory,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'sub_category': subCategory,
      'description': description,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      subCategory: map['sub_category'] as String?,
      description: map['description'] as String,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? type,
    double? amount,
    DateTime? date,
    String? category,
    String? subCategory,
    String? description,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      description: description ?? this.description,
    );
  }
}

/// Static category -> subcategory map used to populate the dropdowns
/// on the Add Entry screen. Feel free to extend.
const Map<String, List<String>> kExpenseCategories = {
  'Food': ['Snacks', 'Lunch', 'Dinner', 'Breakfast', 'Groceries'],
  'Travel': ['Bus Ticket', 'Fuel', 'Cab', 'Flight'],
  'Shopping': ['Clothes', 'Electronics', 'Accessories'],
  'Lodging': ['Hotel', 'Rent'],
  'Bills': ['Electricity', 'Water', 'Internet', 'Mobile Recharge'],
  'Health': ['Medicine', 'Doctor', 'Insurance'],
  'Entertainment': ['Movies', 'Subscriptions', 'Games'],
  'Other': ['Misc'],
};

const Map<String, List<String>> kIncomeCategories = {
  'Income': ['Salary', 'Bonus', 'Freelance'],
  'Reimbursement': ['Travel', 'Medical', 'Other'],
  'Investment': ['Dividend', 'Interest'],
  'Other': ['Gift', 'Misc'],
};
