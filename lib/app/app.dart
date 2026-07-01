import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class MilkSafeApp extends StatelessWidget {
  const MilkSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MilkSafe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
