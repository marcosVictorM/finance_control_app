// lib/auth/register_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Importamos nosso serviço

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Instância do serviço
  final AuthService _authService = AuthService();

  // Estado de loading
  bool _isLoading = false;

  // Função para lidar com o cadastro
  void _signUp() async {
    if (_isLoading) return;

    // 1. Validar se as senhas são iguais
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("As senhas não conferem!"),
          backgroundColor: Colors.red,
        ),
      );
      return; // Para a execução
    }

    // 2. Iniciar o Loading
    setState(() { _isLoading = true; });

    try {
      // 3. Tentar criar o usuário
      await _authService.createUserWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      // 4. Se der certo, mostra feedback e fecha a tela
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Conta criada com sucesso! Faça o login."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Volta para a tela de Login
      }
    } catch (e) {
      // 5. Se der erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Falha ao criar conta: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 6. Parar o loading
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
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
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de Confirmar Senha
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botão de Cadastrar
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Cadastrar'),
                      ),
                
                const SizedBox(height: 16),
                
                // Botão para voltar ao Login
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Apenas fecha esta tela
                  },
                  child: const Text('Já tem uma conta? Faça o login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}