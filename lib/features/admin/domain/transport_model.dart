class TransportRoute {
  final String id;
  final String name;
  final String vehicleNumber;
  final String driverName;
  final List<TransportStop> stoppages;

  const TransportRoute({
    required this.id,
    required this.name,
    required this.vehicleNumber,
    required this.driverName,
    required this.stoppages,
  });

  factory TransportRoute.fromJson(Map<String, dynamic> json) => TransportRoute(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        vehicleNumber: json['vehicleNumber']?.toString() ?? '',
        driverName: json['driverName']?.toString() ?? '',
        stoppages: (json['stoppages'] as List<dynamic>?)
                ?.map((e) => TransportStop.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class TransportStop {
  final String id;
  final String name;
  final int order;
  final double fee;

  const TransportStop({
    required this.id,
    required this.name,
    required this.order,
    required this.fee,
  });

  factory TransportStop.fromJson(Map<String, dynamic> json) => TransportStop(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        fee: (json['fee'] as num?)?.toDouble() ?? 0,
      );
}

class TransportAssignment {
  final String studentId;
  final String studentName;
  final String routeId;
  final String routeName;
  final String stoppageId;
  final String stoppageName;

  const TransportAssignment({
    required this.studentId,
    required this.studentName,
    required this.routeId,
    required this.routeName,
    required this.stoppageId,
    required this.stoppageName,
  });

  factory TransportAssignment.fromJson(Map<String, dynamic> json) =>
      TransportAssignment(
        studentId: json['studentId']?.toString() ?? '',
        studentName: json['studentName']?.toString() ?? '',
        routeId: json['routeId']?.toString() ?? '',
        routeName: json['routeName']?.toString() ?? '',
        stoppageId: json['stoppageId']?.toString() ?? '',
        stoppageName: json['stoppageName']?.toString() ?? '',
      );
}

class TransportRebate {
  final String id;
  final String studentName;
  final double amount;
  final String reason;

  const TransportRebate({
    required this.id,
    required this.studentName,
    required this.amount,
    required this.reason,
  });

  factory TransportRebate.fromJson(Map<String, dynamic> json) =>
      TransportRebate(
        id: json['id']?.toString() ?? '',
        studentName: json['studentName']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        reason: json['reason']?.toString() ?? '',
      );
}
