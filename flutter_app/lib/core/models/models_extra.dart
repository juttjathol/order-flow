import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

const _uuid = Uuid();

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

  Map<String, dynamic> toJson() => {
        'key': key,
        'customerId': customerId,
        'customerName': customerName,
        'expiresAt': expiresAt.toIso8601String(),
        'isActive': isActive,
        'lastValidatedAt': lastValidatedAt?.toIso8601String(),
      };

  factory LicenseInfo.fromJson(Map<String, dynamic> j) => LicenseInfo(
        key: j['key'] as String? ?? '',
        customerId: j['customerId'] as String? ?? '',
        customerName: j['customerName'] as String? ?? '',
        expiresAt: DateTime.tryParse('${j['expiresAt']}') ??
            DateTime.now().add(const Duration(days: 30)),
        isActive: j['isActive'] as bool? ?? true,
        lastValidatedAt: j['lastValidatedAt'] != null
            ? DateTime.tryParse('${j['lastValidatedAt']}')
            : null,
      );

  @override
  List<Object?> get props => [key, customerId, expiresAt, isActive];
}

class DeviceInfo extends Equatable {
  final String id;
  final String name;
  final DeviceRole role;
  final String? ip;
  final bool isOnline;
  final DateTime? lastSeen;

  DeviceInfo({
    String? id,
    required this.name,
    required this.role,
    this.ip,
    this.isOnline = false,
    this.lastSeen,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'ip': ip,
        'isOnline': isOnline,
        'lastSeen': lastSeen?.toIso8601String(),
      };

  factory DeviceInfo.fromJson(Map<String, dynamic> j) => DeviceInfo(
        id: j['id'] as String?,
        name: j['name'] as String? ?? 'Device',
        role: DeviceRole.values.firstWhere(
          (r) => r.name == j['role'],
          orElse: () => DeviceRole.orderTaker,
        ),
        ip: j['ip'] as String?,
        isOnline: j['isOnline'] as bool? ?? false,
        lastSeen: j['lastSeen'] != null
            ? DateTime.tryParse('${j['lastSeen']}')
            : null,
      );

  @override
  List<Object?> get props => [id, name, role, ip, isOnline];
}

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
        id: j['id'] as String?,
        name: j['name'] as String? ?? '',
        unit: j['unit'] as String? ?? 'pcs',
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        lowStockThreshold: (j['lowStockThreshold'] as num?)?.toDouble() ?? 5,
        linkedMenuItemId: j['linkedMenuItemId'] as String?,
      );

  @override
  List<Object?> get props => [id, name, unit, quantity, lowStockThreshold];
}
