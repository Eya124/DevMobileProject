import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentixa/screens/complaint/complaint_list.dart';

import '../models/user.dart';
import 'package:rentixa/providers/auth_provider.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  List<User> users = [];
  bool loading = true;

  /// 🔥 MAP ADMIN
  final Map<int, bool> adminMap = {};

  final String baseUrl = 'http://10.0.2.2:8111';

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  // 🔐 TOKEN
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 📥 LOAD USERS
  Future<void> loadUsers() async {
    setState(() => loading = true);

    final token = await getToken();
    if (token == null) {
      setState(() => loading = false);
      return;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawUsers = data['users'] as List;

      users = rawUsers.map((e) => User.fromJson(e)).toList();

      adminMap.clear();
      for (final u in rawUsers) {
        adminMap[u['id']] = u['is_admin'] == true;
      }
    }

    setState(() => loading = false);
  }

  // 🗑️ DELETE USER
  Future<void> deleteUser(int id) async {
    final token = await getToken();
    if (token == null) return;

    await http.delete(
      Uri.parse('$baseUrl/users/delete/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    loadUsers();
  }

  // ➕ CREATE USER
  Future<void> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required bool isAdmin,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/authentification/admin-create-user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'is_admin': isAdmin,
      }),
    );

    loadUsers();
  }

  // 🪟 CREATE USER DIALOG
  void showCreateUserDialog() {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isAdmin = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Ajouter un utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                ),
                TextField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Administrateur'),
                  value: isAdmin,
                  onChanged: (v) => setStateDialog(() => isAdmin = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                await createUser(
                  firstName: firstNameCtrl.text,
                  lastName: lastNameCtrl.text,
                  email: emailCtrl.text,
                  password: passwordCtrl.text,
                  isAdmin: isAdmin,
                );
                Navigator.pop(context);
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth =
        MediaQuery.of(context).size.width < 600 ? double.infinity : 260;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      /// ✅ APPBAR AVEC HAMBURGER AUTO
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Ajouter un utilisateur',
            icon: const Icon(Icons.person_add),
            onPressed: showCreateUserDialog,
          ),
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            onPressed: loadUsers,
          ),
        ],
      ),

      /// 🍔 DRAWER
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Admin Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Utilisateurs'),
              onTap: () {
                Navigator.pop(context);
                loadUsers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Plaintes'),
              onTap: () {
                Navigator.pop(context);
                // Exemple de navigation vers une page Complaints
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ComplaintListPage(), // créer ce screen
                  ),
                );
              },
            ),


            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
             
            ),
          ],
        ),
      ),

      /// 📄 BODY
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 📊 STATS
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _statCard(
                        width: cardWidth,
                        title: 'Utilisateurs',
                        value: users.length.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _statCard(
                        width: cardWidth,
                        title: 'Admins',
                        value: adminMap.values
                            .where((v) => v)
                            .length
                            .toString(),
                        icon: Icons.admin_panel_settings,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Liste des utilisateurs',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final user = users[i];
                        final isAdmin = adminMap[user.id] == true;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isAdmin
                                    ? Colors.deepPurple
                                    : Colors.blueGrey,
                                child: Text(
                                  user.firstName.isNotEmpty
                                      ? user.firstName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${user.firstName} ${user.lastName}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(user.email),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => deleteUser(user.id!),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 📦 STAT CARD
  Widget _statCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
