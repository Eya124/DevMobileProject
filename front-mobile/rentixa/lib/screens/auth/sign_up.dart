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
  void initState() {
    super.initState();
    passwordController.addListener(() => setState(() {}));
  }

  // ================= VALIDATIONS =================

  bool isValidEmail(String email) {
    final regex =
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe obligatoire';
    }
    if (value.length < 6) {
      return 'Minimum 6 caractères';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Ajoutez une majuscule';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Ajoutez une minuscule';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Ajoutez un chiffre';
    }
    if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
      return 'Ajoutez un caractère spécial';
    }
    return null;
  }

  int passwordStrength(String password) {
    int score = 0;
    if (password.length >= 6) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) score++;
    return score;
  }

  Color strengthColor(int score) {
    if (score <= 2) return Colors.red;
    if (score == 3) return Colors.orange;
    return Colors.green;
  }

  String strengthLabel(int score) {
    if (score <= 2) return 'Faible';
    if (score == 3) return 'Moyen';
    return 'Fort';
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final score = passwordStrength(passwordController.text);
    final isPasswordStrong = score >= 4;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Header(
              isConnected: false,
              isVerified: false,
              isAdmin: false,
              username: '',
              onSignIn: () =>
                  Navigator.pushReplacementNamed(context, '/sign-in'),
            );
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: isMobile ? double.infinity : 430,
            margin: const EdgeInsets.all(16),
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
                        fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Rejoignez-nous en quelques secondes",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 26),

                  if (errorMessage != null)
                    _messageBox(errorMessage!, Colors.red),

                  isMobile
                      ? Column(
                          children: [
                            _inputField(
                                label: 'Prénom',
                                controller: firstNameController,
                                icon: Icons.person_outline),
                            const SizedBox(height: 18),
                            _inputField(
                                label: 'Nom',
                                controller: lastNameController,
                                icon: Icons.badge_outlined),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                                child: _inputField(
                                    label: 'Prénom',
                                    controller: firstNameController,
                                    icon: Icons.person_outline)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: _inputField(
                                    label: 'Nom',
                                    controller: lastNameController,
                                    icon: Icons.badge_outlined)),
                          ],
                        ),

                  const SizedBox(height: 18),

                  _inputField(
                    label: 'E-mail',
                    controller: emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v != null && isValidEmail(v)
                            ? null
                            : 'Email invalide',
                  ),

                  const SizedBox(height: 18),

                  _passwordField(
                    label: 'Mot de passe',
                    controller: passwordController,
                    obscure: obscurePassword,
                    toggle: () =>
                        setState(() => obscurePassword = !obscurePassword),
                    validator: validatePassword,
                  ),

                  const SizedBox(height: 8),

                  LinearProgressIndicator(
                    value: score / 5,
                    color: strengthColor(score),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade300,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Sécurité : ${strengthLabel(score)}',
                    style: TextStyle(
                        color: strengthColor(score),
                        fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  Column(
                    children: [
                      _checkItem('6 caractères minimum',
                          passwordController.text.length >= 6),
                      _checkItem('1 majuscule',
                          RegExp(r'[A-Z]').hasMatch(passwordController.text)),
                      _checkItem('1 minuscule',
                          RegExp(r'[a-z]').hasMatch(passwordController.text)),
                      _checkItem('1 chiffre',
                          RegExp(r'[0-9]').hasMatch(passwordController.text)),
                      _checkItem(
                          '1 caractère spécial',
                          RegExp(r'[!@#\$&*~]')
                              .hasMatch(passwordController.text)),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _passwordField(
                    label: 'Confirmer le mot de passe',
                    controller: confirmPasswordController,
                    obscure: obscureConfirmPassword,
                    toggle: () => setState(() =>
                        obscureConfirmPassword = !obscureConfirmPassword),
                    validator: (v) => v != passwordController.text
                        ? 'Les mots de passe ne correspondent pas'
                        : null,
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading || !isPasswordStrong
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _handleSignUp();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              'Créer mon compte',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= COMPONENTS =================

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
            prefixIcon:
                icon != null ? Icon(icon, color: primaryOrange) : null,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

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
      icon: Icons.lock_outline,
      validator: validator,
    );
  }

  Widget _checkItem(String text, bool ok) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel,
            color: ok ? Colors.green : Colors.grey, size: 18),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

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
        Provider.of<AuthProvider>(context, listen: false).setUserData(
          currentUser['id'].toString(),
          currentUser['first_name'] ?? '',
          currentUser['last_name'] ?? '',
          currentUser['email'] ?? '',
        );
        Navigator.pushReplacementNamed(context, '/verify-otp');
      } else {
        errorMessage = 'Inscription échouée';
      }
    } catch (_) {
      errorMessage = 'Erreur réseau';
    } finally {
      setState(() => isLoading = false);
    }
  }
}
