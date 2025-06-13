import 'package:flutter/material.dart';

class ContainerHomeScreen extends StatelessWidget{
  const ContainerHomeScreen({super.key,required this.icon,required this.title,required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(icon),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios_sharp, size: 18),
          ],
        ),
      ),
    );
  }
}