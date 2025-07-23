import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:file_manager/Providers/limit_setting_provider.dart';
import 'package:file_manager/Providers/theme_notifier.dart';
import 'package:file_manager/Services/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() {
    return _SettingScreenState();
  }
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  final _limitRecentController = TextEditingController();
  final _limitFavoriteController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _limitRecentController.dispose();
    _limitFavoriteController.dispose();
  }

  String _getThemeSubtitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return "Dark theme enabled";
      case ThemeMode.light:
        return "Light theme enabled";
      case ThemeMode.system:
        return "System default theme";
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.system:
        return Icons.brightness_6_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    final hiddenNotifier = ref.read(hiddenPathsProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Theme
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 6.0),
            child: Text(
              "Interface",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _SettingTile(
            title: "UI mode",
            subtitle: _getThemeSubtitle(ref.watch(themeNotifierProvider)),
            icon: _getThemeIcon(ref.watch(themeNotifierProvider)),
            onTap: () async {
              String current =
                  SharedPrefsService.instance.getString('themeMode') ?? 'system';

              String? selected = await showDialog<String>(
                context: context,
                builder: (context) {
                  String tempSelection = current;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text("Choose Theme"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: const Text('System Theme'),
                              value: 'system',
                              groupValue: tempSelection,
                              onChanged: (value) {
                                setState(() => tempSelection = value!);
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Light Theme'),
                              value: 'light',
                              groupValue: tempSelection,
                              onChanged: (value) {
                                setState(() => tempSelection = value!);
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Dark Theme'),
                              value: 'dark',
                              groupValue: tempSelection,
                              onChanged: (value) {
                                setState(() => tempSelection = value!);
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          ElevatedButton(
                            child: const Text("Apply"),
                            onPressed: () =>
                                Navigator.pop(context, tempSelection),
                          ),
                        ],
                      );
                    },
                  );
                },
              );

              if (selected != null) {
                await ref
                    .read(themeNotifierProvider.notifier)
                    .setTheme(selected);
              }
            },
          ),
          Divider(),
          //Recent
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 6.0),
            child: Text(
              "General",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: Text(
              "Recent Files Limit",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Limit size of Recent Files List"),
            leading: Icon(Icons.history),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  String? errorText;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      final focusNode = FocusNode();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        focusNode.requestFocus();
                      });
                      return AlertDialog(
                        title: Text("Recent Files Showing Limit"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              focusNode: focusNode,
                              controller: _limitRecentController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                hintText: "Enter Limit (25-150)",
                                errorText: errorText,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                final value = int.tryParse(
                                  _limitRecentController.text.trim(),
                                );
                                if (value == null ||
                                    value < 25 ||
                                    value > 150) {
                                  setState(() {
                                    errorText = "choose between 25 to 150";
                                  });
                                  FocusScope.of(context).unfocus();
                                  return;
                                } else {
                                  Navigator.pop(context);
                                  FocusScope.of(context).unfocus();
                                  ref
                                      .read(limitSettingsProvider.notifier)
                                      .updateRecentLimit(value);
                                  _limitRecentController.clear();
                                }
                              },
                              child: Text("Save"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ).then((_){
                _limitRecentController.clear();
              });
            },
          ),
          //Favorite
          ListTile(
            title: Text(
              "Favorites Files Limit",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Limit size of Favorite Files List"),
            leading: Icon(Icons.favorite),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  String? errorText;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      final focusNode = FocusNode();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        focusNode.requestFocus();
                      });
                      return AlertDialog(
                        title: Text("Favorites Files Showing Limit"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              focusNode: focusNode,
                              controller: _limitFavoriteController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                hintText: "Enter Limit (2–25)",
                                errorText: errorText,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                final value = int.tryParse(
                                  _limitFavoriteController.text.trim(),
                                );
                                if (value == null || value < 2 || value > 25) {
                                  setState(() {
                                    errorText = "choose between 2 to 25";
                                  });
                                  FocusScope.of(context).unfocus();
                                  return;
                                } else {
                                  Navigator.pop(context);
                                  FocusScope.of(context).unfocus();
                                  ref
                                      .read(limitSettingsProvider.notifier)
                                      .updateFavoriteLimit(value);
                                  _limitFavoriteController.clear();
                                }
                              },
                              child: Text("Save"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ).then((_){
                _limitFavoriteController.clear();
              });
            },
          ),
          //Hide
          ListTile(
            title: Text(
              "Show Hidden Files and Folders",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Enable to show hidden files and folders"),
            leading: Icon(Icons.visibility_off),
            trailing: Switch(
              value: ref.watch(hiddenPathsProvider).showHidden,
              onChanged: (_) {
                hiddenNotifier.toggleShowHidden();
              },
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueGrey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
