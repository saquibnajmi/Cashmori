class ShareModel {
  final int? id;
  final String companyName;
  final double quantity;
  final double buyPrice;
  final double currentPrice;
  final DateTime purchaseDate;
  final String? notes;

  ShareModel({
    this.id,
    required this.companyName,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    required this.purchaseDate,
    this.notes,
  });

  double get investedValue => quantity * buyPrice;
  double get currentValue => quantity * currentPrice;
  double get gainLoss => currentValue - investedValue;
  double get gainLossPercent =>
      investedValue == 0 ? 0 : (gainLoss / investedValue) * 100;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'quantity': quantity,
      'buy_price': buyPrice,
      'current_price': currentPrice,
      'purchase_date': purchaseDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory ShareModel.fromMap(Map<String, dynamic> map) {
    return ShareModel(
      id: map['id'] as int?,
      companyName: map['company_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      buyPrice: (map['buy_price'] as num).toDouble(),
      currentPrice: (map['current_price'] as num).toDouble(),
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      notes: map['notes'] as String?,
    );
  }
}
