import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/providers/auth_provider.dart';
import 'package:rentixa/services/avatar_service.dart';
import '../../widgets/header.dart';
import 'change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? avatarPath;

  static const Color primaryOrange = Colors.orange;
  static const Color backgroundColor = Color(0xFFF9F6F2);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.email ?? '';
    final path = await AvatarService.getAvatar(email);

    setState(() {
      avatarPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final String firstName = authProvider.firstName ?? '';
    final String lastName = authProvider.lastName ?? '';
    final String email = authProvider.email ?? '';
    final String initials = authProvider.userInitials;

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Header(
          isConnected: authProvider.userId != null,
          isVerified: authProvider.userId != null,
          isAdmin: false,
          username: initials,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Container(
            width: isMobile ? double.infinity : 460,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                /// 👤 AVATAR
                GestureDetector(
                  onTap: () async {
                    final newPath =
                        await AvatarService.pickAndSaveAvatar(email);
                    if (newPath != null) {
                      setState(() {
                        avatarPath = newPath;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryOrange.withOpacity(0.8),
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: primaryOrange.withOpacity(0.12),
                      backgroundImage: avatarPath != null
                          ? FileImage(File(avatarPath!))
                          : null,
                      child: avatarPath == null
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: primaryOrange,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                const Text(
                  'Appuyer pour modifier la photo',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 18),

                /// NOM
                Text(
                  ('$firstName $lastName').trim().isEmpty
                      ? 'Utilisateur'
                      : '$firstName $lastName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                /// EMAIL
                Text(
                  email,
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 14),

                /// BADGE
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Connecté',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                _actionButton(
                  icon: Icons.lock_outline,
                  label: 'Changer le mot de passe',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordPage(),
                      ),
                    );
                  },
                ),

                _actionButton(
                  icon: Icons.delete_outline,
                  label: 'Supprimer la photo',
                  isDestructive: true,
                  onTap: () async {
                    await AvatarService.removeAvatar(email);
                    setState(() {
                      avatarPath = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : primaryOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
