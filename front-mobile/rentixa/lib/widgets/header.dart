import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/providers/auth_provider.dart';
import 'package:rentixa/services/auth_service.dart';

// Ensure this path matches your project structure
import 'package:rentixa/screens/ads/create_ad_modal.dart';

class Header extends StatefulWidget {
  final bool isConnected;
  final bool isVerified;
  final bool isAdmin;
  final String? username;
  final Widget? leading;
  final VoidCallback? onSignIn;
  final VoidCallback? onAddAd;

  const Header({
    Key? key,
    required this.isConnected,
    required this.isVerified,
    required this.isAdmin,
    this.username,
    this.leading,
    this.onSignIn,
    this.onAddAd,
  }) : super(key: key);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final authProvider = Provider.of<AuthProvider>(context);

    final isAuthenticated =
        authProvider.userId != null && authProvider.userId != "0";
    final userInitials = authProvider.userInitials;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: widget.leading,
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo_ekri.png',
                  height: 32,
                  width: 32,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.home, color: Colors.orange),
                ),
                if (!isSmallScreen) ...[
                  const SizedBox(width: 8),
                  const Text(
                    "Rentixa",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),

          if (!isAuthenticated) ...[
            IconButton(
              icon: const Icon(Icons.login, color: Colors.black87),
              onPressed:
                  widget.onSignIn ??
                  () => Navigator.pushNamed(context, '/sign-in'),
              tooltip: 'Se connecter',
            ),
            if (!isSmallScreen)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/sign-up'),
                child: const Text(
                  "S'inscrire",
                  style: TextStyle(color: Colors.black87),
                ),
              ),
          ] else ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showUserMenu(context),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.orange,
                child: Text(
                  userInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Mon Profil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Mes annonces'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/my-ads');
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Mes reclamations'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/complaints');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Déconnexion',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService.logout();
                  authProvider.clear();
                  Navigator.pushReplacementNamed(context, '/sign-in');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
