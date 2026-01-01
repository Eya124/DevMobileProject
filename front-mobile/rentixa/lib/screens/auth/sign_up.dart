import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rentixa/widgets/header.dart';
import 'package:rentixa/services/auth_service.dart';
import 'package:rentixa/models/user.dart';
import 'package:rentixa/providers/auth_provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

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
              onSignIn: () {
                Navigator.pushReplacementNamed(context, '/sign-in');
              },
            );
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 430,
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
                  Image.asset('assets/logo_ekri.png', width: 85),
                  const SizedBox(height: 20),

                  const Text(
                    "Créer un compte",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(height: 6),
                  Text(
                    "Rejoignez-nous en quelques secondes",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 26),

                  if (errorMessage != null)
                    _messageBox(errorMessage!, Colors.red),

                  /// PRENOM & NOM
                  Row(
                    children: [
                      Expanded(
                        child: _inputField(
                          label: 'Prénom',
                          controller: firstNameController,
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _inputField(
                          label: 'Nom',
                          controller: lastNameController,
                          icon: Icons.badge_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _inputField(
                    label: 'E-mail',
                    controller: emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v != null && v.contains('@') ? null : 'Email invalide',
                  ),

                  const SizedBox(height: 18),

                  _passwordField(
                    label: 'Mot de passe',
                    controller: passwordController,
                    obscure: obscurePassword,
                    toggle: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),

                  const SizedBox(height: 18),

                  _passwordField(
                    label: 'Confirmer le mot de passe',
                    controller: confirmPasswordController,
                    obscure: obscureConfirmPassword,
                    toggle: () => setState(
                        () => obscureConfirmPassword = !obscureConfirmPassword),
                    validator: (v) => v != passwordController.text
                        ? 'Les mots de passe ne correspondent pas'
                        : null,
                  ),

                  const SizedBox(height: 32),

                  /// BUTTON ORANGE PREMIUM
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _handleSignUp();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        elevation: 4,
                        backgroundColor: primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Créer mon compte',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Déjà un compte ? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/sign-in');
                        },
                        child: const Text(
                          'Se connecter',
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

  /// INPUT FIELD ORANGE
  Widget _inputField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
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
          validator: validator ??
              (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: primaryOrange) : null,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryOrange, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  /// PASSWORD FIELD
  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return _inputField(
      label: label,
      controller: controller,
      validator: validator,
      icon: Icons.lock_outline,
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
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  /// SIGN UP LOGIC (INCHANGÉE)
  Future<void> _handleSignUp() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = User(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
      );

      final response = await AuthService.signUp(
        user: user,
        password: passwordController.text,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final currentUser = data['CurrentUser'] ?? {};

        final userId = currentUser['id'];
        final firstName = currentUser['first_name'] ?? '';
        final lastName = currentUser['last_name'] ?? '';
        final email = currentUser['email'] ?? '';

        if (userId != null) {
          Provider.of<AuthProvider>(context, listen: false)
              .setUserData(userId.toString(), firstName, lastName, email);
          Navigator.pushReplacementNamed(context, '/verify-otp');
        }
      } else {
        errorMessage = 'Inscription échouée';
      }
    } catch (e) {
      errorMessage = 'Erreur réseau';
    } finally {
      setState(() => isLoading = false);
    }
  }
}
