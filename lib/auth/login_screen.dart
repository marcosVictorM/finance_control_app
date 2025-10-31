// lib/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Importamos nosso serviço
import 'register_screen.dart'; // Importamos a tela de cadastro (vamos criar)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para os campos de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Instância do nosso serviço de autenticação
  final AuthService _authService = AuthService();

  // Estado de loading
  bool _isLoading = false;

  // Função para lidar com o login
  void _signIn() async {
    // Se não estiver carregando
    if (_isLoading) return;

    // Atualiza o estado para mostrar o "loading"
    setState(() {
      _isLoading = true;
    });

    try {
      // Tenta fazer o login usando nosso serviço
      await _authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
      
      // Se o login for bem-sucedido, o 'AuthGate' vai
      // automaticamente nos levar para a 'HomeScreen'.
      // Não precisamos fazer nada aqui.

    } catch (e) {
      // Se der erro, mostra um feedback para o usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Falha no login: Verifique seu e-mail e senha."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Independente de sucesso ou falha, para de carregar
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Função para navegar para a tela de cadastro
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView( // Evita que o teclado quebre a tela
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Campo de E-mail
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo de Senha
                TextField(
                  controller: _passwordController,
                  obscureText: true, // Esconde a senha
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botão de Entrar
                _isLoading
                    ? const CircularProgressIndicator() // Mostra o loading
                    : ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Entrar'),
                      ),
                
                const SizedBox(height: 16),
                
                // Botão para ir para a tela de Cadastro
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