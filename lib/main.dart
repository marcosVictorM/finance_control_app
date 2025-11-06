// lib/main.dart
import 'package:flutter/material.dart';

// 1. Importe o 'firebase_core'
import 'package:firebase_core/firebase_core.dart';

// 2. Importe o arquivo que o FlutterFire criou
import 'firebase_options.dart'; 

import 'package:app_financas/auth/auth_gate.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() async {
  // 3. Garante que o Flutter esteja pronto antes de chamar o Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  
  // 4. Inicializa o Firebase usando as opções do arquivo gerado
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 5. Roda o seu aplicativo
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Finanças',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Você pode mudar a cor
      ),
      // 6. Vamos começar com uma tela temporária
      home: const AuthGate(),
    );
  }
}