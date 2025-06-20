import 'dart:io';
import 'dart:typed_data';

import 'package:file_manager/Services/recycler_bin.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class RecentlyDeletedScreen extends StatefulWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  State<RecentlyDeletedScreen> createState() => _RecentlyDeletedScreenState();
}

class _RecentlyDeletedScreenState extends State<RecentlyDeletedScreen> {
  List<Map<String, dynamic>> deletedItems = [];

  @override
  void initState() {
    super.initState();
    _loadDeletedItems();
  }

  Future<void> _loadDeletedItems() async {
    final items = await RecentlyDeletedManager().getDeletedItems();
    if (mounted) {
      setState(() => deletedItems = items);
    }
  }

  Future<void> _restoreItem(String trashedPath) async {
    await RecentlyDeletedManager().restoreFromTrash(trashedPath);
    await _loadDeletedItems();
  }

  Future<void> _deleteItem(String trashedPath) async {
    final confirmed = await _showConfirmationDialog("Delete Permanently", "Are you sure?");
    if (confirmed) {
      await RecentlyDeletedManager().permanentlyDelete(trashedPath);
      await _loadDeletedItems();
    }
  }

  Future<void> _deleteAllItems() async {
    final confirmed = await _showConfirmationDialog("Delete All", "Delete all items permanently?");
    if (confirmed) {
      await RecentlyDeletedManager().deleteAll();
      await _loadDeletedItems();
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return (await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    )) ??
        false;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delete_outline, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Recycle Bin is empty',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> item) {
    final trashedPath = item['trashedPath'];
    final originalPath = item['originalPath'];
    final isDir = FileSystemEntity.typeSync(trashedPath) == FileSystemEntityType.directory;

    return ListTile(
      leading: FutureBuilder<Uint8List?>(
        future: ThumbnailService.getThumbnail(trashedPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(snapshot.data!, width: 40, height: 40, fit: BoxFit.cover),
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              color: Colors.grey[200],
              child: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
            ),
          );
        },
      ),
      title: Text(p.basename(originalPath)),
      subtitle: Text("From: $originalPath", maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _restoreItem(trashedPath),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _deleteItem(trashedPath),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recycle Bin", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: BackButton(),
        actions: [
          if (deletedItems.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text("Delete All"),
              onPressed: _deleteAllItems,
            ),
        ],
      ),
      body: deletedItems.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        itemCount: deletedItems.length,
        itemBuilder: (_, index) => _buildListTile(deletedItems[index]),
      ),
    );
  }
}
