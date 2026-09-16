import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'providers/watchlist_provider.dart';

void main() {
  runApp(const Wheels2DriveApp());
}

class Wheels2DriveApp extends StatelessWidget {
  const Wheels2DriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        Provider(create: (_) => ()),
      ],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: MaterialApp.router(
            title: 'Wheels2Drive',
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}
