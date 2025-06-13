import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:file_manager/Services/sqflite_favorites.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Map<String, dynamic>> list = [];

  void _getFavoriteList() async {
    final favoriteList = await FavoritesDB().getAllFavorites();
    setState(() {
      list = favoriteList;
    });
  }

  @override
  void initState() {
    super.initState();
    _getFavoriteList();
  }

  void _loadContent(String path) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text("Favorites", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          if (list.isNotEmpty)
            TextButton(
              onPressed: () async {
                await FavoritesDB().clearFavorites();
                setState(() {});
                _getFavoriteList();
              },
              child: Text("Clear All"),
            ),
        ],
      ),
      body: list.isNotEmpty
          ? ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final data = list[index];
                final path = data['path'];
                final name = path.toString().split("/").last;
                final isDir = data['isFolder'];
                return ListTile(
                  title: Text(name),
                  subtitle: Text(path.toString(), maxLines: 2),
                  leading: Icon(
                    isDir == 1 ? Icons.folder : Icons.insert_drive_file,
                  ),
                  onTap: () {
                    if (isDir == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FileExplorerScreen(path: path),
                        ),
                      );
                    } else {
                      OpenFilex.open(path);
                    }
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.favorite, color: Colors.red),
                    onPressed: () async {
                      await FavoritesDB().removeFavorite(path);
                      _getFavoriteList();
                    },
                  ),
                );
              },
            )
          : Center(
              child: Text(
                "Favorites is Empty!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ),
    );
  }
}
