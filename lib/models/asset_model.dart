class AssetModel {
  final int? id;
  final String name;
  final String assetType; // Property, Gold, Vehicle, Other
  final double value;
  final DateTime purchaseDate;
  final String? notes;

  AssetModel({
    this.id,
    required this.name,
    required this.assetType,
    required this.value,
    required this.purchaseDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'asset_type': assetType,
      'value': value,
      'purchase_date': purchaseDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory AssetModel.fromMap(Map<String, dynamic> map) {
    return AssetModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      assetType: map['asset_type'] as String,
      value: (map['value'] as num).toDouble(),
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      notes: map['notes'] as String?,
    );
  }
}

const List<String> kAssetTypes = ['Property', 'Gold', 'Vehicle', 'Other'];
