import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/screens/complaint/complaint_list.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/header.dart';
// Assurez-vous que le chemin d'importation vers votre page est correct
// import 'complaint_list_page.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({Key? key}) : super(key: key);

  // Données statiques pour les annonces
  final List<Map<String, String>> staticAds = const [
    {
      'title': 'Appartement F3 - Alger',
      'price': '200 TND/mois',
      'image': 'assets/house1.jpg',
      'location': 'Manouba, Tunis',
    },
    {
      'title': 'Studio Meublé',
      'price': '300 TND/mois',
      'image': 'assets/house2.webp',
      'location': 'Centre Ville, Tunis',
    },
    {
      'title': 'Villa avec Piscine',
      'price': '120 TND/mois',
      'image': 'assets/house3.jpg',
      'location': 'Beja, Tunisie',
    },
    {
      'title': 'Local Commercial',
      'price': '6000 TND/mois',
      'image': 'assets/house4.webp',
      'location': 'sfax, Tunisie',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      // --- AJOUT DU MENU LATÉRAL (DRAWER) ---
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2D2D2D)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(
                  authProvider.userInitials,
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              accountName: Text("${authProvider.firstName}"),
              accountEmail: const Text("Utilisateur vérifié"),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.orange),
              title: const Text("Accueil"),
              onTap: () =>
                  Navigator.pop(context), // Changé : onTap au lieu de onPressed
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.orange),
              title: const Text("Mes Annonces"),
              onTap: () {
                // Changé : onTap au lieu de onPressed
                Navigator.pop(context);
                // Naviguer vers Mes Annonces
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.feedback_outlined,
                color: Colors.orange,
              ),
              title: const Text("Mes Réclamations"),
              onTap: () {
                // Changé : onTap au lieu de onPressed
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComplaintListPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.orange),
              title: const Text("Mon Profil"),
              onTap: () {
                // Changé : onTap au lieu de onPressed
                Navigator.pop(context);
                // Naviguer vers Profil
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Déconnexion"),
              onTap: () {
                // Changé : onTap au lieu de onPressed
                // Logique de déconnexion
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Header(
          isConnected: true,
          isVerified: true,
          isAdmin: false,
          username: authProvider.userInitials,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bienvenue, ${authProvider.firstName} 👋",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Découvrez les dernières annonces de location",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 20),

            // --- BOUTON D'ACCÈS RAPIDE AUX RÉCLAMATIONS ---
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComplaintListPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.campaign, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Suivre mes réclamations",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Grille des annonces
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.8,
              ),
              itemCount: staticAds.length,
              itemBuilder: (context, index) {
                final ad = staticAds[index];
                return _buildAdCard(ad);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(Map<String, String> ad) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image, size: 50, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ad['location']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ad['price']!,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
