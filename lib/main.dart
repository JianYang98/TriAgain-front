import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/app/router.dart';
import 'package:triagain/app/theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TriAgainApp(),
    ),
  );
}

class TriAgainApp extends StatelessWidget {
  const TriAgainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TriAgain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
