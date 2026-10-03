import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 3: the dark/light mode switch now lives on its own
// Settings page instead of in the Home app bar.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          text: 'Settings',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            activeThumbColor: theme.colorScheme.secondary,
            title: CustomText(
              text: themeProvider.isDark ? 'Dark Mode' : 'Light Mode',
            ),
            subtitle: const CustomText(
              text: 'Toggle between light and dark theme',
              fontSize: 12,
            ),
            value: themeProvider.isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const CustomText(text: 'Log out'),
            onTap: () async {
              try {
                await UserService().signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/signin',
                  (route) => false,
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.toString())));
              }
            },
          ),
        ],
      ),
    );
  }
}
