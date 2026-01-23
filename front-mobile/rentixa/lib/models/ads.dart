class Ads {
  final int? id;
  final String title;
  final String? description;
  final String? size;
  final int price;
  final String state; // State name
  final String? delegation; // Delegation name, nullable
  final String? jurisdiction; // Jurisdiction name, nullable
  final bool status;
  final String type; // Type name
  final String? localisation;
  final DateTime? datePosted;
  final int? user; // Foreign key ID, nullable
  final int phone;
  final String? idFolder;
  final String? url;
  final String? binome;
  final List<String>? images; // Add images field

  Ads({
    this.id,
    required this.title,
    this.description,
    this.size,
    required this.price,
    required this.state,
    this.delegation,
    this.jurisdiction,
    this.status = true,
    required this.type,
    this.localisation,
    this.datePosted,
    this.user,
    required this.phone,
    this.idFolder,
    this.url,
    this.binome,
    this.images,
  });

  factory Ads.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing ads JSON: $json');
      
      final ad = Ads(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        size: json['size']?.toString(),
        price: json['price'] is int ? json['price'] : int.tryParse(json['price']?.toString() ?? '0') ?? 0,
        state: json['state']?.toString() ?? '',
        delegation: json['delegation']?.toString(),
        jurisdiction: json['jurisdiction']?.toString(),
        status: json['status'] is bool ? json['status'] : (json['status']?.toString() == 'true'),
        type: json['type']?.toString() ?? '',
        localisation: json['localisation']?.toString(),
        datePosted: json['date_posted'] != null 
            ? DateTime.parse(json['date_posted'].toString())
            : null,
        user: json['user'] is int ? json['user'] : int.tryParse(json['user']?.toString() ?? ''),
        phone: json['phone'] is int ? json['phone'] : int.tryParse(json['phone']?.toString() ?? '0') ?? 0,
        idFolder: json['id_folder']?.toString(),
        url: json['url']?.toString(),
        binome: json['binome']?.toString(),
        images: json['images'] != null 
            ? List<String>.from(json['images'].map((x) {
                String imageUrl = x.toString();
                // Convert relative URLs to absolute URLs
                if (imageUrl.startsWith('/media/')) {
                  return 'http://10.0.2.2:8111$imageUrl';
                }
                return imageUrl;
              }))
            : null,
      );
      
      print('Successfully parsed ads: ${ad.title}');
      return ad;
    } catch (e, stackTrace) {
      print('Error parsing ads JSON: $e');
      print('JSON data: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (size != null) 'size': size,
      'price': price,
      'state': state,
      if (delegation != null) 'delegation': delegation,
      if (jurisdiction != null) 'jurisdiction': jurisdiction,
      'status': status,
      'type': type,
      if (localisation != null) 'localisation': localisation,
      if (datePosted != null) 'date_posted': datePosted!.toIso8601String(),
      if (user != null) 'user': user,
      'phone': phone,
      if (idFolder != null) 'id_folder': idFolder,
      if (url != null) 'url': url,
      if (binome != null) 'binome': binome,
      if (images != null) 'images': images,
    };
  }

  // Create a copy of the ads with updated fields
  Ads copyWith({
    int? id,
    String? title,
    String? description,
    String? size,
    int? price,
    String? state,
    String? delegation,
    String? jurisdiction,
    bool? status,
    String? type,
    String? localisation,
    DateTime? datePosted,
    int? user,
    int? phone,
    String? idFolder,
    String? url,
    String? binome,
    List<String>? images,
  }) {
    return Ads(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      size: size ?? this.size,
      price: price ?? this.price,
      state: state ?? this.state,
      delegation: delegation ?? this.delegation,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      status: status ?? this.status,
      type: type ?? this.type,
      localisation: localisation ?? this.localisation,
      datePosted: datePosted ?? this.datePosted,
      user: user ?? this.user,
      phone: phone ?? this.phone,
      idFolder: idFolder ?? this.idFolder,
      url: url ?? this.url,
      binome: binome ?? this.binome,
      images: images ?? this.images,
    );
  }

  @override
  String toString() {
    return 'Ads(id: $id, title: $title, price: $price, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ads && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 
