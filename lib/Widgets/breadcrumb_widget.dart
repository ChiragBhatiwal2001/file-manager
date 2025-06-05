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
  State<StatefulWidget> createState() {
    return _BreadcrumbWidget();
  }
}

class _BreadcrumbWidget extends State<BreadcrumbWidget> {
  late List<String> pathList;
  List<String> breadcrumbList = [];

  @override
  void initState() {
    super.initState();
    pathList = widget.path.split("/");
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
    pathList = widget.path.split("/");
    breadcrumbList = [];
    for (int i = 0; i < pathList.length; i++) {
      String pathPart = pathList[i];
      if (pathPart == "") continue;
      String path = "/" + pathList.sublist(1, i + 1).join("/");
      breadcrumbList.add(path);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hadData = breadcrumbList.isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 10.0),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(breadcrumbList.length, (index) {
            String name = breadcrumbList[index].split("/").last;
            name = name == "0" ? "All Files" : name;

            return hadData
                ? Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          widget.loadContent(breadcrumbList[index]);
                        },
                        child: Text(
                          name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (index != breadcrumbList.length - 1)
                        const Text("➤", style: TextStyle(color: Colors.black)),
                    ],
                  )
                : Text("Internal Storage");
          }),
        ),
      ),
    );
  }
}
