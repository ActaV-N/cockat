import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../cocktails/cocktails_screen.dart';
import '../products/my_bar_screen.dart';
import '../products/products_catalog_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const _screenNames = ['Cocktails', 'MyBar', 'Products', 'Profile'];

  @override
  void initState() {
    super.initState();
    _logScreenView(0);
  }

  void _logScreenView(int index) {
    ref.read(analyticsServiceProvider).logScreenView(
          screenName: _screenNames[index],
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screens = [
      const CocktailsScreen(),
      const MyBarScreen(),
      const ProductsCatalogScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _logScreenView(index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.local_bar_outlined),
            selectedIcon: const Icon(Icons.local_bar),
            label: l10n.cocktails,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: l10n.myBar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.liquor_outlined),
            selectedIcon: const Icon(Icons.liquor),
            label: l10n.products,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
