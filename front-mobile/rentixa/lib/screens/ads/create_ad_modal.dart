import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data'; 
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rentixa/services/ads_service.dart';
import 'package:rentixa/providers/search_provider.dart';
import 'package:rentixa/models/ads.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateAdModal extends StatefulWidget {
  final Ads? existingAd;
  const CreateAdModal({Key? key, this.existingAd}) : super(key: key);

  @override
  State<CreateAdModal> createState() => _CreateAdModalState();
}

class _CreateAdModalState extends State<CreateAdModal> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? selectedState;
  String? selectedDelegation;
  String? selectedType;
  String selectedSize = 'S'; 

  List<dynamic> states = [];
  List<dynamic> delegations = [];
  List<dynamic> types = [];

  bool isLoadingStates = false;
  bool isLoadingDelegations = false;
  bool isLoadingTypes = false;
  bool isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];

  bool get isEditing => widget.existingAd != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadStates(), _loadTypes()]);
    if (isEditing && mounted) {
      _preFillTextFieldsOnly();
    }
  }

  void _preFillTextFieldsOnly() {
    final ad = widget.existingAd!;
    titleController.text = ad.title;
    descriptionController.text = ad.description ?? '';
    priceController.text = ad.price.toString();
    phoneController.text = ad.phone.toString();
    setState(() {});
  }

  Future<void> _loadStates() async {
    setState(() => isLoadingStates = true);
    final data = await AdsService.getAllStates();
    if (mounted) setState(() { states = data; isLoadingStates = false; });
  }

  Future<void> _loadDelegations(int stateId) async {
    setState(() => isLoadingDelegations = true);
    final data = await AdsService.getAllDelegationsByStateId(stateId);
    if (mounted) setState(() { delegations = data; isLoadingDelegations = false; });
  }

  Future<void> _loadTypes() async {
    setState(() => isLoadingTypes = true);
    final data = await AdsService.getAllTypes();
    if (mounted) setState(() { types = data; isLoadingTypes = false; });
  }

  Widget _buildSafeDropdown({required String label, required List<dynamic> items, required String? currentValue, required Function(String?) onChanged, bool isLoading = false}) {
    bool valueExists = items.any((item) => item['id'].toString() == currentValue);
    return DropdownButtonFormField<String>(
      value: valueExists ? currentValue : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((item) => DropdownMenuItem<String>(value: item['id'].toString(), child: Text(item['name'].toString()))).toList(),
      onChanged: isLoading ? null : onChanged,
    );
  }

  Future<void> _submitForm() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (titleController.text.isEmpty || selectedState == null || selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Champs obligatoires manquants')));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token') ?? prefs.getString('token');

      List<Map<String, dynamic>> imageDataList = [];
      for (var xFile in _images) {
        final Uint8List bytes = await xFile.readAsBytes();
        imageDataList.add({'bytes': bytes, 'name': xFile.name});
      }

      final ad = Ads(
        id: widget.existingAd?.id,
        title: titleController.text,
        description: descriptionController.text,
        size: selectedSize, 
        price: int.tryParse(priceController.text) ?? 0,
        state: selectedState!, 
        delegation: selectedDelegation, 
        type: selectedType!, 
        phone: int.tryParse(phoneController.text) ?? 0,
        datePosted: DateTime.now(),
      );

      // IMPORTANT: Ensure your AdsService uses PUT for updateAd
      final response = isEditing 
          ? await AdsService.updateAd(adId: ad.id!, ad: ad, images: imageDataList, token: token)
          : await AdsService.addAd(ad: ad, images: imageDataList, userId: auth.userId, token: token);

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          final List<Ads> updatedAds = await AdsService.getAllAds();
          Provider.of<SearchProvider>(context, listen: false).setSearchResults(updatedAds);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Succès !'), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${response.statusCode}')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEditing ? "Modifier" : "Ajouter", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Titre*", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Prix*", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Tel*", border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 12),
            _buildSafeDropdown(label: "Gouvernorat*", items: states, currentValue: selectedState, isLoading: isLoadingStates, onChanged: (val) {
              setState(() { selectedState = val; selectedDelegation = null; });
              if (val != null) _loadDelegations(int.parse(val));
            }),
            const SizedBox(height: 12),
            _buildSafeDropdown(label: "Délégation", items: delegations, currentValue: selectedDelegation, isLoading: isLoadingDelegations, onChanged: (val) => setState(() => selectedDelegation = val)),
            const SizedBox(height: 12),
            _buildSafeDropdown(label: "Type*", items: types, currentValue: selectedType, isLoading: isLoadingTypes, onChanged: (val) => setState(() => selectedType = val)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedSize,
              decoration: const InputDecoration(labelText: "Taille*", border: OutlineInputBorder()),
              items: ['S', 'M', 'L'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => selectedSize = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
              child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("VALIDER", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}