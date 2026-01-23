import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/admin/admin_panel.dart';

// --- Providers ---
import 'package:rentixa/providers/auth_provider.dart';
import 'package:rentixa/providers/search_provider.dart';

// --- Services & Models ---
import 'package:rentixa/services/ads_service.dart';
import 'package:rentixa/models/ads.dart';

// --- Widgets & Pages ---
import 'package:rentixa/widgets/header.dart';
import 'package:rentixa/widgets/ad_details_modal.dart';
import 'package:rentixa/screens/ads/create_ad_modal.dart'; 
import 'package:rentixa/screens/auth/sign_up.dart';
import 'package:rentixa/screens/auth/sign_in.dart';
import 'package:rentixa/screens/auth/verify_otp.dart';
import 'package:rentixa/screens/auth/profile.dart';
import 'package:rentixa/screens/auth/users_page.dart';
import 'package:rentixa/screens/complaint/Add_complaint.dart';
import 'package:rentixa/screens/complaint/complaint_list.dart';
import 'package:rentixa/screens/chatbot/chat_discussion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.restoreSession(); // ✅ RESTAURATION SESSION

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentixa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeWithFilter(),
        '/sign-up': (context) => SignUpPage(),
        '/sign-in': (context) => SignInPage(),
        '/verify-otp': (context) => VerifyOtpPage(),
        '/profile': (context) => const ProfilePage(),
        '/users': (context) => const UsersPage(),
        '/admin': (context) => const AdminPanel(),
        '/complaints': (context) => ComplaintListPage(),
        '/complaints/add': (context) => AddComplaintPage(),
      },
    );
  }
}

class HomeWithFilter extends StatefulWidget {
  const HomeWithFilter({super.key});

  @override
  State<HomeWithFilter> createState() => _HomeWithFilterState();
}

class _HomeWithFilterState extends State<HomeWithFilter> {
  bool isLoadingAds = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAds();
    });
  }

  Future<void> _loadAds() async {
    if (!mounted) return;
    setState(() {
      isLoadingAds = true;
      errorMessage = null;
    });

    try {
      final List<Ads> ads = await AdsService.getAllAds();
      if (mounted) {
        Provider.of<SearchProvider>(context, listen: false).setSearchResults(ads);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Impossible de charger les annonces: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingAds = false;
        });
      }
    }
  }

  void _navigateToCreateAd() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateAdModal(); 
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final searchProvider = Provider.of<SearchProvider>(context);

    final bool isUserLoggedIn =
        authProvider.userId != null && authProvider.userId != "0";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      
      floatingActionButton: isUserLoggedIn
          ? FloatingActionButton(
              backgroundColor: Colors.orange,
              child: const Icon(Icons.chat, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => ChatDiscussionModal(),
                );
              },
            )
          : null,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Header(
          isConnected: isUserLoggedIn,
          isVerified: isUserLoggedIn,
          isAdmin: false,
          username: authProvider.userInitials,
          onSignIn: () {
            Navigator.pushNamed(context, '/sign-in');
          },
          onAddAd: _navigateToCreateAd, 
          leading: isUserLoggedIn 
            ? IconButton(
                icon: const Icon(Icons.add_box_outlined, color: Colors.orange),
                onPressed: _navigateToCreateAd,
                tooltip: "Ajouter une annonce",
              )
            : null,
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadAds,
        child: _buildBody(searchProvider),
      ),
    );
  }

  Widget _buildBody(SearchProvider searchProvider) {
    if (isLoadingAds) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAds,
              child: const Text("Réessayer"),
            ),
          ],
        ),
      );
    }

    if (searchProvider.searchResults.isEmpty) {
      return const Center(
        child: Text("Aucune annonce disponible pour le moment."),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      itemCount: searchProvider.searchResults.length,
      itemBuilder: (context, index) {
        final ad = searchProvider.searchResults[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: Colors.orange.shade50,
                child: const Icon(Icons.home_work, color: Colors.orange),
              ),
            ),
            title: Text(
              ad.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("${ad.delegation ?? ad.state ?? 'Localisation inconnue'}"),
                Text(
                  '${ad.price} DT',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AdDetailsModal(
                    adId: ad.id ?? 0, 
                    basicAd: ad,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}