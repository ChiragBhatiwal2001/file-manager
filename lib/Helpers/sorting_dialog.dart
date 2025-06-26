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
      widget.showPathSpecificOption ? _applyToCurrentPath : true;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSortBy;
    _sortOrder = widget.initialSortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Sort By"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile(
            title: const Text("Name"),
            value: "name",
            groupValue: _sortBy,
            onChanged: (val) => setState(() => _sortBy = val as String),
          ),
          RadioListTile(
            title: const Text("Size"),
            value: "size",
            groupValue: _sortBy,
            onChanged: (val) => setState(() => _sortBy = val as String),
          ),
          RadioListTile(
            title: const Text("Last Modified"),
            value: "modified",
            groupValue: _sortBy,
            onChanged: (val) => setState(() => _sortBy = val as String),
          ),
          RadioListTile(
            title: const Text("Type"),
            value: "type",
            groupValue: _sortBy,
            onChanged: (val) => setState(() => _sortBy = val as String),
          ),
          if (widget.showPathSpecificOption)
            RadioListTile(
              title: const Text("Manual Drag"),
              value: "drag",
              groupValue: _sortBy,
              onChanged: (val) {
                setState(() {
                  _sortBy = val as String;
                  _applyToCurrentPath = true;
                });
              },
            ),
          if (widget.showPathSpecificOption)
            SwitchListTile(
              key: ValueKey("switch-$_applyToCurrentPath"),
              title: const Text("only this folder"),
              value: _applyToCurrentPath,
              onChanged: (val) => setState(() => _applyToCurrentPath = val),
            ),
          if (_sortBy == "drag")
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, {
                    "sortBy": "drag",
                    "sortOrder": "drag",
                    "applyToCurrentPath": _finalApplyToCurrentPath,
                  });
                },
                child: const Text("OK"),
              ),
            ),
          if(_sortBy != "drag")
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    _sortOrder = "desc";
                    Navigator.pop(context, {
                      "sortBy": _sortBy,
                      "sortOrder": _sortOrder,
                      "applyToCurrentPath": _applyToCurrentPath,
                    });
                  },
                  child: const Text("Descending"),
                ),
                TextButton(
                  onPressed: () {
                    _sortOrder = "asc";
                    Navigator.pop(context, {
                      "sortBy": _sortBy,
                      "sortOrder": _sortOrder,
                      "applyToCurrentPath": _applyToCurrentPath,
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
