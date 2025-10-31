// lib/auth/auth_gate.dart
import 'package:app_financas/screens/home_screen.dart'; // Importa a tela principal
import 'package:app_financas/auth/login_screen.dart';   // Importa a tela de login
import 'package:app_financas/services/auth_service.dart'; // Importa o serviço
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 1. Onde ele vai "ouvir": nosso stream do AuthService
      stream: AuthService().authStateChanges,
      
      // 2. O que ele vai construir com base no que ouviu
      builder: (context, snapshot) {
        
        // 3. Se estiver "esperando" (verificando o status)
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostra uma tela de loading simples
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 4. Se o "snapshot" (a foto do momento) TIVER dados (usuário)
        if (snapshot.hasData) {
          // Usuário está LOGADO -> Mostra a HomeScreen
          return HomeScreen();
        }

        // 5. Se o "snapshot" NÃO tiver dados
        // Usuário está DESLOGADO -> Mostra a LoginScreen
        return const LoginScreen();
      },
    );
  }
}