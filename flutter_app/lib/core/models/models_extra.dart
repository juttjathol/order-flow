import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

const _uuid = Uuid();

class InventoryItem extends Equatable {
  final String id;
  final String name;
  final String unit;
  final double quantity;
  final double lowStockThreshold;
  final String? linkedMenuItemId;

  InventoryItem({
    String? id,
    required this.name,
    this.unit = 'pcs',
    this.quantity = 0,
    this.lowStockThreshold = 5,
    this.linkedMenuItemId,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'quantity': quantity,
        'lowStockThreshold': lowStockThreshold,
        'linkedMenuItemId': linkedMenuItemId,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
        id: j['id'] as String,
        name: j['name'] as String,
        unit: j['unit'] as String? ?? 'pcs',
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        lowStockThreshold: (j['lowStockThreshold'] as num?)?.toDouble() ?? 5,
        linkedMenuItemId: j['linkedMenuItemId'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, name, unit, quantity, lowStockThreshold, linkedMenuItemId];
}

class DeviceInfo extends Equatable {
  final String id;
  final String name;
  final DeviceRole role;
  final String? ip;
  final DateTime lastSeen;
  final bool isOnline;

  DeviceInfo({
    String? id,
    required this.name,
    required this.role,
    this.ip,
    DateTime? lastSeen,
    this.isOnline = true,
  })  : id = id ?? _uuid.v4(),
        lastSeen = lastSeen ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'ip': ip,
        'lastSeen': lastSeen.toIso8601String(),
        'isOnline': isOnline,
      };

  factory DeviceInfo.fromJson(Map<String, dynamic> j) => DeviceInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        role: DeviceRole.values.firstWhere(
          (e) => e.name == j['role'],
          orElse: () => DeviceRole.orderTaker,
        ),
        ip: j['ip'] as String?,
        lastSeen: DateTime.parse(j['lastSeen'] as String),
        isOnline: j['isOnline'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, name, role, ip, isOnline];
}

class LicenseInfo extends Equatable {
  final String key;
  final String customerId;
  final String customerName;
  final DateTime expiresAt;
  final bool isActive;
  final DateTime? lastValidatedAt;

  const LicenseInfo({
    required this.key,
    required this.customerId,
    required this.customerName,
    required this.expiresAt,
    this.isActive = true,
    this.lastValidatedAt,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'key': key,
        'customerId': customerId,
        'customerName': customerName,
        'expiresAt': expiresAt.toIso8601String(),
        'isActive': isActive,
        'lastValidatedAt': lastValidatedAt?.toIso8601String(),
      };

  factory LicenseInfo.fromJson(Map<String, dynamic> j) => LicenseInfo(
        key: j['key'] as String,
        customerId: j['customerId'] as String,
        customerName: j['customerName'] as String,
        expiresAt: DateTime.parse(j['expiresAt'] as String),
        isActive: j['isActive'] as bool? ?? true,
        lastValidatedAt: j['lastValidatedAt'] != null
            ? DateTime.parse(j['lastValidatedAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [key, customerId, expiresAt, isActive];
}

class AppSettings extends Equatable {
  final String restaurantName;
  final String currency;
  final double taxPercent;
  final double serviceChargePercent;
  final int nextOrderNumber;
  final String? kitchenPrinterIp;
  final String? cashierPrinterIp;
  final bool autoDeductInventory;
  final int offlineGraceDays;

  const AppSettings({
    this.restaurantName = 'My Restaurant',
    this.currency = 'USD',
    this.taxPercent = 0,
    this.serviceChargePercent = 0,
    this.nextOrderNumber = 1,
    this.kitchenPrinterIp,
    this.cashierPrinterIp,
    this.autoDeductInventory = true,
    this.offlineGraceDays = 45,
  });

  Map<String, dynamic> toJson() => {
        'restaurantName': restaurantName,
        'currency': currency,
        'taxPercent': taxPercent,
        'serviceChargePercent': serviceChargePercent,
        'nextOrderNumber': nextOrderNumber,
        'kitchenPrinterIp': kitchenPrinterIp,
        'cashierPrinterIp': cashierPrinterIp,
        'autoDeductInventory': autoDeductInventory,
        'offlineGraceDays': offlineGraceDays,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        restaurantName: j['restaurantName'] as String? ?? 'My Restaurant',
        currency: j['currency'] as String? ?? 'USD',
        taxPercent: (j['taxPercent'] as num?)?.toDouble() ?? 0,
        serviceChargePercent:
            (j['serviceChargePercent'] as num?)?.toDouble() ?? 0,
        nextOrderNumber: j['nextOrderNumber'] as int? ?? 1,
        kitchenPrinterIp: j['kitchenPrinterIp'] as String?,
        cashierPrinterIp: j['cashierPrinterIp'] as String?,
        autoDeductInventory: j['autoDeductInventory'] as bool? ?? true,
        offlineGraceDays: j['offlineGraceDays'] as int? ?? 45,
      );

  AppSettings copyWith({
    String? restaurantName,
    String? currency,
    double? taxPercent,
    double? serviceChargePercent,
    int? nextOrderNumber,
    String? kitchenPrinterIp,
    String? cashierPrinterIp,
    bool? autoDeductInventory,
    int? offlineGraceDays,
  }) =>
      AppSettings(
        restaurantName: restaurantName ?? this.restaurantName,
        currency: currency ?? this.currency,
        taxPercent: taxPercent ?? this.taxPercent,
        serviceChargePercent: serviceChargePercent ?? this.serviceChargePercent,
        nextOrderNumber: nextOrderNumber ?? this.nextOrderNumber,
        kitchenPrinterIp: kitchenPrinterIp ?? this.kitchenPrinterIp,
        cashierPrinterIp: cashierPrinterIp ?? this.cashierPrinterIp,
        autoDeductInventory: autoDeductInventory ?? this.autoDeductInventory,
        offlineGraceDays: offlineGraceDays ?? this.offlineGraceDays,
      );

  @override
  List<Object?> get props => [
        restaurantName,
        currency,
        taxPercent,
        nextOrderNumber,
        kitchenPrinterIp,
        autoDeductInventory
      ];
}
