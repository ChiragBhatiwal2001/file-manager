import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:file_manager/Providers/limit_setting_provider.dart';
import 'package:file_manager/Providers/theme_notifier.dart';
import 'package:flutter/material.dart';
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
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 6.0),
            child: Text(
              "Interface",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: Text(
              "Theme",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            trailing: Switch(
              value: isDark,
              onChanged: (_) {
                ref.read(themeNotifierProvider.notifier).toggleTheme();
              },
            ),
          ),
          Divider(),
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
                      return AlertDialog(
                        title: Text("Recent Files Showing Limit"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _limitRecentController,
                              keyboardType: TextInputType.number,
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
                                  _limitRecentController.clear();
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
              );
            },
          ),
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
                      return AlertDialog(
                        title: Text("Favorites Files Showing Limit"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _limitFavoriteController,
                              keyboardType: TextInputType.number,
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
                                  _limitFavoriteController.clear();
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
              );
            },
          ),
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
