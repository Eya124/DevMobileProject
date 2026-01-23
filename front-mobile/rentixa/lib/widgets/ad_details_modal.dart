import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ads.dart';
import '../services/ads_service.dart';
import 'package:rentixa/providers/search_provider.dart';
import '../providers/auth_provider.dart';
import '../pages/detail_page.dart';
import '../screens/ads/create_ad_modal.dart'; // Import this to use it for editing

class AdDetailsModal extends StatefulWidget {
  final int adId;
  final Ads? basicAd;

  const AdDetailsModal({Key? key, required this.adId, this.basicAd}) : super(key: key);

  @override
  State<AdDetailsModal> createState() => _AdDetailsModalState();
}

class _AdDetailsModalState extends State<AdDetailsModal> {
  Map<String, dynamic>? adDetails;
  bool isLoading = true;
  String? error;
  int currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

      final details = await AdsService.getAdDetails(widget.adId).timeout(const Duration(seconds: 10));
      
      setState(() {
        adDetails = details['annonce'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      
      if (widget.basicAd != null) {
        setState(() {
          adDetails = {
            'id': widget.basicAd!.id,
            'title': widget.basicAd!.title,
            'type': widget.basicAd!.type,
            'size': widget.basicAd!.size ?? 'N/A',
            'price': widget.basicAd!.price,
            'state': widget.basicAd!.state,
            'delegation': widget.basicAd!.delegation,
            'description': widget.basicAd!.description,
            'phone': widget.basicAd!.phone,
            'user': widget.basicAd!.user, 
            'images': widget.basicAd!.images,
          };
          isLoading = false;
          error = null;
        });
      }
    }
  }

  // --- DELETE LOGIC ---
  Future<void> _deleteAd() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: const Text('Voulez-vous vraiment supprimer cette annonce ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      setState(() => isLoading = true);
      final success = await AdsService.deleteAd(widget.adId);
      if (success && mounted) {
        final List<Ads> updatedAds = await AdsService.getAllAds();
        if (mounted) {
          Provider.of<SearchProvider>(context, listen: false).setSearchResults(updatedAds);
          Navigator.of(context).pop(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annonce supprimée'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Échec de la suppression');
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- UPDATE/EDIT LOGIC ---
  void _openEditModal() {
    if (adDetails == null) return;

    // Convert the current adDetails Map back to an Ads object for the modal
    final adToEdit = Ads(
      id: widget.adId,
      title: adDetails!['title'],
      description: adDetails!['description'],
      price: int.tryParse(adDetails!['price'].toString()) ?? 0,
      state: adDetails!['state'].toString(),
      delegation: adDetails!['delegation']?.toString(),
      type: adDetails!['type'].toString(),
      phone: int.tryParse(adDetails!['phone'].toString()) ?? 0,
      size: adDetails!['size'],
    );

    showDialog(
      context: context,
      builder: (context) => CreateAdModal(existingAd: adToEdit),
    ).then((_) => _loadAdDetails()); // Refresh details after closing edit modal
  }

  Widget _buildContent() {
    if (adDetails == null) return const Center(child: Text('Aucune donnée disponible'));

    final ad = adDetails!;
    final images = ad['images'] as List<dynamic>? ?? [];

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? loggedInUserId = authProvider.userId;
    
    final dynamic userData = ad['user'];
    String? adOwnerId;
    String ownerEmail = 'Inconnu';

    if (userData is Map) {
      adOwnerId = userData['id']?.toString();
      ownerEmail = userData['email']?.toString() ?? 'Inconnu';
    } else {
      adOwnerId = userData?.toString() ?? ad['user_id']?.toString();
      ownerEmail = ad['user_email']?.toString() ?? 'Inconnu';
    }

    final bool isOwner = loggedInUserId != null && 
                         adOwnerId != null && 
                         adOwnerId == loggedInUserId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel
          Container(
            width: double.infinity, height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => currentImageIndex = index),
                itemCount: images.isNotEmpty ? images.length.clamp(0, 3) : 1,
                itemBuilder: (context, index) {
                  return images.isNotEmpty
                      ? Image.network(
                          'http://172.24.162.10:8111${images[index]}', 
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, s) => const Icon(Icons.image_not_supported, size: 80),
                        )
                      : const Icon(Icons.image_not_supported, size: 80);
                },
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(ad['title']?.toString() ?? 'Sans titre', 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
              ),
              if (isOwner)
                const Chip(
                  label: Text('Votre annonce', style: TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: Colors.green,
                ),
            ],
          ),
          Text('${ad['price']?.toString() ?? '0'} DT', 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
          
          const SizedBox(height: 16),
          const Text('Détails', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildSpecRow('Annonceur', ownerEmail, icon: Icons.email_outlined),
                _buildSpecRow('Type', ad['type']?.toString() ?? 'N/A', icon: Icons.category_outlined),
                _buildSpecRow('Taille', ad['size']?.toString() ?? 'N/A', icon: Icons.straighten),
                _buildSpecRow('Localisation', '${ad['state'] ?? 'N/A'} - ${ad['delegation'] ?? ''}', icon: Icons.location_on_outlined),
                _buildSpecRow('Téléphone', ad['phone']?.toString() ?? 'N/A', icon: Icons.phone_outlined),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              if (isOwner) ...[
                // DELETE BUTTON
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200)
                  ),
                  child: IconButton(
                    onPressed: _deleteAd,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Supprimer',
                  ),
                ),
                // UPDATE/EDIT BUTTON
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200)
                  ),
                  child: IconButton(
                    onPressed: _openEditModal,
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    tooltip: 'Modifier',
                  ),
                ),
              ],
              
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DetailPage(
                          adId: widget.adId,
                          basicAd: widget.basicAd?.toJson(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Voir plus', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 18, color: Colors.amber), 
          if (icon != null) const SizedBox(width: 8),
          SizedBox(width: 90, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.orange)) 
              : error != null 
                ? Center(child: Text('Erreur: $error')) 
                : _buildContent(),
            Positioned(
              top: 10, right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}