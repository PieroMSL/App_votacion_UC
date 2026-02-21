import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // LO QUE FALTABA: Crear una única instancia y pasarle el Client ID de Web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // ATENCIÓN: Debes poner tu Client ID real aquí para que funcione en Chrome
    clientId:
        '17851172844-a5kbc39qlksidmanda4r7f2gd8giqja9.apps.googleusercontent.com',
  );

  // Stream para cambios de estado (Login/Logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Obtener ID Token para Backend
  Future<String?> getIdToken() async {
    if (currentUser == null) return null;
    return await currentUser!.getIdToken();
  }

  // Login con Email/Password
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // SignUp con Email/Password
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Google Sign-In con restricción de dominio institucional
  Future<UserCredential> signInWithGoogle() async {
    try {
      print("Iniciando Google Sign-In...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print("Google User: ${googleUser?.email}");

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      // ── VALIDACIÓN DE DOMINIO INSTITUCIONAL ──────────────────────
      // Solo se permite el correo de la Universidad Continental
      if (!googleUser.email.endsWith('@continental.edu.pe')) {
        // Cancelar el proceso de Google Sign-In inmediatamente
        await _googleSignIn.signOut();
        throw Exception(
          'Solo se permiten correos de la Universidad Continental (@continental.edu.pe). '
          'Ingresaste: ${googleUser.email}',
        );
      }
      // ─────────────────────────────────────────────────────────────

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // SignOut
  Future<void> signOut() async {
    // Usamos la misma instancia para cerrar sesión en Google
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
