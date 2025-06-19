import 'package:file_manager/Utils/constant.dart';
import 'package:flutter/material.dart';

class BreadcrumbWidget extends StatefulWidget {
  const BreadcrumbWidget({
    super.key,
    required this.path,
    required this.loadContent,
  });

  final String path;
  final void Function(String path) loadContent;

  @override
  State<StatefulWidget> createState() => _BreadcrumbWidget();
}

class _BreadcrumbWidget extends State<BreadcrumbWidget> {
  List<String> breadcrumbList = [];
  List<String> breadcrumbNames = [];

  @override
  void initState() {
    super.initState();
    _updateBreadcrumbs();
  }

  @override
  void didUpdateWidget(covariant BreadcrumbWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _updateBreadcrumbs();
    }
  }

  void _updateBreadcrumbs() {
    breadcrumbList = [];
    breadcrumbNames = [];

    String path = widget.path;
    String root = Constant.internalPath;

    // Normalize both root and path
    path = path.replaceAll(RegExp(r'/+'), '/').trim();
    root = root.replaceAll(RegExp(r'/+'), '/').trim();

    if (!root.endsWith('/')) root = '$root/';
    if (!path.endsWith('/')) path = '$path/';

    if (path.startsWith(root)) {
      breadcrumbList.add(Constant.internalPath);
      breadcrumbNames.add('All Files');

      String subPath = path.substring(root.length);
      List<String> parts = subPath.split('/')..removeWhere((e) => e.isEmpty);
      String current = Constant.internalPath;

      for (var part in parts) {
        current = '$current/$part';
        breadcrumbList.add(current.replaceAll(RegExp(r'/+'), '/'));
        breadcrumbNames.add(part);
      }
    } else {
      // Fallback for non-internal paths
      List<String> parts = path.split('/')..removeWhere((e) => e.isEmpty);
      String current = '';
      for (var part in parts) {
        current = '$current/$part';
        breadcrumbList.add(current.replaceAll(RegExp(r'/+'), '/'));
        breadcrumbNames.add(part);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 10.0),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(breadcrumbList.length, (index) {
            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    widget.loadContent(breadcrumbList[index]);
                  },
                  child: Text(
                    breadcrumbNames[index],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (index != breadcrumbList.length - 1)
                  Text(
                    "➤",
                    style: TextStyle(
                      letterSpacing: 12,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
