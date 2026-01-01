import 'package:flutter/material.dart';
import 'package:rentixa/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/providers/auth_provider.dart';

class VerifyOtpPage extends StatefulWidget {
  VerifyOtpPage({Key? key}) : super(key: key);

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 900;
                double logoSize = isWide ? 220 : 120;
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 2,
                  margin: EdgeInsets.all(32),
                  child: Container(
                    width: isWide ? 1000 : double.infinity,
                    padding: EdgeInsets.all(isWide ? 48 : 16),
                    child: isWide
                        ? Row(
                            children: [
                              // Left: Logo
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Image.asset(
                                    'assets/logo_ekri.png',
                                    width: logoSize,
                                    height: logoSize,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              // Right: OTP form
                              Expanded(
                                flex: 2,
                                child: _buildOtpForm(context),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 16),
                              Image.asset(
                                'assets/logo_ekri.png',
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 24),
                              _buildOtpForm(context),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
          // Home icon at top right
          Positioned(
            top: 24,
            right: 24,
            child: IconButton(
              icon: Icon(Icons.home, size: 32, color: Colors.black87),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/all-ads');
              },
              tooltip: 'Accueil',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 8),
        Text(
          'VÉRIFIER VOTRE COMPTE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.black87,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Veuillez saisir le code de vérification ( OTP )',
          style: TextStyle(fontSize: 15, color: Colors.grey[700]),
        ),
        SizedBox(height: 32),
        _buildOtpInputs(),
        SizedBox(height: 24),
        if (isLoading)
          Center(child: CircularProgressIndicator()),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(errorMessage!, style: TextStyle(color: Colors.red)),
          ),
        if (successMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(successMessage!, style: TextStyle(color: Colors.green)),
          ),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Vérifier le compte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Vous n'avez pas reçu de code ? "),
            TextButton(
              onPressed: () {
                // TODO: Call API to resend OTP
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                'Renvoyer',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 48,
          height: 56,
          margin: EdgeInsets.symmetric(horizontal: 6),
          child: TextField(
            controller: otpControllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (value) {
              if (value.length == 1 && index < 5) {
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

  Future<void> _handleVerifyOtp() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });
    String code = otpControllers.map((c) => c.text).join();
    if (code.length != 6 || !RegExp(r'^[0-9]{6}?$').hasMatch(code)) {
      setState(() {
        isLoading = false;
        errorMessage = 'Veuillez saisir un code de 6 chiffres.';
      });
      return;
    }
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final response = await AuthService.verifyOtp(userId: userId!, code: code);
      if (response.statusCode == 200) {
        setState(() {
          successMessage = 'Vérification réussie!';
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushReplacementNamed(context, '/all-ads');
        });
      } else {
        setState(() {
          if (response.body.contains('<html')) {
            errorMessage = 'Code de vérification incorrect ou expiré.';
          } else {
            errorMessage = 'Erreur: ' + (response.body.isNotEmpty ? response.body : response.reasonPhrase ?? '');
          }
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur réseau: ${e?.toString() ?? 'Une erreur inconnue est survenue.'}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
} 