import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';
import '../models/models_extra.dart';
import '../network/local_server.dart';

const _uuid = Uuid();

class AppController extends ChangeNotifier {
  static const licenseApiBase = 'https://order-flow-1ib.pages.dev';
  bool isMain = false, serverRunning = false, clientConnected = false;
  String? localIp, connectedHost, licenseMessage;
  int port = 8787, _orderSeq = 1;
  String deviceId = _uuid.v4(), deviceName = 'Device';
  DeviceRole role = DeviceRole.orderTaker;
  List<MenuCategory> categories = [];
  List<MenuItem> menuItems = [];
  List<Order> orders = [];
  List<InventoryItem> inventory = [];
  List<DeviceInfo> devices = [];
  LicenseInfo? license;
  LocalServer? _server;
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;

  String get joinUrl => 'http://${localIp ?? '0.0.0.0'}:$port';
  List<Order> get openOrders => orders.where((o) => !o.isPaid && o.status != OrderStatus.cancelled).toList();
  List<Order> get kitchenOrders => openOrders.where((o) => o.status == OrderStatus.open || o.status == OrderStatus.preparing || o.status == OrderStatus.ready).toList();
  double get todaySales {
    final t = DateTime.now().toUtc();
    return orders.where((o) => o.isPaid && o.paidAt != null && o.paidAt!.year == t.year && o.paidAt!.month == t.month && o.paidAt!.day == t.day).fold<double>(0, (s, o) => s + o.total.asDouble);
  }

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    deviceId = p.getString('device_id') ?? deviceId;
    await p.setString('device_id', deviceId);
    deviceName = p.getString('device_name') ?? 'Tablet-${deviceId.substring(0, 4)}';
    final k = p.getString('license_key');
    if (k != null) {
      license = LicenseInfo(key: k, customerId: p.getString('license_customer_id') ?? '', customerName: p.getString('license_customer_name') ?? '', expiresAt: DateTime.tryParse(p.getString('license_expires') ?? '') ?? DateTime.now().add(const Duration(days: 30)), isActive: true);
    }
    _seed();
    notifyListeners();
  }

  void _seed() {
    if (categories.isNotEmpty) return;
    final mains = MenuCategory(name: 'Mains', sortOrder: 1);
    final drinks = MenuCategory(name: 'Drinks', sortOrder: 2);
    final sides = MenuCategory(name: 'Sides', sortOrder: 3);
    final desserts = MenuCategory(name: 'Desserts', sortOrder: 4);
    categories = [mains, drinks, sides, desserts];
    menuItems = [
      MenuItem(categoryId: mains.id, name: 'Grilled Chicken', price: const Money(1250)),
      MenuItem(categoryId: mains.id, name: 'Beef Burger', price: const Money(1100)),
      MenuItem(categoryId: mains.id, name: 'Pasta Alfredo', price: const Money(1050)),
      MenuItem(categoryId: drinks.id, name: 'Fresh Juice', price: const Money(350)),
      MenuItem(categoryId: drinks.id, name: 'Cola', price: const Money(200)),
      MenuItem(categoryId: sides.id, name: 'Fries', price: const Money(300)),
      MenuItem(categoryId: sides.id, name: 'Salad', price: const Money(450)),
      MenuItem(categoryId: desserts.id, name: 'Cheesecake', price: const Money(550)),
    ];
    inventory = menuItems.map((m) => InventoryItem(name: m.name, quantity: 100, lowStockThreshold: 10, linkedMenuItemId: m.id)).toList();
  }

  Future<String?> _ip() async {
    try {
      for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4, includeLinkLocal: false)) {
        for (final a in i.addresses) {
          if (!a.isLoopback) return a.address;
        }
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> fullState() => {
    'categories': categories.map((c) => c.toJson()).toList(),
    'menuItems': menuItems.map((m) => m.toJson()).toList(),
    'orders': orders.map((o) => o.toJson()).toList(),
    'inventory': inventory.map((i) => i.toJson()).toList(),
    'orderSeq': _orderSeq,
    'devices': devices.map((d) => d.toJson()).toList(),
  };

  void applyState(Map<String, dynamic> s) {
    categories = (s['categories'] as List? ?? []).map((e) => MenuCategory.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    menuItems = (s['menuItems'] as List? ?? []).map((e) => MenuItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    orders = (s['orders'] as List? ?? []).map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    inventory = (s['inventory'] as List? ?? []).map((e) => InventoryItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    _orderSeq = s['orderSeq'] as int? ?? _orderSeq;
    notifyListeners();
  }

  Future<void> startAsMain() async {
    isMain = true; role = DeviceRole.main;
    localIp = await _ip() ?? '127.0.0.1';
    _server = LocalServer(port: port, getFullState: () async => fullState(), onClientEvent: _onEvent);
    await _server!.start();
    serverRunning = true;
    devices = [DeviceInfo(id: deviceId, name: deviceName, role: DeviceRole.main, ip: localIp, isOnline: true)];
    notifyListeners();
  }

  Future<void> stopMain() async {
    await _server?.stop(); _server = null; serverRunning = false; notifyListeners();
  }

  Future<void> _onEvent(String type, Map<String, dynamic> payload, String did) async {
    if (type == 'order.create') {
      final order = Order.fromJson(payload);
      orders = [...orders, order];
      _orderSeq++;
      _deduct(order);
      _server?.broadcast('order.upsert', order.toJson());
    } else if (type == 'order.update') {
      final order = Order.fromJson(payload);
      orders = orders.map((o) => o.id == order.id ? order : o).toList();
      _server?.broadcast('order.upsert', order.toJson());
    }
    notifyListeners();
  }

  void _deduct(Order order) {
    for (final line in order.items) {
      inventory = inventory.map((inv) {
        if (inv.linkedMenuItemId == line.menuItemId) {
          return InventoryItem(id: inv.id, name: inv.name, unit: inv.unit, quantity: (inv.quantity - line.quantity).clamp(0, 1e9), lowStockThreshold: inv.lowStockThreshold, linkedMenuItemId: inv.linkedMenuItemId);
        }
        return inv;
      }).toList();
    }
    _server?.broadcast('state.replace', fullState());
  }

  Future<bool> connectToMain(String host, {DeviceRole asRole = DeviceRole.orderTaker}) async {
    try {
      final base = host.startsWith('http') ? host : 'http://$host';
      final uri = Uri.parse(base.contains(':') ? base : '$base:$port');
      final health = await http.get(Uri.parse('${uri.scheme}://${uri.host}:${uri.port}/health')).timeout(const Duration(seconds: 4));
      if (health.statusCode != 200) return false;
      final st = await http.get(Uri.parse('${uri.scheme}://${uri.host}:${uri.port}/state')).timeout(const Duration(seconds: 6));
      if (st.statusCode == 200) applyState(jsonDecode(st.body) as Map<String, dynamic>);
      final wsUrl = Uri.parse('${uri.scheme == 'https' ? 'wss' : 'ws'}://${uri.host}:${uri.port}/ws');
      await _wsSub?.cancel(); await _ws?.sink.close();
      _ws = WebSocketChannel.connect(wsUrl);
      _wsSub = _ws!.stream.listen((msg) {
        try {
          final data = jsonDecode(msg as String) as Map<String, dynamic>;
          final type = data['type'] as String? ?? '';
          final payload = Map<String, dynamic>.from(data['payload'] as Map? ?? {});
          if (type == 'order.upsert') {
            final order = Order.fromJson(payload);
            final idx = orders.indexWhere((o) => o.id == order.id);
            orders = idx >= 0 ? ([...orders]..[idx] = order) : [...orders, order];
            notifyListeners();
          } else if (type == 'state.replace') {
            applyState(payload);
          }
        } catch (_) {}
      }, onDone: () { clientConnected = false; notifyListeners(); });
      _ws!.sink.add(jsonEncode({'type': 'identify', 'deviceId': deviceId, 'payload': DeviceInfo(id: deviceId, name: deviceName, role: asRole, isOnline: true).toJson()}));
      isMain = false; role = asRole; connectedHost = '${uri.host}:${uri.port}'; clientConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      licenseMessage = 'Connect failed: $e';
      notifyListeners();
      return false;
    }
  }

  void _send(String type, Map<String, dynamic> payload) {
    if (!isMain) _ws?.sink.add(jsonEncode({'type': type, 'deviceId': deviceId, 'payload': payload}));
  }

  Order createOrder({required String? tableNumber, required String? ticketNumber, required List<OrderItem> items}) {
    final order = Order(orderNumber: '$_orderSeq', tableNumber: tableNumber, ticketNumber: ticketNumber, items: items, status: OrderStatus.open, createdByDeviceId: deviceId);
    _orderSeq++;
    orders = [...orders, order];
    if (isMain) { _deduct(order); _server?.broadcast('order.upsert', order.toJson()); }
    else { _send('order.create', order.toJson()); }
    notifyListeners();
    return order;
  }

  void updateOrderStatus(String id, OrderStatus status) {
    orders = orders.map((o) => o.id == id ? o.copyWith(status: status) : o).toList();
    final order = orders.firstWhere((o) => o.id == id);
    if (isMain) _server?.broadcast('order.upsert', order.toJson()); else _send('order.update', order.toJson());
    notifyListeners();
  }

  void markPaid(String id) {
    orders = orders.map((o) => o.id == id ? o.copyWith(isPaid: true, status: OrderStatus.paid, paidAt: DateTime.now().toUtc()) : o).toList();
    final order = orders.firstWhere((o) => o.id == id);
    if (isMain) _server?.broadcast('order.upsert', order.toJson()); else _send('order.update', order.toJson());
    notifyListeners();
  }

  void upsertMenuItem(MenuItem item) {
    if (!isMain) return;
    final idx = menuItems.indexWhere((m) => m.id == item.id);
    if (idx >= 0) menuItems = [...menuItems]..[idx] = item;
    else {
      menuItems = [...menuItems, item];
      inventory = [...inventory, InventoryItem(name: item.name, quantity: 50, linkedMenuItemId: item.id)];
    }
    _server?.broadcast('state.replace', fullState());
    notifyListeners();
  }

  void deleteMenuItem(String id) {
    if (!isMain) return;
    menuItems = menuItems.where((m) => m.id != id).toList();
    _server?.broadcast('state.replace', fullState());
    notifyListeners();
  }

  void upsertCategory(MenuCategory cat) {
    if (!isMain) return;
    final idx = categories.indexWhere((c) => c.id == cat.id);
    if (idx >= 0) categories = [...categories]..[idx] = cat; else categories = [...categories, cat];
    _server?.broadcast('state.replace', fullState());
    notifyListeners();
  }

  void setInventoryQty(String id, double qty) {
    if (!isMain) return;
    inventory = inventory.map((i) => i.id != id ? i : InventoryItem(id: i.id, name: i.name, unit: i.unit, quantity: qty, lowStockThreshold: i.lowStockThreshold, linkedMenuItemId: i.linkedMenuItemId)).toList();
    _server?.broadcast('state.replace', fullState());
    notifyListeners();
  }

  Future<bool> activateLicense(String key) async {
    licenseMessage = null; notifyListeners();
    try {
      final res = await http.post(Uri.parse('$licenseApiBase/api/v1/license/validate'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'licenseKey': key.trim(), 'deviceId': deviceId})).timeout(const Duration(seconds: 12));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final p = await SharedPreferences.getInstance();
      await p.setString('license_key', key.trim());
      if (res.statusCode != 200 || data['valid'] != true) {
        licenseMessage = data['error']?.toString() ?? 'Invalid license';
        license = LicenseInfo(key: key.trim(), customerId: '', customerName: 'Pending', expiresAt: DateTime.now().add(const Duration(days: 7)), isActive: true);
        notifyListeners();
        return false;
      }
      license = LicenseInfo(key: key.trim(), customerId: '${data['customerId'] ?? ''}', customerName: '${data['customerName'] ?? ''}', expiresAt: DateTime.tryParse('${data['expiresAt']}') ?? DateTime.now().add(const Duration(days: 30)), isActive: true, lastValidatedAt: DateTime.now().toUtc());
      await p.setString('license_customer_id', license!.customerId);
      await p.setString('license_customer_name', license!.customerName);
      await p.setString('license_expires', license!.expiresAt.toIso8601String());
      licenseMessage = 'License active until ${license!.expiresAt.toLocal().toString().split(' ').first}';
      notifyListeners();
      return true;
    } catch (e) {
      final p = await SharedPreferences.getInstance();
      await p.setString('license_key', key.trim());
      license = LicenseInfo(key: key.trim(), customerId: '', customerName: 'Offline grace', expiresAt: DateTime.now().add(const Duration(days: 14)), isActive: true);
      licenseMessage = 'Saved offline with grace period.';
      notifyListeners();
      return true;
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel(); _ws?.sink.close(); _server?.stop();
    super.dispose();
  }
}

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) => AppController());
