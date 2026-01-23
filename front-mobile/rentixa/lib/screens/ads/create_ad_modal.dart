import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rentixa/services/ads_service.dart';
import 'package:rentixa/models/ads.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/providers/auth_provider.dart';

class CreateAdModal extends StatefulWidget {
  const CreateAdModal({Key? key}) : super(key: key);

  @override
  State<CreateAdModal> createState() => _CreateAdModalState();
}

class _CreateAdModalState extends State<CreateAdModal> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController roomController = TextEditingController();

  String? selectedState;
  String? selectedDelegation; // Re-added
  String? selectedType;

  List<dynamic> states = [];
  List<dynamic> delegations = []; // Re-added
  List<dynamic> types = [];

  bool isLoadingStates = false;
  bool isLoadingDelegations = false; // Re-added
  bool isLoadingTypes = false;
  bool isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadStates(), _loadTypes()]);
  }

  Future<void> _loadStates() async {
    if (!mounted) return;
    setState(() => isLoadingStates = true);
    try {
      final data = await AdsService.getAllStates();
      if (mounted) {
        setState(() {
          states = data ?? []; 
          isLoadingStates = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingStates = false);
    }
  }

  Future<void> _loadDelegations(int stateId) async {
    print('UI: Starting to load delegations for State ID: $stateId');
    setState(() => isLoadingDelegations = true);
    
    try {
      final data = await AdsService.getAllDelegationsByStateId(stateId);
      if (mounted) {
        setState(() {
          delegations = data ?? [];
          isLoadingDelegations = false;
        });
        print('UI: Successfully loaded ${delegations.length} items');
      }
    } catch (e) {
      print('UI ERROR: Exception caught in modal: $e');
      if (mounted) setState(() => isLoadingDelegations = false);
    }
  }

  Future<void> _loadTypes() async {
    if (!mounted) return;
    setState(() => isLoadingTypes = true);
    try {
      final data = await AdsService.getAllTypes();
      if (mounted) {
        setState(() {
          types = data ?? [];
          isLoadingTypes = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingTypes = false);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile>? picked = await _picker.pickMultiImage();
    if (picked != null) {
      setState(() => _images.addAll(picked));
    }
  }

  Future<void> _submitForm() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (titleController.text.isEmpty || selectedState == null || selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir les champs obligatoires (*)')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final ad = Ads(
        title: titleController.text,
        description: descriptionController.text,
        size: 'S',
        price: int.tryParse(priceController.text) ?? 0,
        state: selectedState!,
        delegation: selectedDelegation, // Now sends the selected ID
        jurisdiction: null, 
        type: selectedType!,
        localisation: roomController.text, 
        phone: int.tryParse(phoneController.text) ?? 0,
        datePosted: DateTime.now(),
      );

      final response = await AdsService.addAd(
        ad: ad,
        imagePaths: _images.map((img) => img.path).toList(),
        userId: auth.userId,
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce créée !')),
        );
      } else {
        throw Exception("Server Error: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Nouvelle Annonce", style: Theme.of(context).textTheme.headlineSmall),
              const Divider(),
              const SizedBox(height: 16),
              
              _buildField(titleController, "Titre de l'annonce*"),
              const SizedBox(height: 12),
              
              _buildField(descriptionController, "Description*", maxLines: 3),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildField(priceController, "Prix (TND)*", isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(phoneController, "Téléphone*", isNumber: true)),
                ],
              ),
              const SizedBox(height: 12),

              _buildDropdown("État*", states, selectedState, (val) {
                setState(() => selectedState = val);
                if (val != null) _loadDelegations(int.parse(val));
              }, isLoadingStates),
              const SizedBox(height: 12),

              // Re-added Delegation Dropdown
              _buildDropdown("Délégation", delegations, selectedDelegation, (val) {
                setState(() => selectedDelegation = val);
              }, isLoadingDelegations),
              const SizedBox(height: 12),

              _buildDropdown("Type*", types, selectedType, (val) {
                setState(() => selectedType = val);
              }, isLoadingTypes),
              const SizedBox(height: 20),

              _buildImagePicker(),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Publier l'annonce", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildDropdown(String label, List items, String? currentVal, Function(String?) onChanged, bool loading) {
    return DropdownButtonFormField<String>(
      value: currentVal,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: loading ? const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
        ) : null,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['id'].toString(),
          child: Text(item['name'].toString()),
        );
      }).toList(),
      onChanged: loading ? null : onChanged,
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Photos", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._images.asMap().entries.map((entry) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb 
                      ? Image.network(entry.value.path, width: 80, height: 80, fit: BoxFit.cover)
                      : Image.file(File(entry.value.path), width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(entry.key)),
                      child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                    ),
                  )
                ],
              );
            }).toList(),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add_a_photo, color: Colors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }
}