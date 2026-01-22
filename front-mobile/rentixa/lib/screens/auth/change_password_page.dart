import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rentixa/services/auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool loading = false;
  bool showOldPassword = false;
  bool showNewPassword = false;

  String? errorMessage;
  String? successMessage;

  static const Color primaryOrange = Colors.orange;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Changer le mot de passe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: isMobile ? double.infinity : 420,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  /// ICON
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: primaryOrange.withOpacity(0.15),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 34,
                      color: primaryOrange,
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// TITLE
                  const Text(
                    'Sécurité du compte',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Mettez à jour votre mot de passe',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 28),

                  /// ERROR / SUCCESS
                  if (errorMessage != null)
                    _messageBox(errorMessage!, Colors.red),

                  if (successMessage != null)
                    _messageBox(successMessage!, Colors.green),

                  /// OLD PASSWORD
                  _passwordField(
                    controller: oldPasswordController,
                    label: 'Ancien mot de passe',
                    icon: Icons.lock_outline,
                    isVisible: showOldPassword,
                    onToggle: () =>
                        setState(() => showOldPassword = !showOldPassword),
                  ),

                  const SizedBox(height: 18),

                  /// NEW PASSWORD
                  _passwordField(
                    controller: newPasswordController,
                    label: 'Nouveau mot de passe',
                    icon: Icons.lock_reset,
                    isVisible: showNewPassword,
                    onToggle: () =>
                        setState(() => showNewPassword = !showNewPassword),
                  ),

                  const SizedBox(height: 30),

                  /// SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Mettre à jour',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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

  /// PASSWORD FIELD
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: (v) =>
          v != null && v.length >= 6 ? null : 'Minimum 6 caractères',
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryOrange),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onToggle,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: primaryOrange, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  /// MESSAGE BOX
  Widget _messageBox(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            color == Colors.green
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  /// SUBMIT LOGIC
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      errorMessage = null;
      successMessage = null;
    });

    final response = await AuthService.changePassword(
      oldPassword: oldPasswordController.text,
      newPassword: newPasswordController.text,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        successMessage = data['message'];
        oldPasswordController.clear();
        newPasswordController.clear();
      });
    } else {
      setState(() {
        errorMessage = data['message'] ?? 'Erreur';
      });
    }

    setState(() => loading = false);
  }
}
