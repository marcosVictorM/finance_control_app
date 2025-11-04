// lib/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
// 1. IMPORTAR O PACOTE DE AUTH (para ler o tipo de erro)
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // 2. NOVA FUNÇÃO (Helper para mostrar o erro)
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 3. FUNÇÃO DE LOGIN (Atualizada com o 'catch' inteligente)
  void _signIn() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; });

    try {
      // Tenta fazer o login
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(), // .trim() remove espaços
        _passwordController.text.trim(),
      );
      
    } on FirebaseAuthException catch (e) {
      // --- A MÁGICA ACONTECE AQUI ---
      // Lemos o "código" do erro que o Firebase nos deu
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-email':
        case 'invalid-credential':
          errorMessage = 'E-mail ou senha incorretos.';
          break;
        case 'wrong-password':
           errorMessage = 'E-mail ou senha incorretos.';
          break;
        case 'user-disabled':
          errorMessage = 'Este usuário foi desabilitado.';
          break;
        default:
          errorMessage = 'Ocorreu um erro. Tente novamente.';
          print('Erro de Login não tratado: ${e.code}');
      }
      _showErrorSnackbar(errorMessage);

    } catch (e) {
      // Captura qualquer outro erro
      _showErrorSnackbar('Ocorreu um erro inesperado.');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (O resto do seu 'build' continua exatamente igual) ...
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Entrar'),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _navigateToRegister,
                  child: const Text('Não tem uma conta? Cadastre-se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}