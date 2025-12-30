import 'package:flutter/material.dart';
import 'package:fluttercourse/screens/feedback/feedback_list_page.dart';
import 'package:provider/provider.dart';
import 'package:fluttercourse/providers/auth_provider.dart';
import 'package:fluttercourse/providers/search_provider.dart';
import 'package:fluttercourse/widgets/header.dart';
import 'package:fluttercourse/widgets/filter.dart';
import 'package:fluttercourse/widgets/card.dart';
import 'package:fluttercourse/widgets/search_modal.dart';
import 'package:fluttercourse/screens/auth/sign_up.dart';
import 'package:fluttercourse/screens/auth/sign_in.dart';
import 'package:fluttercourse/screens/auth/verify_otp.dart';
import 'package:fluttercourse/screens/ads/create_ad_modal.dart';
import 'package:fluttercourse/services/ads_service.dart';
import 'package:fluttercourse/models/ads.dart';
import 'package:fluttercourse/screens/chatbot/chat_discussion.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
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
      initialRoute: '/all-ads',
      routes: {
        '/home': (context) => HomeWithFilter(),
        '/sign-up': (context) => SignUpPage(),
        '/sign-in': (context) => SignInPage(),
        '/all-ads': (context) => HomeWithFilter(),
        '/verify-otp': (context) => VerifyOtpPage(),
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
  
  // State for ads
  List<Ads> ads = [];
  bool isLoadingAds = false;
  String? errorMessage;
  
  // Pagination state
  int currentPage = 1;
  int itemsPerPage = 15;
  int totalPages = 0;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadAds();
    
    // Show search modal when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SearchModal.show(context);
    });
  }

  Future<void> _loadAds() async {
    setState(() {
      isLoadingAds = true;
      errorMessage = null;
    });

    try {
      print('Loading ads...');
      final adsData = await AdsService.getAllAds();
      print('Ads loaded: ${adsData.length} items');
      print('First ad: ${adsData.isNotEmpty ? adsData.first.toString() : 'No ads'}');
      
      setState(() {
        ads = adsData;
        isLoadingAds = false;
        totalPages = (adsData.length / itemsPerPage).ceil();
        currentPage = 1;
        print('Total pages: $totalPages, Current page: $currentPage');
      });
    } catch (e) {
      print('Error loading ads: $e');
      setState(() {
        errorMessage = 'Erreur lors du chargement des annonces: $e';
        isLoadingAds = false;
      });
    }
  }

  List<Ads> getCurrentPageAds() {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return ads.sublist(startIndex, endIndex > ads.length ? ads.length : endIndex);
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
      });
    }
  }

  void _openFilterModal() {
    final double modalHeight = 600.0; // Adjust as needed for your filter content
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double verticalMargin = (screenHeight - modalHeight) / 2;
    
    // Calculate responsive width
    double modalWidth = 350;
    if (screenWidth < 400) {
      modalWidth = screenWidth - 48; // Leave 24px margin on each side
    }
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filtres',
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: modalWidth,
              height: modalHeight,
              margin: EdgeInsets.only(
                top: verticalMargin > 0 ? verticalMargin : 24, 
                bottom: verticalMargin > 0 ? verticalMargin : 24,
                left: 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(2, 4),
                  ),
                ],
              ),
              child: Filter(
                isOpen: true,
                onClose: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(-1, 0),
            end: Offset(0, 0),
          ).animate(anim1),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
     final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final bool isUserLoggedIn = authProvider.userId != null && authProvider.userId != "0";
    return Scaffold(
      key: _scaffoldKey,
       // ✅ CHAT DISCUSSION BUBBLE
      floatingActionButton: isUserLoggedIn
        ? FloatingActionButton(
        backgroundColor: Colors.orange,
        child: Icon(Icons.chat, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => ChatDiscussionModal(),
          );
        },
      ): null,
      appBar: PreferredSize(
      preferredSize: Size.fromHeight(60.0),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Stack(
            children: [
              Header(
                isConnected: authProvider.userId != null,
                isVerified: authProvider.userId != null,
                isAdmin: false,
                username: authProvider.userInitials,
                leading: null,
                onSignIn: () {
                  Navigator.pushNamed(context, '/sign-in');
                },
              ),
              if (isUserLoggedIn)
              // 🔔 FEEDBACK BUTTON
              Positioned(
                right: 150,
                top: 12,
                child: IconButton(
                  tooltip: "Donner un avis",
                  icon: Icon(Icons.rate_review, color: Colors.orange),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeedbackListPage(adsList: ads),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
      body: Column(
        children: [
          // Top buttons row
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Much smaller padding
            child: Row(
              children: [
                // Create Ad button - very compact
                Expanded(
                  flex: 3, // Back to 3 for better proportion
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CreateAdModal(),
                      ).then((_) {
                        // Reload ads after creating a new one
                        _loadAds();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black87, width: 1),
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Minimal horizontal padding
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      backgroundColor: Colors.white,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CRÉER UNE ANNONCE', // Full text restored
                        style: TextStyle(
                          fontSize: 11, // Slightly larger but still compact
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8), // Smaller spacing
                // Filter button - very compact
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _openFilterModal,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black87),
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Minimal padding
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Smaller radius
                      backgroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list, color: Colors.black87, size: 12), // Smaller icon
                        SizedBox(width: 2), // Minimal spacing
                        Flexible(
                          child: Text(
                            'FILTRER', // Shorter text
                            style: TextStyle(
                              fontSize: 10, // Very small font
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Status indicator
                Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.grey.shade50,
                  child: Row(
                    children: [
                      Icon(
                        isLoadingAds ? Icons.hourglass_empty : Icons.list,
                        color: isLoadingAds ? Colors.orange : Colors.green,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isLoadingAds 
                          ? 'Chargement...' 
                          : '${ads.length} annonces trouvées',
                        style: TextStyle(
                          fontSize: 14,
                          color: isLoadingAds ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      if (totalPages > 1)
                        Text(
                          'Page $currentPage sur $totalPages',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Ads list
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (isLoadingAds) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Chargement des annonces...'),
                            ],
                          ),
                        );
                      }

                      if (errorMessage != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAds,
                                child: Text('Réessayer'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (ads.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Aucune annonce trouvée',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Soyez le premier à créer une annonce !',
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 16),
                              // Debug information
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Total ads: ${ads.length}'),
                                    Text('Total pages: $totalPages'),
                                    Text('Current page: $currentPage'),
                                    Text('Items per page: $itemsPerPage'),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadAds,
                                      child: Text('Reload Ads from API'),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Add test data
                                        setState(() {
                                          ads = [
                                            Ads(
                                              id: 1,
                                              title: 'Test Ad 1',
                                              description: 'Test description 1',
                                              price: 1000,
                                              state: 'Test State',
                                              type: 'Test Type',
                                              phone: 123456789,
                                            ),
                                            Ads(
                                              id: 2,
                                              title: 'Test Ad 2',
                                              description: 'Test description 2',
                                              price: 2000,
                                              state: 'Test State',
                                              type: 'Test Type',
                                              phone: 123456789,
                                            ),
                                            Ads(
                                              id: 3,
                                              title: 'Test Ad 3',
                                              description: 'Test description 3',
                                              price: 3000,
                                              state: 'Test State',
                                              type: 'Test Type',
                                              phone: 123456789,
                                            ),
                                          ];
                                          totalPages = (ads.length / itemsPerPage).ceil();
                                          currentPage = 1;
                                        });
                                      },
                                      child: Text('Load Test Data'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          

                        );
                      }

                      final currentAds = getCurrentPageAds();
                      
                      // Debug: Show current ads info
                      print('Current ads on page $currentPage: ${currentAds.length}');
                      if (currentAds.isEmpty && ads.isNotEmpty) {
                        print('Warning: No ads on current page but total ads: ${ads.length}');
                      }
                      
                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: currentAds.length,
                        itemBuilder: (context, index) {
                          final ad = currentAds[index];
                          print('Rendering ad $index: ${ad.title}');
                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                                    child: CardWidget(
          imageUrl: (ad.images != null && ad.images!.isNotEmpty)
              ? ad.images!.first
              : (ad.url ?? 'https://via.placeholder.com/300x160'),
          price: '${ad.price} DT',
          title: ad.title,
          size: ad.size ?? 'N/A',
          state: ad.state,
          delegation: ad.delegation,
          type: ad.type,
          description: ad.description ?? '',
          ad: ad, // Pass the Ads object for details modal
        ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // Paginator
                if (totalPages > 1)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Previous button
                        IconButton(
                          onPressed: currentPage > 1 ? _previousPage : null,
                          icon: Icon(Icons.chevron_left),
                          color: currentPage > 1 ? Colors.orange : Colors.grey,
                        ),
                        
                        // Page numbers
                        ...List.generate(
                          totalPages > 7 ? 7 : totalPages,
                          (index) {
                            int pageNumber;
                            if (totalPages <= 7) {
                              pageNumber = index + 1;
                            } else {
                              if (currentPage <= 4) {
                                pageNumber = index + 1;
                              } else if (currentPage >= totalPages - 3) {
                                pageNumber = totalPages - 6 + index;
                              } else {
                                pageNumber = currentPage - 3 + index;
                              }
                            }
                            
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () => _goToPage(pageNumber),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: currentPage == pageNumber ? Colors.orange : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: currentPage == pageNumber ? Colors.orange : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      pageNumber.toString(),
                                      style: TextStyle(
                                        color: currentPage == pageNumber ? Colors.white : Colors.black87,
                                        fontWeight: currentPage == pageNumber ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Next button
                        IconButton(
                          onPressed: currentPage < totalPages ? _nextPage : null,
                          icon: Icon(Icons.chevron_right),
                          color: currentPage < totalPages ? Colors.orange : Colors.grey,
                        ),
                      ],
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