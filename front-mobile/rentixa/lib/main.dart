import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/providers/auth_provider.dart';
import 'package:rentixa/widgets/header.dart';
import 'package:rentixa/screens/auth/sign_up.dart';
import 'package:rentixa/screens/auth/sign_in.dart';
import 'package:rentixa/screens/auth/verify_otp.dart';
import 'package:rentixa/screens/chatbot/chat_discussion.dart';
import 'package:rentixa/screens/auth/profile.dart';
import 'package:rentixa/screens/auth/users_page.dart';
import 'package:rentixa/admin/admin_panel.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => SearchProvider()), // TEMP REMOVED
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ekri App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomeWithFilter(),
        '/sign-up': (context) => SignUpPage(),
        '/sign-in': (context) => SignInPage(),
        '/verify-otp': (context) => VerifyOtpPage(),
        '/profile': (context) => const ProfilePage(),
        '/users': (context) => const UsersPage(),

      },
    );
  }
}

class HomeWithFilter extends StatefulWidget {
  @override
  _HomeWithFilterState createState() => _HomeWithFilterState();
}

class _HomeWithFilterState extends State<HomeWithFilter> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // TEMP REMOVED (Ads state)
  // List<Ads> ads = [];
  bool isLoadingAds = false;
  String? errorMessage;

  // Pagination (structure conservée)
  int currentPage = 1;
  int itemsPerPage = 15;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();

    // TEMP REMOVED
    // _loadAds();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   SearchModal.show(context);
    // });
  }

  // Pagination logic conserved
  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() => currentPage++);
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() => currentPage = page);
    }
  }

  // TEMP REMOVED
  // void _openFilterModal() {}

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isUserLoggedIn =
        authProvider.userId != null && authProvider.userId != "0";

    return Scaffold(
      key: _scaffoldKey,

      // CHAT BUBBLE (conservé)
      floatingActionButton: isUserLoggedIn
          ? FloatingActionButton(
              backgroundColor: Colors.orange,
              child: const Icon(Icons.chat, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => ChatDiscussionModal(),
                );
              },
            )
          : null,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Header(
          isConnected: isUserLoggedIn,
          isVerified: isUserLoggedIn,
          isAdmin: false,
          username: authProvider.userInitials,
          leading: null,
          onSignIn: () {
            Navigator.pushNamed(context, '/sign-in');
          },
        ),
      ),

      body: Column(
        children: [
          // TOP ACTION BAR
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton(
                    onPressed: () {
                      // TEMP REMOVED
                      // showDialog(
                      //   context: context,
                      //   builder: (context) => CreateAdModal(),
                      // );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black87),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                    ),
                    child: const Text(
                      'CRÉER UNE ANNONCE',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      // _openFilterModal(); // TEMP REMOVED
                    },
                    child: const Icon(Icons.filter_list, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // CONTENT
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.construction,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Module annonces temporairement désactivé',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PAGINATION (structure conservée)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _previousPage,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page $currentPage'),
                IconButton(
                  onPressed: _nextPage,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
