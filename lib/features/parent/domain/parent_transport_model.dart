/// Transport info for the parent's selected child — `GET /api/parent/transport`.
/// `activeTripId`, when non-null, is the id of an in-progress driver trip
/// the parent can watch live on Firebase Realtime DB (`buses/{tripId}`).
class ParentTransport {
  const ParentTransport({
    this.route,
    this.stoppage,
    this.activeTripId,
    this.tripType,
    this.driverName,
    this.driverContact,
    this.conductorName,
    this.conductorContact,
  });

  final TransportRouteSummary? route;
  final TransportStoppageSummary? stoppage;

  /// `BusTrip.id` for the currently in-progress trip — null when no live
  /// trip is running for this route right now.
  final String? activeTripId;
  final String? tripType;
  final String? driverName;
  final String? driverContact;
  final String? conductorName;
  final String? conductorContact;

  bool get hasAssignment => route != null;
  bool get isLive => activeTripId != null && activeTripId!.isNotEmpty;

  factory ParentTransport.fromJson(Map<String, dynamic> json) {
    return ParentTransport(
      route: json['route'] is Map
          ? TransportRouteSummary.fromJson(
              (json['route'] as Map).cast<String, dynamic>())
          : null,
      stoppage: json['stoppage'] is Map
          ? TransportStoppageSummary.fromJson(
              (json['stoppage'] as Map).cast<String, dynamic>())
          : null,
      activeTripId: json['activeTripId']?.toString(),
      tripType: json['tripType']?.toString(),
      driverName: json['driverName']?.toString(),
      driverContact: json['driverContact']?.toString(),
      conductorName: json['conductorName']?.toString(),
      conductorContact: json['conductorContact']?.toString(),
    );
  }
}

class TransportRouteSummary {
  const TransportRouteSummary({
    required this.id,
    required this.name,
    this.description,
    this.stoppages = const [],
  });

  final String id;
  final String name;
  final String? description;
  final List<TransportStoppageSummary> stoppages;

  factory TransportRouteSummary.fromJson(Map<String, dynamic> json) {
    final stops = (json['stoppages'] as List? ?? const [])
        .map((s) =>
            TransportStoppageSummary.fromJson(s as Map<String, dynamic>))
        .toList();
    return TransportRouteSummary(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      stoppages: stops,
    );
  }
}

class TransportStoppageSummary {
  const TransportStoppageSummary({
    required this.id,
    required this.name,
    required this.order,
    this.feeAmount,
  });

  final String id;
  final String name;
  final int order;
  final double? feeAmount;

  factory TransportStoppageSummary.fromJson(Map<String, dynamic> json) =>
      TransportStoppageSummary(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        order: (json['order'] as num?)?.toInt() ?? 0,
        feeAmount: json['feeAmount'] is num
            ? (json['feeAmount'] as num).toDouble()
            : double.tryParse(json['feeAmount']?.toString() ?? ''),
      );
}
