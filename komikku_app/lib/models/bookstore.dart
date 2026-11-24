/// Model data Toko Buku / Perpustakaan untuk fitur LBS (SRS 2.5.3, FR-LBS)
class Bookstore {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String address;
  double? distanceInMeters;

  Bookstore({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    this.distanceInMeters,
  });

  factory Bookstore.fromJson(Map<String, dynamic> json) {
    return Bookstore(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Toko Buku',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }

  /// Menampilkan teks jarak terbaca (misal: "350 m" atau "2.4 km")
  String get formattedDistance {
    if (distanceInMeters == null) return '-';
    if (distanceInMeters! < 1000) {
      return '${distanceInMeters!.round()} m';
    }
    final inKm = distanceInMeters! / 1000;
    return '${inKm.toStringAsFixed(1)} km';
  }

  /// Apakah lokasi sangat dekat (< 500 m) sesuai FR-LBS-04
  bool get isVeryClose => (distanceInMeters ?? double.infinity) < 500;
}
