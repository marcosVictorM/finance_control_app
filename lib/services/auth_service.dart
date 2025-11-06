// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. MÉTODO DE LOGIN (Entrar)
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      // --- MUDANÇA AQUI ---
      // Em vez de retornar null, nós re-lançamos o erro
      // para que a tela (UI) possa lê-lo.
      print("Erro ao fazer login (AuthService): $e");
      rethrow; 
    }
  }

  // 2. MÉTODO DE CADASTRO (Criar Conta)
  Future<User?> createUserWithEmailAndPassword(String email, String password, String name) async {
  try {
    // Tenta criar o utilizador no Auth
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? newUser = credential.user;

    // 4. ADICIONE ESTE BLOCO:
    // Se o utilizador foi criado, salva o nome/email no Firestore
    if (newUser != null) {
      await _firestore.collection('users').doc(newUser.uid).set({
        'name': name,
        'email': email,
      });
    }
    // FIM DO BLOCO ADICIONADO

    return newUser;
  } catch (e) {
    print("Erro ao criar usuário (AuthService): $e");
    rethrow;
  }
}

  // 3. MÉTODO DE LOGOUT (Sair)
  Future<void> signOut() async {
    await _auth.signOut();
    print("Usuário deslogado.");
  }

  // 4. VERIFICADOR DE ESTADO (O "Porteiro")
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}