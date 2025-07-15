import 'package:file_manager/Utils/sort_enum.dart';
import 'package:flutter/material.dart';

class SortDialog extends StatefulWidget {
  final String initialSortBy;
  final String initialSortOrder;
  final bool showPathSpecificOption;

  const SortDialog({
    super.key,
    required this.initialSortBy,
    required this.initialSortOrder,
    this.showPathSpecificOption = false,
  });

  @override
  State<SortDialog> createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  late String _sortBy;
  late String _sortOrder;
  bool _applyToCurrentPath = false;

  bool get _finalApplyToCurrentPath =>
      _sortBy == SortByType.drag.name ? true : (widget.showPathSpecificOption ? _applyToCurrentPath : true);

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSortBy;
    _sortOrder = widget.initialSortOrder;
    if (_sortBy == SortByType.drag.name) {
      _applyToCurrentPath = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Sort By"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile(
            title: Text(SortByType.name.displayName),
            value: SortByType.name.name,
            groupValue: _sortBy,
            onChanged: (val) => setState(() => _sortBy = val as String),
          ),
          RadioListTile(
            title: Text(SortByType.size.displayName),
            value: SortByType.size.name,
            groupValue: _sortBy,
            onChanged: (val) => setState(() => _sortBy = val as String),
          ),
          RadioListTile(
            title: const Text("Last Modified"),
            value: SortByType.modified.name,
            groupValue: _sortBy,
            onChanged: (val) => setState(() => _sortBy = val as String),
          ),
          RadioListTile(
            title: Text(SortByType.type.displayName),
            value: SortByType.type.name,
            groupValue: _sortBy,
            onChanged: (val) => setState(() => _sortBy = val as String),
          ),
          if (widget.showPathSpecificOption)
            RadioListTile(
              title: const Text("Manual Drag"),
              value: SortByType.drag.name,
              groupValue: _sortBy,
              onChanged: (val) {
                setState(() {
                  _sortBy = val as String;
                  _applyToCurrentPath = true; // Force path-specific
                });
              },
            ),
          if (widget.showPathSpecificOption && _sortBy != SortByType.drag.name)
            SwitchListTile(
              key: ValueKey("switch-$_applyToCurrentPath"),
              title: const Text("Only this folder"),
              value: _applyToCurrentPath,
              onChanged: (val) => setState(() => _applyToCurrentPath = val),
            ),
          if (_sortBy == SortByType.drag.name)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, {
                    "sortBy": SortByType.drag.name,
                    "sortOrder": SortByType.drag.name,
                    "applyToCurrentPath": _finalApplyToCurrentPath,
                  });
                },
                child: const Text("OK"),
              ),
            ),
          if (_sortBy != SortByType.drag.name)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    _sortOrder = SortOrderType.desc.name;
                    Navigator.pop(context, {
                      "sortBy": _sortBy,
                      "sortOrder": _sortOrder,
                      "applyToCurrentPath": _finalApplyToCurrentPath,
                    });
                  },
                  child: const Text("Descending"),
                ),
                TextButton(
                  onPressed: () {
                    _sortOrder = SortOrderType.asc.name;
                    Navigator.pop(context, {
                      "sortBy": _sortBy,
                      "sortOrder": _sortOrder,
                      "applyToCurrentPath": _finalApplyToCurrentPath,
                    });
                  },
                  child: const Text("Ascending"),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

