import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/providers/auth_provider.dart';
import '../../widgets/header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  static const Color primaryOrange = Colors.orange;
  static const Color backgroundColor = Color(0xFFF9F6F2);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final String firstName = authProvider.firstName ?? '';
    final String lastName = authProvider.lastName ?? '';
    final String email = authProvider.email ?? '';
    final String initials = authProvider.userInitials ?? 'U';

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
                /// AVATAR avec ring
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryOrange.withOpacity(0.8),
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: primaryOrange.withOpacity(0.12),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: primaryOrange,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// NOM
                Text(
                  ('$firstName $lastName').trim().isEmpty
                      ? 'Utilisateur'
                      : '$firstName $lastName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 6),

                /// EMAIL
                Text(
                  email.isEmpty ? 'email@exemple.com' : email,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 14),

                /// BADGE STATUS
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Connecté',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                /// SECTION INFOS
                _sectionTitle('Informations'),
                _infoTile(
                  icon: Icons.person_outline,
                  label: 'Nom complet',
                  value: ('$firstName $lastName').trim().isEmpty
                      ? '—'
                      : '$firstName $lastName',
                ),
                _infoTile(
                  icon: Icons.email_outlined,
                  label: 'Adresse email',
                  value: email.isEmpty ? '—' : email,
                ),

                const SizedBox(height: 34),

                /// SECTION ACTIONS
                _sectionTitle('Actions'),
                _actionButton(
                  icon: Icons.edit_outlined,
                  label: 'Modifier le profil',
                  onTap: () {},
                ),
                _actionButton(
                  icon: Icons.lock_outline,
                  label: 'Changer le mot de passe',
                  onTap: () {},
                ),
                _actionButton(
                  icon: Icons.logout,
                  label: 'Se déconnecter',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/profile');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// SECTION TITLE
  Widget _sectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// INFO TILE
  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryOrange),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ACTION BUTTON
  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color color = isDestructive ? Colors.red : primaryOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: color.withOpacity(0.08),
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
                  fontSize: 15,
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
