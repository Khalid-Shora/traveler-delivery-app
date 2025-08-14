class Address {
  final String label;
  final String country;
  final String city;
  final String street;
  final String details; // Apt, Building, etc
  final double? lat;
  final double? lng;

  Address({
    required this.label,
    required this.country,
    required this.city,
    required this.street,
    required this.details,
    this.lat,
    this.lng,
  });

  // دالة ترجع العنوان كامل في سطر واحد
  String get fullAddress {
    List<String> parts = [
      if (country.isNotEmpty) country,
      if (city.isNotEmpty) city,
      if (street.isNotEmpty) street,
      if (details.isNotEmpty) details,
    ];
    return parts.join(', ');
  }


  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      label: map['label'] ?? '',
      country: map['country'] ?? '',
      city: map['city'] ?? '',
      street: map['street'] ?? '',
      details: map['details'] ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'country': country,
      'city': city,
      'street': street,
      'details': details,
      'lat': lat,
      'lng': lng,
    };
  }
}
