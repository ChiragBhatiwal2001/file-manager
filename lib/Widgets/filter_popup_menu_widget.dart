import 'package:flutter/material.dart';

class FilterPopupMenuWidget extends StatelessWidget {
  FilterPopupMenuWidget({
    super.key,
    required this.filterValue,
    required this.onChanged,
  });

  final String filterValue;
  final Function(String value) onChanged;

  final Map<String, String> items = {
    "name-asc": "Filename - ASC",
    "name-desc": "Filename - DESC",
    "size": "Size",
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => items.entries
          .map((e) => PopupMenuItem<String>(value: e.key, child: Text(e.value)))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            items[filterValue].toString(),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
