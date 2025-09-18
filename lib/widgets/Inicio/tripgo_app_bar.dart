import 'package:flutter/material.dart';

class TripGoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TripGoAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE9D8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.menu, color: Color(0xFFFF6A00)),
        ),
      ),
      centerTitle: true,
      title: const Text(
        'TripGo',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.notifications_none, color: Colors.black87),
        ),
      ],
    );
  }
}
