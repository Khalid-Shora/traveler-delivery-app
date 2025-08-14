class TripModel {
  final String tripId;
  final String travelerId;
  final String from;
  final String to;
  final DateTime departDate;
  final DateTime? arriveDate;
  final double availableWeight;
  final List<String>? orders;
  final String status;
  final DateTime? createdAt;

  TripModel({
    required this.tripId,
    required this.travelerId,
    required this.from,
    required this.to,
    required this.departDate,
    this.arriveDate,
    required this.availableWeight,
    this.orders,
    required this.status,
    this.createdAt,
  });

  factory TripModel.fromMap(Map<String, dynamic> map) => TripModel(
    tripId: map['tripId'],
    travelerId: map['travelerId'],
    from: map['from'],
    to: map['to'],
    departDate: map['departDate'].toDate(),
    arriveDate: map['arriveDate']?.toDate(),
    availableWeight: (map['availableWeight'] as num).toDouble(),
    orders: map['orders'] != null
        ? List<String>.from(map['orders'])
        : null,
    status: map['status'],
    createdAt: map['createdAt']?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'tripId': tripId,
    'travelerId': travelerId,
    'from': from,
    'to': to,
    'departDate': departDate,
    'arriveDate': arriveDate,
    'availableWeight': availableWeight,
    'orders': orders,
    'status': status,
    'createdAt': createdAt,
  };
}
