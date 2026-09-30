import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'providers/watchlist_provider.dart';
import 'services/subscription_store.dart';

import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().init();
  runApp(const Wheels2DriveApp());
}

class Wheels2DriveApp extends StatefulWidget {
  const Wheels2DriveApp({super.key});

  @override
  State<Wheels2DriveApp> createState() => _Wheels2DriveAppState();
}

class _Wheels2DriveAppState extends State<Wheels2DriveApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SubscriptionStore().reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        Provider(create: (_) => ()),
      ],
      child: MaterialApp.router(
        title: 'Wheels2Drive',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
