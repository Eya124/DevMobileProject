import 'package:flutter/material.dart';
import '../models/ads.dart';
import '../services/ads_service.dart';

class DetailPage extends StatefulWidget {
  final int adId;
  final Map<String, dynamic>? basicAd;

  const DetailPage({
    Key? key,
    required this.adId,
    this.basicAd,
  }) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map<String, dynamic>? adDetails;
  bool isLoading = true;
  String? error;
  int currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    print('Detail page initialized with adId: ${widget.adId}');
    _loadAdDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAdDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      print('Loading ad details for ID: ${widget.adId}');
      
      // Add timeout to prevent infinite loading
      final details = await AdsService.getAdDetails(widget.adId)
          .timeout(Duration(seconds: 10));
      
      print('API Response: $details');
      
      setState(() {
        adDetails = details['annonce'];
        isLoading = false;
      });
      
      print('Ad details set: $adDetails');
    } catch (e) {
      print('Error loading ad details: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      
      // If we have basic ad info, show it instead of error
      if (widget.basicAd != null) {
        print('Showing basic ad info as fallback');
        setState(() {
          adDetails = widget.basicAd;
          isLoading = false;
          error = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Détails de l\'annonce',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fonctionnalité de partage à venir')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              // TODO: Implement favorite functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ajouté aux favoris')),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Chargement...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Erreur: $error',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAdDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    print('Building content with adDetails: $adDetails');
    
    if (adDetails == null) {
      return Center(child: Text('Aucune donnée disponible'));
    }

    final ad = adDetails!;
    final images = (ad['images'] as List<dynamic>?)?.where((img) => img != null && img.toString().isNotEmpty).toList() ?? [];
    
    print('Ad data: $ad');
    print('Images: $images');
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header section
          _buildEnhancedHeader(ad),
          
          // Content matching modal layout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main image carousel (same as modal but with all images)
                _buildImageCarousel(images),
                
                const SizedBox(height: 16),
                
                // Image thumbnails (if multiple images, all images)
                if (images.length > 1)
                  Container(
                    height: 80,
                    width: double.infinity,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            final clampedIndex = index.clamp(0, images.length - 1);
                            setState(() {
                              currentImageIndex = clampedIndex;
                            });
                            _pageController.animateToPage(
                              clampedIndex,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: currentImageIndex == index ? Colors.orange : Colors.grey.shade300,
                                width: currentImageIndex == index ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                'http://10.0.2.2:8111${images[index]}',
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Product title (same as modal)
                Text(
                  ad['title']?.toString() ?? 'Sans titre',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Price (same as modal)
                Text(
                  '${ad['price']?.toString() ?? 'N/A'} DT',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Details section (same as modal)
                Text(
                  'Détails',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Specifications details (same as modal)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSpecRow('Type', ad['type']?.toString() ?? 'N/A'),
                      _buildSpecRow('Taille', ad['size']?.toString() ?? 'N/A'),
                      _buildSpecRow('Localisation', ad['delegation'] != null && ad['delegation'].toString().isNotEmpty 
                          ? '${ad['state']?.toString() ?? 'N/A'} - ${ad['delegation']}'
                          : ad['state']?.toString() ?? 'N/A'),
                      if (ad['description'] != null && ad['description'].toString().isNotEmpty)
                        _buildSpecRow('Description', ad['description'].toString()),
                      _buildSpecRow('Téléphone', ad['phone']?.toString() ?? 'N/A'),
                      if (ad['date_posted'] != null)
                        _buildSpecRow('Date de publication', ad['date_posted'].toString()),
                      if (ad['user_email'] != null && ad['user_email'].toString().isNotEmpty)
                        _buildSpecRow('Email', ad['user_email'].toString()),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(Map<String, dynamic> ad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade400,
            Colors.orange.shade600,
            Colors.orange.shade700,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with improved typography
          Text(
            ad['title']?.toString() ?? 'Sans titre',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 16),
          
          // Price with enhanced design
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  '${ad['price']?.toString() ?? 'N/A'} DT',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Enhanced info cards
          Row(
            children: [
              // Type
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.category,
                  title: 'Type',
                  value: ad['type']?.toString() ?? 'N/A',
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              
              SizedBox(width: 12),
              
              // Size
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.straighten,
                  title: 'Taille',
                  value: ad['size']?.toString() ?? 'N/A',
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              
              SizedBox(width: 12),
              
              // Location
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.location_on,
                  title: 'Localisation',
                  value: ad['state']?.toString() ?? 'N/A',
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    return Container(
      height: 350,
      width: double.infinity,
      child: Stack(
        children: [
          // Main image with PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentImageIndex = index.clamp(0, images.length - 1);
              });
            },
            itemCount: images.isNotEmpty ? images.length : 1,
            itemBuilder: (context, index) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                child: images.isNotEmpty
                    ? Image.network(
                        'http://10.0.2.2:8111${images[index]}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                      ),
              );
            },
          ),
          
          // Image indicators
          if (images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: 10,
                    height: 10,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentImageIndex == index
                          ? Colors.orange
                          : Colors.white.withOpacity(0.6),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Image counter
          if (images.length > 1)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${currentImageIndex + 1}/${images.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
