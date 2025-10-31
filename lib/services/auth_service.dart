// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Instância do Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. MÉTODO DE LOGIN (Entrar)
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Tenta fazer o login com o email e senha fornecidos
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Se der certo, retorna o usuário
      return credential.user;
    } catch (e) {
      // Se der errado (ex: senha errada, usuário não existe), imprime o erro
      print("Erro ao fazer login: $e");
      return null;
    }
  }

  // 2. MÉTODO DE CADASTRO (Criar Conta)
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      // Tenta criar um novo usuário com email e senha
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Se der certo, retorna o novo usuário
      return credential.user;
    } catch (e) {
      // Se der errado (ex: email já em uso, senha fraca), imprime o erro
      print("Erro ao criar usuário: $e");
      return null;
    }
  }

  // 3. MÉTODO DE LOGOUT (Sair)
  Future<void> signOut() async {
    await _auth.signOut();
    print("Usuário deslogado.");
  }

  // 4. VERIFICADOR DE ESTADO (O "Porteiro")
  // Isso nos diz se o usuário está logado ou não, em tempo real.
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}