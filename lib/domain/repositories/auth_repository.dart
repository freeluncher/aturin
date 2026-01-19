import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> signOut();
}
