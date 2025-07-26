import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routing/app_router.dart';

class ComnecterApp extends StatelessWidget {
  const ComnecterApp({super.key});

  @override
  Widget build(BuildContext context){
      final _router = createRouter();

      return MaterialApp.router(
        title: 'Comnecter',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          fontFamily: 'SF Pro',
        ),
        routerConfig: _router,
      );

  }
  
  }