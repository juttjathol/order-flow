import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum DeviceRole { main, orderTaker, kitchen, cashier }
enum OrderStatus { open, preparing, ready, served, paid, cancelled }

class Money extends Equatable {
  final int amount;
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
  MenuCategory({String? id, required this.name, this.sortOrder = 0, this.isActive = true})
      : id = id ?? _uuid.v4();
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'sortOrder': sortOrder, 'isActive': isActive};
  factory MenuCategory.fromJson(Map<String, dynamic> j) => MenuCategory(
        id: j['id'] as String, name: j['name'] as String,
        sortOrder: j['sortOrder'] as int? ?? 0, isActive: j['isActive'] as bool? ?? true);
  @override
  List<Object?> get props => [id, name, sortOrder, isActive];
}

class MenuModifier extends Equatable {
  final String id;
  final String name;
  final Money priceDelta;
  final bool isDefault;
  MenuModifier({String? id, required this.name, required this.priceDelta, this.isDefault = false})
      : id = id ?? _uuid.v4();
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'priceDelta': priceDelta.toJson(), 'isDefault': isDefault};
  factory MenuModifier.fromJson(Map<String, dynamic> j) => MenuModifier(
        id: j['id'] as String, name: j['name'] as String,
        priceDelta: Money.fromJson(j['priceDelta'] as Map<String, dynamic>),
        isDefault: j['isDefault'] as bool? ?? false);
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
  final String? imageUrl;
  final int sortOrder;
  MenuItem({String? id, required this.categoryId, required this.name, this.description,
      required this.price, this.isAvailable = true, this.modifiers = const [], this.imageUrl, this.sortOrder = 0})
      : id = id ?? _uuid.v4();
  Map<String, dynamic> toJson() => {
        'id': id, 'categoryId': categoryId, 'name': name, 'description': description,
        'price': price.toJson(), 'isAvailable': isAvailable,
        'modifiers': modifiers.map((m) => m.toJson()).toList(), 'imageUrl': imageUrl, 'sortOrder': sortOrder};
  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'] as String, categoryId: j['categoryId'] as String, name: j['name'] as String,
        description: j['description'] as String?, price: Money.fromJson(j['price'] as Map<String, dynamic>),
        isAvailable: j['isAvailable'] as bool? ?? true,
        modifiers: (j['modifiers'] as List<dynamic>? ?? []).map((m) => MenuModifier.fromJson(m as Map<String, dynamic>)).toList(),
        imageUrl: j['imageUrl'] as String?, sortOrder: j['sortOrder'] as int? ?? 0);
  @override
  List<Object?> get props => [id, categoryId, name, description, price, isAvailable, modifiers, sortOrder];
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
  OrderItem({String? id, required this.menuItemId, required this.nameSnapshot, required this.unitPrice,
      this.quantity = 1, this.selectedModifiers = const [], this.notes, this.isKitchenPrinted = false})
      : id = id ?? _uuid.v4();
  Money get lineTotal {
    final modExtra = selectedModifiers.fold<Money>(const Money(0), (prev, m) => prev + m.priceDelta);
    return Money((unitPrice.amount + modExtra.amount) * quantity, currency: unitPrice.currency);
  }
  Map<String, dynamic> toJson() => {
        'id': id, 'menuItemId': menuItemId, 'nameSnapshot': nameSnapshot, 'unitPrice': unitPrice.toJson(),
        'quantity': quantity, 'selectedModifiers': selectedModifiers.map((m) => m.toJson()).toList(),
        'notes': notes, 'isKitchenPrinted': isKitchenPrinted};
  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'] as String, menuItemId: j['menuItemId'] as String, nameSnapshot: j['nameSnapshot'] as String,
        unitPrice: Money.fromJson(j['unitPrice'] as Map<String, dynamic>), quantity: j['quantity'] as int? ?? 1,
        selectedModifiers: (j['selectedModifiers'] as List<dynamic>? ?? []).map((m) => MenuModifier.fromJson(m as Map<String, dynamic>)).toList(),
        notes: j['notes'] as String?, isKitchenPrinted: j['isKitchenPrinted'] as bool? ?? false);
  OrderItem copyWith({int? quantity, List<MenuModifier>? selectedModifiers, String? notes, bool? isKitchenPrinted}) =>
      OrderItem(id: id, menuItemId: menuItemId, nameSnapshot: nameSnapshot, unitPrice: unitPrice,
          quantity: quantity ?? this.quantity, selectedModifiers: selectedModifiers ?? this.selectedModifiers,
          notes: notes ?? this.notes, isKitchenPrinted: isKitchenPrinted ?? this.isKitchenPrinted);
  @override
  List<Object?> get props => [id, menuItemId, nameSnapshot, unitPrice, quantity, selectedModifiers, notes];
}

class Order extends Equatable {
  final String id;
  final String orderNumber;
  final String? tableNumber;
  final String? ticketNumber;
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
  Order({String? id, required this.orderNumber, this.tableNumber, this.ticketNumber, this.items = const [],
      this.status = OrderStatus.open, DateTime? createdAt, DateTime? updatedAt, required this.createdByDeviceId,
      this.notes, this.discount, this.tax, this.serviceCharge, this.isPaid = false, this.paidAt})
      : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();
  Money get subtotal => items.fold(const Money(0), (prev, i) => prev + i.lineTotal);
  Money get total {
    var t = subtotal;
    if (discount != null) t = t - discount!;
    if (tax != null) t = t + tax!;
    if (serviceCharge != null) t = t + serviceCharge!;
    return t;
  }
  Map<String, dynamic> toJson() => {
        'id': id, 'orderNumber': orderNumber, 'tableNumber': tableNumber, 'ticketNumber': ticketNumber,
        'items': items.map((i) => i.toJson()).toList(), 'status': status.name,
        'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(),
        'createdByDeviceId': createdByDeviceId, 'notes': notes, 'discount': discount?.toJson(),
        'tax': tax?.toJson(), 'serviceCharge': serviceCharge?.toJson(), 'isPaid': isPaid,
        'paidAt': paidAt?.toIso8601String()};
  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String, orderNumber: j['orderNumber'] as String,
        tableNumber: j['tableNumber'] as String?, ticketNumber: j['ticketNumber'] as String?,
        items: (j['items'] as List<dynamic>? ?? []).map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList(),
        status: OrderStatus.values.firstWhere((e) => e.name == j['status'], orElse: () => OrderStatus.open),
        createdAt: DateTime.parse(j['createdAt'] as String), updatedAt: DateTime.parse(j['updatedAt'] as String),
        createdByDeviceId: j['createdByDeviceId'] as String, notes: j['notes'] as String?,
        discount: j['discount'] != null ? Money.fromJson(j['discount'] as Map<String, dynamic>) : null,
        tax: j['tax'] != null ? Money.fromJson(j['tax'] as Map<String, dynamic>) : null,
        serviceCharge: j['serviceCharge'] != null ? Money.fromJson(j['serviceCharge'] as Map<String, dynamic>) : null,
        isPaid: j['isPaid'] as bool? ?? false,
        paidAt: j['paidAt'] != null ? DateTime.parse(j['paidAt'] as String) : null);
  Order copyWith({List<OrderItem>? items, OrderStatus? status, String? notes, Money? discount, Money? tax,
      Money? serviceCharge, bool? isPaid, DateTime? paidAt, DateTime? updatedAt}) =>
      Order(id: id, orderNumber: orderNumber, tableNumber: tableNumber, ticketNumber: ticketNumber,
          items: items ?? this.items, status: status ?? this.status, createdAt: createdAt,
          updatedAt: updatedAt ?? DateTime.now().toUtc(), createdByDeviceId: createdByDeviceId,
          notes: notes ?? this.notes, discount: discount ?? this.discount, tax: tax ?? this.tax,
          serviceCharge: serviceCharge ?? this.serviceCharge, isPaid: isPaid ?? this.isPaid, paidAt: paidAt ?? this.paidAt);
  @override
  List<Object?> get props => [id, orderNumber, tableNumber, items, status, isPaid];
}

// See also models_extra.dart for InventoryItem, DeviceInfo, LicenseInfo, AppSettings
