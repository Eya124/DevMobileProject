import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/providers/auth_provider.dart';
import 'package:rentixa/services/auth_service.dart';


class Header extends StatefulWidget {
  final bool isConnected;
  final bool isVerified;
  final bool isAdmin;
  final String? username;
  final Widget? leading;
  final VoidCallback? onSignIn;

  const Header({
    Key? key,
    required this.isConnected,
    required this.isVerified,
    required this.isAdmin,
    this.username,
    this.leading,
    this.onSignIn,
  }) : super(key: key);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  final TextEditingController _searchController = TextEditingController();
  bool dropdownOpen = false;

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.userId != null;
    final userInitials = authProvider.userInitials;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: widget.leading ?? const SizedBox.shrink(),
      title: Row(
        children: [
          // LOGO
          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, '/all-ads');
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo_ekri.png',
                  height: 32,
                  width: 32,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const Spacer(),

          // SEARCH (TEMP REMOVED)
          if (!isSmallScreen) ...[
            Container(
              width: 300,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Recherche désactivée',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                readOnly: true,
                onTap: () {
                  // SearchModal.show(context); // TEMP REMOVED
                },
              ),
            ),
            const SizedBox(width: 16),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black87),
              onPressed: () {
                // SearchModal.show(context); // TEMP REMOVED
              },
              tooltip: 'Recherche (désactivée)',
            ),
          ],

          // AUTH BUTTONS
          if (!isAuthenticated) ...[
            IconButton(
              icon: const Icon(Icons.login, color: Colors.black87),
              onPressed: widget.onSignIn,
              tooltip: 'Se connecter',
            ),
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.black87),
              onPressed: () {
                Navigator.pushNamed(context, '/sign-up');
              },
              tooltip: "S'inscrire",
            ),
          ] else ...[
            GestureDetector(
              onTap: () {
                _showUserMenu(context);
              },
              child: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(
                  userInitials,
                  style: const TextStyle(
                    color: Colors.white,
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

  // CONSERVÉ (non lié à Search / Welcome)
  Widget _buildMobileMenu(
    bool isAuthenticated,
    String userInitials,
    AuthProvider authProvider,
  ) {
    if (!isAuthenticated) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.login, color: Colors.black87),
            onPressed: widget.onSignIn,
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.black87),
            onPressed: () {
              Navigator.pushNamed(context, '/sign-up');
            },
          ),
        ],
      );
    } else {
      return IconButton(
        icon: CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Text(
            userInitials,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
        onPressed: () => _showUserMenu(context),
      );
    }
  }

  // CONSERVÉ
  Widget _buildRightSection(
    bool isAuthenticated,
    String userInitials,
    AuthProvider authProvider,
  ) {
    if (!isAuthenticated) {
      return Row(
        children: [
          ElevatedButton(
            onPressed: widget.onSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
            ),
            child: const Text('Se connecter'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/sign-up');
            },
            child: const Text("S'inscrire"),
          ),
        ],
      );
    } else {
      return PopupMenuButton<String>(
        onSelected: (value) async {
          switch (value) {
            case 'profile':
              Navigator.pushNamed(context, '/profile');
              break;
            case 'myAds':
              Navigator.pushNamed(context, '/my-ads');
              break;
            case 'logout':
              await AuthService.logout();
              authProvider.clear();
              Navigator.pushReplacementNamed(context, '/sign-in');
              break;
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'profile', child: Text('Profile')),
          PopupMenuItem(value: 'myAds', child: Text('Mes annonces')),
          PopupMenuItem(value: 'logout', child: Text('Déconnexion')),
        ],
        child: CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Text(
            userInitials,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      );
    }
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
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('Mes annonces'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/my-ads');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Déconnexion'),
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
