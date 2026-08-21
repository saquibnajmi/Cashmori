class BorrowModel {
  final int? id;
  final String type; // 'borrowed' (you owe) or 'lent' (owed to you)
  final String personName;
  final double amount;
  final DateTime date;
  final DateTime? dueDate;
  final String status; // 'outstanding' or 'settled'
  final String? notes;

  BorrowModel({
    this.id,
    required this.type,
    required this.personName,
    required this.amount,
    required this.date,
    this.dueDate,
    this.status = 'outstanding',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'person_name': personName,
      'amount': amount,
      'date': date.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory BorrowModel.fromMap(Map<String, dynamic> map) {
    return BorrowModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      personName: map['person_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      status: map['status'] as String,
      notes: map['notes'] as String?,
    );
  }

  BorrowModel copyWith({String? status}) {
    return BorrowModel(
      id: id,
      type: type,
      personName: personName,
      amount: amount,
      date: date,
      dueDate: dueDate,
      status: status ?? this.status,
      notes: notes,
    );
  }
}
