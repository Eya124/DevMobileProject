import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/admin/UserHomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/header.dart';
import 'package:rentixa/services/auth_service.dart';
import 'package:rentixa/providers/auth_provider.dart';

// ✅ AJOUTS POUR LA REDIRECTION
import '../../admin/admin_panel.dart';
import '../auth/profile.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  String? errorMessage;

  static const Color primaryOrange = Colors.orange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Header(
              isConnected: authProvider.userId != null,
              isVerified: authProvider.userId != null,
              isAdmin: false,
              username: authProvider.userInitials,
            );
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryOrange.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  /// LOGO
                  Image.asset('assets/logo_ekri.png', width: 85),
                  const SizedBox(height: 18),

                  /// TITLE
                  const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),
                  Text(
                    'Accédez à votre espace personnel',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 26),

                  /// ERROR MESSAGE
                  if (errorMessage != null)
                    _messageBox(errorMessage!, Colors.red),

                  /// EMAIL
                  _inputField(
                    label: 'E-mail',
                    controller: emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v != null && v.contains('@') ? null : 'Email invalide',
                  ),

                  const SizedBox(height: 18),

                  /// PASSWORD
                  _passwordField(),

                  /// FORGOT PASSWORD
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _handleSignIn();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// SIGN UP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Vous n'avez pas de compte ? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/sign-up');
                        },
                        child: const Text(
                          'Créer votre compte',
                          style: TextStyle(
                            color: primaryOrange,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// INPUT FIELD
  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator:
              validator ??
              (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryOrange),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryOrange, width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  /// PASSWORD FIELD
  Widget _passwordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mot de passe',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          validator: (v) =>
              v != null && v.length >= 6 ? null : 'Mot de passe trop court',
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: primaryOrange),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryOrange, width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  /// MESSAGE BOX
  Widget _messageBox(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  /// ✅ SIGN IN LOGIC AVEC REDIRECTION ADMIN / USER
  Future<void> _handleSignIn() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await AuthService.signIn(
        email: emailController.text,
        password: passwordController.text,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        print('✅ TOKEN SAUVEGARDÉ => $token');

        final currentUser = data['CurrentUser'] ?? {};

        final userId = currentUser['id'];
        final firstName =
            currentUser['first_name'] ?? currentUser['username'] ?? '';
        final lastName = currentUser['last_name'] ?? '';
        final email = currentUser['email'] ?? '';
        final bool isAdmin = currentUser['is_admin'] == true;

        if (userId != null) {
          Provider.of<AuthProvider>(
            context,
            listen: false,
          ).setUserData(userId.toString(), firstName, lastName, email);

          // --- C'EST ICI QUE LA MODIFICATION SE PASSE ---
          if (isAdmin) {
            // 👉 REDIRECTION ADMIN
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminPanel()),
            );
          } else {
            // 👉 REDIRECTION USER NORMAL (VERS LA PAGE DES ANNONCES)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const UserHomePage(),
              ), // Remplace ProfilePage()
            );
          }
          // ----------------------------------------------
        } else {
          errorMessage = 'Impossible de récupérer l’utilisateur';
        }
      } else {
        errorMessage = 'Email ou mot de passe incorrect';
      }
    } catch (e) {
      errorMessage = 'Erreur réseau';
    } finally {
      setState(() => isLoading = false);
    }
  }
}
