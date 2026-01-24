import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/providers/auth_provider.dart';
import 'package:rentixa/services/auth_service.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({Key? key}) : super(key: key);

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Vérification OTP',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// LOGO (mobile friendly)
              Image.asset(
                'assets/logo_ekri.png',
                height: isSmallScreen ? 90 : 140,
              ),

              const SizedBox(height: 24),

              const Text(
                'Vérifiez votre compte',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Entrez le code à 6 chiffres envoyé par SMS ou email',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 32),

              /// OTP INPUTS
              _buildOtpInputs(context),

              const SizedBox(height: 24),

              if (isLoading)
                const CircularProgressIndicator(),

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              if (successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),

              const SizedBox(height: 28),

              /// VERIFY BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Vérifier',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// RESEND
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Code non reçu ? "),
                  TextButton(
                    onPressed: () {
                      // TODO: resend OTP
                    },
                    child: const Text(
                      'Renvoyer',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// OTP INPUTS
  Widget _buildOtpInputs(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 48,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            controller: otpControllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }

  /// VERIFY OTP
  Future<void> _handleVerifyOtp() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    final code = otpControllers.map((c) => c.text).join();

    if (code.length != 6) {
      setState(() {
        errorMessage = 'Veuillez saisir un code à 6 chiffres';
        isLoading = false;
      });
      return;
    }

    try {
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);

      final response = await AuthService.verifyOtp(
        userId: authProvider.userId!,
        code: code,
      );

      if (response.statusCode == 200) {
        setState(() {
          successMessage = 'Compte vérifié avec succès';
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        setState(() {
          errorMessage = 'Code invalide ou expiré';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur réseau';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
