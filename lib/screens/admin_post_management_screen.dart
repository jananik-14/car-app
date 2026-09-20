import 'package:flutter/material.dart';
import '../widgets/admin_navigation_drawer.dart';

class AdminPostManagementScreen extends StatelessWidget {
  const AdminPostManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF001128)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Post Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF001128)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF001128),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      drawer: const AdminNavigationDrawer(),
      body: const Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF001128),
          ),
        ),
      ),
    );
  }
}
