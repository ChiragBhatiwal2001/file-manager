import 'package:flutter/material.dart';

class PopupMenuWidget extends StatelessWidget{
  const PopupMenuWidget({super.key,required this.popupList,required this.addContent});

  final List<String> popupList;
  final void Function(String value) addContent;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value){
        addContent(value);
      },
      icon: Icon(Icons.add_circle_outline),
      itemBuilder: (context) => popupList.map((item){
        return PopupMenuItem(
            value: item,
            child: Text(item));
      }).toList()
      ,);
  }
}