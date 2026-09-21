import 'package:flutter/material.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const AdminAppBar({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF001128);
    const orangeColor = Color(0xFFfb7800);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: navyColor),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      iconTheme: const IconThemeData(color: navyColor),
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Wheels2Drive',
            style: TextStyle(
              color: navyColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'ADMIN PORTAL',
            style: TextStyle(
              color: orangeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: actions ?? [
        IconButton(
          icon: const Icon(Icons.search, color: navyColor),
          onPressed: () {},
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: navyColor,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'AD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
