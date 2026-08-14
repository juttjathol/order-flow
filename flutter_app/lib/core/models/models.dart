import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Roles a device can operate in
enum DeviceRole { main, orderTaker, kitchen, cashier }

/// Order lifecycle
enum OrderStatus { open, preparing, ready, served, paid, cancelled }

/// Simple money representation in smallest currency unit (cents / paisa)
class Money extends Equatable {
  final int amount; // in minor units
  final String currency;

  const Money(this.amount, {this.currency = 'USD'});

  double get asDouble => amount / 100.0;

  Money operator +(Money other) => Money(amount + other.amount, currency: currency);
  Money operator -(Money other) => Money(amount - other.amount, currency: currency);

  @override
  List<Object?> get props => [amount, currency];

  Map<String, dynamic> toJson() => {'amount': amount, 'currency': currency};
  factory Money.fromJson(Map<String, dynamic> j) =>
      Money(j['amount'] as int, currency: j['currency'] as String? ?? 'USD');
}

class MenuCategory extends Equatable {
  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;

  MenuCategory({
    String? id,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  factory MenuCategory.fromJson(Map<String, dynamic> j) => MenuCategory(
        id: j['id'] as String,
        name: j['name'] as String,
        sortOrder: j['sortOrder'] as int? ?? 0,
        isActive: j['isActive'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, name, sortOrder, isActive];
}

class MenuModifier extends Equatable {
  final String id;
  final String name;
  final Money priceDelta;
  final bool isDefault;

  MenuModifier({
    String? id,
    required this.name,
    required this.priceDelta,
    this.isDefault = false,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priceDelta': priceDelta.toJson(),
        'isDefault': isDefault,
      };

  factory MenuModifier.fromJson(Map<String, dynamic> j) => MenuModifier(
        id: j['id'] as String,
        name: j['name'] as String,
        priceDelta: Money.fromJson(j['priceDelta'] as Map<String, dynamic>),
        isDefault: j['isDefault'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, name, priceDelta, isDefault];
}

class MenuItem extends Equatable {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final Money price;
  final bool isAvailable;
  final List<MenuModifier> modifiers;
  final String? imageUrl; // local path or null
  final int sortOrder;

  MenuItem({
    String? id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.isAvailable = true,
    this.modifiers = const [],
    this.imageUrl,
    this.sortOrder = 0,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'price': price.toJson(),
        'isAvailable': isAvailable,
        'modifiers': modifiers.map((m) => m.toJson()).toList(),
        'imageUrl': imageUrl,
        'sortOrder': sortOrder,
      };

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'] as String,
        categoryId: j['categoryId'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        price: Money.fromJson(j['price'] as Map<String, dynamic>),
        isAvailable: j['isAvailable'] as bool? ?? true,
        modifiers: (j['modifiers'] as List<dynamic>? ?? [])
            .map((m) => MenuModifier.fromJson(m as Map<String, dynamic>))
            .toList(),
        imageUrl: j['imageUrl'] as String?,
        sortOrder: j['sortOrder'] as int? ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, categoryId, name, description, price, isAvailable, modifiers, sortOrder];
}

class OrderItem extends Equatable {
  final String id;
  final String menuItemId;
  final String nameSnapshot;
  final Money unitPrice;
  final int quantity;
  final List<MenuModifier> selectedModifiers;
  final String? notes;
  final bool isKitchenPrinted;

  OrderItem({
    String? id,
    required this.menuItemId,
    required this.nameSnapshot,
    required this.unitPrice,
    this.quantity = 1,
    this.selectedModifiers = const [],
    this.notes,
    this.isKitchenPrinted = false,
  }) : id = id ?? _uuid.v4();

  Money get lineTotal {
    final modExtra = selectedModifiers.fold<Money>(
        const Money(0), (prev, m) => prev + m.priceDelta);
    return Money((unitPrice.amount + modExtra.amount) * quantity,
        currency: unitPrice.currency);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'menuItemId': menuItemId,
        'nameSnapshot': nameSnapshot,
        'unitPrice': unitPrice.toJson(),
        'quantity': quantity,
        'selectedModifiers': selectedModifiers.map((m) => m.toJson()).toList(),
        'notes': notes,
        'isKitchenPrinted': isKitchenPrinted,
      };

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'] as String,
        menuItemId: j['menuItemId'] as String,
        nameSnapshot: j['nameSnapshot'] as String,
        unitPrice: Money.fromJson(j['unitPrice'] as Map<String, dynamic>),
        quantity: j['quantity'] as int? ?? 1,
        selectedModifiers: (j['selectedModifiers'] as List<dynamic>? ?? [])
            .map((m) => MenuModifier.fromJson(m as Map<String, dynamic>))
            .toList(),
        notes: j['notes'] as String?,
        isKitchenPrinted: j['isKitchenPrinted'] as bool? ?? false,
      );

  OrderItem copyWith({
    int? quantity,
    List<MenuModifier>? selectedModifiers,
    String? notes,
    bool? isKitchenPrinted,
  }) =>
      OrderItem(
        id: id,
        menuItemId: menuItemId,
        nameSnapshot: nameSnapshot,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        selectedModifiers: selectedModifiers ?? this.selectedModifiers,
        notes: notes ?? this.notes,
        isKitchenPrinted: isKitchenPrinted ?? this.isKitchenPrinted,
      );

  @override
  List<Object?> get props =>
      [id, menuItemId, nameSnapshot, unitPrice, quantity, selectedModifiers, notes];
}

class Order extends Equatable {
  final String id;
  final String orderNumber; // human friendly sequential or daily
  final String? tableNumber;
  final String? ticketNumber; // custom ticket if no table
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdByDeviceId;
  final String? notes;
  final Money? discount;
  final Money? tax;
  final Money? serviceCharge;
  final bool isPaid;
  final DateTime? paidAt;

  Order({
    String? id,
    required this.orderNumber,
    this.tableNumber,
    this.ticketNumber,
    this.items = const [],
    this.status = OrderStatus.open,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.createdByDeviceId,
    this.notes,
    this.discount,
    this.tax,
    this.serviceCharge,
    this.isPaid = false,
    this.paidAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  Money get subtotal =>
      items.fold(const Money(0), (prev, i) => prev + i.lineTotal);

  Money get total {
    var t = subtotal;
    if (discount != null) t = t - discount!;
    if (tax != null) t = t + tax!;
    if (serviceCharge != null) t = t + serviceCharge!;
    return t;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'tableNumber': tableNumber,
        'ticketNumber': ticketNumber,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdByDeviceId': createdByDeviceId,
        'notes': notes,
        'discount': discount?.toJson(),
        'tax': tax?.toJson(),
        'serviceCharge': serviceCharge?.toJson(),
        'isPaid': isPaid,
        'paidAt': paidAt?.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String,
        orderNumber: j['orderNumber'] as String,
        tableNumber: j['tableNumber'] as String?,
        ticketNumber: j['ticketNumber'] as String?,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        status: OrderStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => OrderStatus.open,
        ),
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        createdByDeviceId: j['createdByDeviceId'] as String,
        notes: j['notes'] as String?,
        discount: j['discount'] != null
            ? Money.fromJson(j['discount'] as Map<String, dynamic>)
            : null,
        tax: j['tax'] != null
            ? Money.fromJson(j['tax'] as Map<String, dynamic>)
            : null,
        serviceCharge: j['serviceCharge'] != null
            ? Money.fromJson(j['serviceCharge'] as Map<String, dynamic>)
            : null,
        isPaid: j['isPaid'] as bool? ?? false,
        paidAt: j['paidAt'] != null
            ? DateTime.parse(j['paidAt'] as String)
            : null,
      );

  Order copyWith({
    List<OrderItem>? items,
    OrderStatus? status,
    String? notes,
    Money? discount,
    Money? tax,
    Money? serviceCharge,
    bool? isPaid,
    DateTime? paidAt,
    DateTime? updatedAt,
  }) =>
      Order(
        id: id,
        orderNumber: orderNumber,
        tableNumber: tableNumber,
        ticketNumber: ticketNumber,
        items: items ?? this.items,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
        createdByDeviceId: createdByDeviceId,
        notes: notes ?? this.notes,
        discount: discount ?? this.discount,
        tax: tax ?? this.tax,
        serviceCharge: serviceCharge ?? this.serviceCharge,
        isPaid: isPaid ?? this.isPaid,
        paidAt: paidAt ?? this.paidAt,
      );

  @override
  List<Object?> get props =>
      [id, orderNumber, tableNumber, items, status, isPaid];
}

class InventoryItem extends Equatable {
  final String id;
  final String name;
  final String unit; // pcs, kg, liter...
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
