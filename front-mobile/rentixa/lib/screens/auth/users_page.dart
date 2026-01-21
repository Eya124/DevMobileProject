import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../widgets/header.dart';
import '../../providers/auth_provider.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({Key? key}) : super(key: key);

  static const Color primaryOrange = Colors.orange;

  /// 🔥 Appel réel à TON backend
  Future<List<dynamic>> fetchUsers() async {
    final uri = Uri.parse('http://192.168.184.68:8111/users/all');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['users'] as List<dynamic>;
    } else {
      throw Exception('Erreur lors du chargement des utilisateurs');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Header(
          isConnected: authProvider.userId != null,
          isVerified: authProvider.userId != null,
          isAdmin: true,
          username: authProvider.userInitials,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liste des utilisateurs',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: fetchUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erreur : ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final users = snapshot.data!;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          primaryOrange.withOpacity(0.1),
                        ),
                        columns: const [
                          DataColumn(label: Text('Utilisateur')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Statut')),
                          DataColumn(label: Text('Admin')),
                        ],
                        rows: users.map((user) {
                          final firstName = user['first_name'] ?? '';
                          final lastName = user['last_name'] ?? '';
                          final email = user['email'] ?? '';
                          final isActive = user['is_active'] == true;
                          final isAdmin = user['is_admin'] == true;

                          final initials =
                              '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
                                  .toUpperCase();

                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          primaryOrange.withOpacity(0.15),
                                      child: Text(
                                        initials.isEmpty ? 'U' : initials,
                                        style: const TextStyle(
                                          color: primaryOrange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$firstName $lastName',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(email)),
                              DataCell(
                                Text(
                                  isActive ? 'Actif' : 'Inactif',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Icon(
                                  isAdmin
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: isAdmin
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
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
}
