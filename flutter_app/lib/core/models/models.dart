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
  final String? imageUrl;
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

// Continued in next commit: OrderItem, Order, InventoryItem, DeviceInfo, LicenseInfo, AppSettings
