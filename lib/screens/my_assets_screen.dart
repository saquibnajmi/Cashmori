import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/asset_model.dart';
import '../theme/app_theme.dart';

class MyAssetsScreen extends StatefulWidget {
  const MyAssetsScreen({super.key});

  @override
  State<MyAssetsScreen> createState() => _MyAssetsScreenState();
}

class _MyAssetsScreenState extends State<MyAssetsScreen> {
  late Future<List<AssetModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.getAllAssets();
  }

  void _refresh() => setState(() => _future = DatabaseHelper.instance.getAllAssets());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Assets')),
      body: FutureBuilder<List<AssetModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final assets = snapshot.data!;

          if (assets.isEmpty) {
            return const Center(
              child: Text('No assets yet. Tap + to add one.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          final total = assets.fold<double>(0, (s, a) => s + a.value);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL ASSET VALUE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(NumberFormat('#,##,##0.00', 'en_IN').format(total),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              for (final a in assets) _AssetTile(asset: a, onDeleted: _refresh),
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
            builder: (_) => const _AddAssetSheet(),
          );
          if (saved == true) _refresh();
        },
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  final AssetModel asset;
  final VoidCallback onDeleted;
  const _AssetTile({required this.asset, required this.onDeleted});

  IconData get _icon {
    switch (asset.assetType) {
      case 'Property':
        return Icons.home_work_rounded;
      case 'Gold':
        return Icons.workspace_premium_rounded;
      case 'Vehicle':
        return Icons.directions_car_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onLongPress: () async {
          if (asset.id != null) {
            await DatabaseHelper.instance.deleteAsset(asset.id!);
            onDeleted();
          }
        },
        child: Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(_icon, size: 32, color: AppColors.textPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(asset.assetType,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text(NumberFormat('#,##,##0', 'en_IN').format(asset.value),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddAssetSheet extends StatefulWidget {
  const _AddAssetSheet();

  @override
  State<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<_AddAssetSheet> {
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  String _assetType = kAssetTypes.first;
  DateTime _date = DateTime.now();

  Future<void> _save() async {
    final value = double.tryParse(_valueCtrl.text.trim());
    if (_nameCtrl.text.trim().isEmpty || value == null || value <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a name and valid value')));
      return;
    }
    await DatabaseHelper.instance.insertAsset(AssetModel(
      name: _nameCtrl.text.trim(),
      assetType: _assetType,
      value: value,
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
              child: Text('ADD ASSET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 18),
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Asset name (e.g. Flat, Car)')),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _assetType,
              items: kAssetTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _assetType = v ?? _assetType),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Current value'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('SAVE')),
          ],
        ),
      ),
    );
  }
}
