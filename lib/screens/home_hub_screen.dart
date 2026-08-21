import 'package:flutter/material.dart';
import '../widgets/hub_card.dart';
import 'my_saving_screen.dart';
import 'borrow_outstanding_screen.dart';
import 'my_shares_screen.dart';
import 'my_assets_screen.dart';
import 'settings_screen.dart';

class HomeHubScreen extends StatefulWidget {
  const HomeHubScreen({super.key});

  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
  Future<void> _openScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashmori'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95,
          children: [
            HubCard(
              icon: Icons.account_balance_wallet_rounded,
              label: 'MY SAVING',
              onTap: () => _openScreen(const MySavingScreen()),
            ),
            HubCard(
              icon: Icons.handshake_rounded,
              label: 'BORROW &\nOUTSTANDING',
              onTap: () => _openScreen(const BorrowOutstandingScreen()),
            ),
            HubCard(
              icon: Icons.donut_large_rounded,
              label: 'MY SHARES',
              onTap: () => _openScreen(const MySharesScreen()),
            ),
            HubCard(
              icon: Icons.apartment_rounded,
              label: 'MY ASSETS',
              onTap: () => _openScreen(const MyAssetsScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
