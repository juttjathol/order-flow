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
import '../services/print_service.dart';

const _uuid = Uuid();

class AppController extends ChangeNotifier {
  static const licenseApiBase = 'https://order-flow-1ib.pages.dev';
  bool isMain = false, serverRunning = false, clientConnected = false;
  String? localIp, connectedHost, licenseMessage;
  int port = 8787, _orderSeq = 1;
  String deviceId = _uuid.v4(), deviceName = 'Device';
  DeviceRole role = DeviceRole.orderTaker;
  BillProfile bill = const BillProfile();
  String? kitchenPrinterIp, cashierPrinterIp;
  List<MenuCategory> categories = [];
  List<MenuItem> menuItems = [];
  List<Order> orders = [];
  List<InventoryItem> inventory = [];
  List<DeviceInfo> devices = [];
  LicenseInfo? license;
  String localeCode = 'en';
  bool get hasLicense => license != null;
  LocalServer? _server;
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;
  Timer? _persistDebounce;

  String get joinUrl => 'http://${localIp ?? '0.0.0.0'}:$port';
  String get restaurantName => bill.restaurantName;
  List<Order> get openOrders => orders.where((o) => !o.isPaid && o.status != OrderStatus.cancelled).toList();
  List<Order> get kitchenOrders => openOrders.where((o) => o.status == OrderStatus.open || o.status == OrderStatus.preparing || o.status == OrderStatus.ready).toList();
  double get todaySales {
    final t = DateTime.now().toUtc();
    return orders.where((o) => o.isPaid && o.paidAt != null && o.paidAt!.year == t.year && o.paidAt!.month == t.month && o.paidAt!.day == t.day).fold<double>(0, (s, o) => s + o.total.asDouble);
  }
  int get todayOrderCount {
    final t = DateTime.now().toUtc();
    return orders.where((o) { final c = o.createdAt; return c.year == t.year && c.month == t.month && c.day == t.day; }).length;
  }
  List<InventoryItem> get lowStockItems => inventory.where((i) => i.quantity <= i.lowStockThreshold).toList();

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    deviceId = p.getString('device_id') ?? deviceId;
    await p.setString('device_id', deviceId);
    deviceName = p.getString('device_name') ?? 'Tablet-${deviceId.substring(0, 4)}';
    kitchenPrinterIp = p.getString('kitchen_printer_ip');
    cashierPrinterIp = p.getString('cashier_printer_ip');
    final billJson = p.getString('bill_profile_json');
    if (billJson != null) {
      try { bill = BillProfile.fromJson(jsonDecode(billJson) as Map<String, dynamic>); } catch (_) {}
    } else {
      final name = p.getString('restaurant_name');
      if (name != null) bill = BillProfile(restaurantName: name);
    }
    final k = p.getString('license_key');
    if (k != null) {
      license = LicenseInfo(key: k, customerId: p.getString('license_customer_id') ?? '', customerName: p.getString('license_customer_name') ?? '', expiresAt: DateTime.tryParse(p.getString('license_expires') ?? '') ?? DateTime.now().add(const Duration(days: 30)), isActive: true);
    }
    localeCode = p.getString('locale_code') ?? 'en';
    final saved = p.getString('main_state_json');
    if (saved != null && saved.isNotEmpty) {
      try { applyState(jsonDecode(saved) as Map<String, dynamic>); } catch (_) { _seed(); }
    } else { _seed(); }
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

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('bill_profile_json', jsonEncode(bill.toJson()));
      await p.setString('restaurant_name', bill.restaurantName);
      if (kitchenPrinterIp != null) await p.setString('kitchen_printer_ip', kitchenPrinterIp!); else await p.remove('kitchen_printer_ip');
      if (cashierPrinterIp != null) await p.setString('cashier_printer_ip', cashierPrinterIp!); else await p.remove('cashier_printer_ip');
      if (isMain || serverRunning) await p.setString('main_state_json', jsonEncode(fullState()));
    } catch (_) {}
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 400), _persist);
  }

  Future<String?> _ip() async {
    try {
      for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4, includeLinkLocal: false)) {
        for (final a in i.addresses) { if (!a.isLoopback) return a.address; }
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
    'bill': bill.toJson(),
    'restaurantName': bill.restaurantName,
    'kitchenPrinterIp': kitchenPrinterIp,
    'cashierPrinterIp': cashierPrinterIp,
  };

  void applyState(Map<String, dynamic> s) {
    categories = (s['categories'] as List? ?? []).map((e) => MenuCategory.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    menuItems = (s['menuItems'] as List? ?? []).map((e) => MenuItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    orders = (s['orders'] as List? ?? []).map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    inventory = (s['inventory'] as List? ?? []).map((e) => InventoryItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    _orderSeq = s['orderSeq'] as int? ?? _orderSeq;
    if (s['bill'] is Map) bill = BillProfile.fromJson(Map<String, dynamic>.from(s['bill'] as Map));
    else if (s['restaurantName'] is String) bill = BillProfile(restaurantName: s['restaurantName'] as String, address: bill.address, phone: bill.phone, taxId: bill.taxId, footer: bill.footer, currencySymbol: bill.currencySymbol);
    if (s.containsKey('kitchenPrinterIp')) kitchenPrinterIp = s['kitchenPrinterIp'] as String?;
    if (s.containsKey('cashierPrinterIp')) cashierPrinterIp = s['cashierPrinterIp'] as String?;
    if (categories.isEmpty) _seed();
    notifyListeners();
  }

  Future<void> saveSettings({BillProfile? billProfile, String? kitchenIp, String? cashierIp}) async {
    if (billProfile != null) bill = billProfile;
    if (kitchenIp != null) kitchenPrinterIp = kitchenIp.isEmpty ? null : kitchenIp;
    if (cashierIp != null) cashierPrinterIp = cashierIp.isEmpty ? null : cashierIp;
    await _persist();
    if (isMain) _server?.broadcast('state.replace', fullState());
    notifyListeners();
  }

  Future<bool> testKitchenPrinter() async {
    if (kitchenPrinterIp == null || kitchenPrinterIp!.isEmpty) return false;
    return PrintService.testPrint(bill: bill, ip: kitchenPrinterIp!);
  }

  Future<bool> testCashierPrinter() async {
    if (cashierPrinterIp == null || cashierPrinterIp!.isEmpty) return false;
    return PrintService.testPrint(bill: bill, ip: cashierPrinterIp!);
  }

  String billPreviewFor(Order order) => PrintService.buildBillPreview(order: order, bill: bill);

  Future<void> startAsMain() async {
    isMain = true; role = DeviceRole.main;
    localIp = await _ip() ?? '127.0.0.1';
    _server = LocalServer(port: port, getFullState: () async => fullState(), onClientEvent: _onEvent);
    await _server!.start();
    serverRunning = true;
    devices = [DeviceInfo(id: deviceId, name: deviceName, role: DeviceRole.main, ip: localIp, isOnline: true)];
    await _persist();
    notifyListeners();
  }

  Future<void> stopMain() async {
    await _persist();
    await _server?.stop(); _server = null; serverRunning = false; notifyListeners();
  }

  Future<void> _onEvent(String type, Map<String, dynamic> payload, String did) async {
    if (type == 'order.create') {
      final order = Order.fromJson(payload);
      if (!orders.any((o) => o.id == order.id)) {
        orders = [...orders, order];
        _orderSeq = (int.tryParse(order.orderNumber) ?? _orderSeq) + 1;
        _deduct(order);
        unawaited(_printKitchen(order));
      }
      _server?.broadcast('order.upsert', order.toJson());
    } else if (type == 'order.update') {
      final order = Order.fromJson(payload);
      orders = orders.map((o) => o.id == order.id ? order : o).toList();
      _server?.broadcast('order.upsert', order.toJson());
    } else if (type == 'order.add_items') {
      final orderId = payload['orderId'] as String?;
      final items = (payload['items'] as List? ?? []).map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      if (orderId != null && items.isNotEmpty) _applyAddItems(orderId, items);
    } else if (type == 'inventory.upsert') {
      upsertInventoryItem(InventoryItem.fromJson(Map<String, dynamic>.from(payload)));
      return;
    } else if (type == 'inventory.delete') {
      final id = payload['id'] as String?;
      if (id != null) deleteInventoryItem(id);
      return;
    } else if (type == 'settings.update') {
      if (payload['bill'] is Map) bill = BillProfile.fromJson(Map<String, dynamic>.from(payload['bill'] as Map));
      if (payload.containsKey('kitchenPrinterIp')) kitchenPrinterIp = payload['kitchenPrinterIp'] as String?;
      if (payload.containsKey('cashierPrinterIp')) cashierPrinterIp = payload['cashierPrinterIp'] as String?;
      _server?.broadcast('state.replace', fullState());
      _schedulePersist();
    }
    _schedulePersist();
    notifyListeners();
  }

  void _deduct(Order order) {
    for (final line in order.items) {
      inventory = inventory.map((inv) {
        if (inv.linkedMenuItemId == line.menuItemId) {
          return InventoryItem(id: inv.id, name: inv.name, unit: inv.unit, quantity: (inv.quantity - line.quantity).clamp(0, 1e9).toDouble(), lowStockThreshold: inv.lowStockThreshold, linkedMenuItemId: inv.linkedMenuItemId);
        }
        return inv;
      }).toList();
    }
  }

  Future<void> _printKitchen(Order order) async {
    if (kitchenPrinterIp == null || kitchenPrinterIp!.isEmpty) return;
    await PrintService.printKitchenTicket(order: order, bill: bill, networkIp: kitchenPrinterIp);
  }

  Future<void> _printReceipt(Order order) async {
    if (cashierPrinterIp == null || cashierPrinterIp!.isEmpty) return;
    await PrintService.printPaymentTicket(order: order, bill: bill, networkIp: cashierPrinterIp);
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
          } else if (type == 'state.replace') { applyState(payload); }
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
    if (isMain) { _deduct(order); _server?.broadcast('order.upsert', order.toJson()); unawaited(_printKitchen(order)); _schedulePersist(); }
    else { _send('order.create', order.toJson()); }
    notifyListeners();
    return order;
  }

  Order? findOpenByTable(String table) {
    final t = table.trim().toLowerCase();
    if (t.isEmpty) return null;
    try { return openOrders.firstWhere((o) => (o.tableNumber ?? '').trim().toLowerCase() == t); } catch (_) { return null; }
  }

  void addItemsToOrder(String orderId, List<OrderItem> extra) {
    if (extra.isEmpty) return;
    if (isMain) { _applyAddItems(orderId, extra); }
    else {
      _send('order.add_items', {'orderId': orderId, 'items': extra.map((e) => e.toJson()).toList()});
      _applyAddItems(orderId, extra);
    }
  }

  void _applyAddItems(String orderId, List<OrderItem> extra) {
    if (!orders.any((o) => o.id == orderId)) return;
    orders = orders.map((o) => o.id != orderId ? o : o.copyWith(items: [...o.items, ...extra], status: OrderStatus.open)).toList();
    final order = orders.firstWhere((o) => o.id == orderId);
    final delta = Order(orderNumber: order.orderNumber, tableNumber: order.tableNumber, ticketNumber: order.ticketNumber, items: extra, createdByDeviceId: deviceId);
    if (isMain) { _deduct(delta); unawaited(_printKitchen(delta)); _server?.broadcast('order.upsert', order.toJson()); _schedulePersist(); }
    notifyListeners();
  }

  void updateOrderStatus(String id, OrderStatus status) {
    orders = orders.map((o) => o.id == id ? o.copyWith(status: status) : o).toList();
    final order = orders.firstWhere((o) => o.id == id);
    if (isMain) { _server?.broadcast('order.upsert', order.toJson()); _schedulePersist(); } else { _send('order.update', order.toJson()); }
    notifyListeners();
  }

  void markPaid(String id) {
    orders = orders.map((o) => o.id == id ? o.copyWith(isPaid: true, status: OrderStatus.paid, paidAt: DateTime.now().toUtc()) : o).toList();
    final order = orders.firstWhere((o) => o.id == id);
    if (isMain) { _server?.broadcast('order.upsert', order.toJson()); unawaited(_printReceipt(order)); _schedulePersist(); } else { _send('order.update', order.toJson()); }
    notifyListeners();
  }

  void upsertMenuItem(MenuItem item) {
    if (!isMain) return;
    final idx = menuItems.indexWhere((m) => m.id == item.id);
    if (idx >= 0) menuItems = [...menuItems]..[idx] = item;
    else { menuItems = [...menuItems, item]; inventory = [...inventory, InventoryItem(name: item.name, quantity: 50, linkedMenuItemId: item.id)]; }
    _server?.broadcast('state.replace', fullState()); _schedulePersist(); notifyListeners();
  }

  void deleteMenuItem(String id) {
    if (!isMain) return;
    menuItems = menuItems.where((m) => m.id != id).toList();
    _server?.broadcast('state.replace', fullState()); _schedulePersist(); notifyListeners();
  }

  void upsertCategory(MenuCategory cat) {
    if (!isMain) return;
    final idx = categories.indexWhere((c) => c.id == cat.id);
    if (idx >= 0) categories = [...categories]..[idx] = cat; else categories = [...categories, cat];
    _server?.broadcast('state.replace', fullState()); _schedulePersist(); notifyListeners();
  }

  void setInventoryQty(String id, double qty) {
    if (!isMain) return;
    inventory = inventory.map((i) => i.id != id ? i : InventoryItem(id: i.id, name: i.name, unit: i.unit, quantity: qty, lowStockThreshold: i.lowStockThreshold, linkedMenuItemId: i.linkedMenuItemId)).toList();
    _server?.broadcast('state.replace', fullState()); _schedulePersist(); notifyListeners();
  }

  void upsertInventoryItem(InventoryItem item) {
    if (!isMain && !serverRunning) return;
    final idx = inventory.indexWhere((i) => i.id == item.id);
    if (idx >= 0) inventory = [...inventory]..[idx] = item; else inventory = [...inventory, item];
    if (isMain) { _server?.broadcast('state.replace', fullState()); _schedulePersist(); }
    notifyListeners();
  }

  void addInventoryItem({required String name, double quantity = 0, String unit = 'pcs', double lowStockThreshold = 5, String? linkedMenuItemId}) {
    if (!isMain) return;
    upsertInventoryItem(InventoryItem(name: name, quantity: quantity, unit: unit, lowStockThreshold: lowStockThreshold, linkedMenuItemId: linkedMenuItemId));
  }

  void deleteInventoryItem(String id) {
    if (!isMain) return;
    inventory = inventory.where((i) => i.id != id).toList();
    _server?.broadcast('state.replace', fullState()); _schedulePersist(); notifyListeners();
  }

  int importInventoryCsv(String raw, {bool replaceAll = false}) {
    if (!isMain) return 0;
    final lines = raw.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return 0;
    var start = 0;
    final first = lines.first.toLowerCase();
    if (first.contains('name') && (first.contains('qty') || first.contains('quantity') || first.contains(','))) start = 1;
    final imported = <InventoryItem>[];
    for (var i = start; i < lines.length; i++) {
      final parts = lines[i].contains('\t') ? lines[i].split('\t') : _parseCsvLine(lines[i]);
      if (parts.isEmpty) continue;
      final name = parts[0].trim();
      if (name.isEmpty) continue;
      final qty = (parts.length > 1 ? double.tryParse(parts[1].trim().replaceAll(',', '')) : null) ?? 0.0;
      final unit = parts.length > 2 && parts[2].trim().isNotEmpty ? parts[2].trim() : 'pcs';
      final low = (parts.length > 3 ? double.tryParse(parts[3].trim().replaceAll(',', '')) : null) ?? 5.0;
      imported.add(InventoryItem(name: name, quantity: qty, unit: unit, lowStockThreshold: low));
    }
    if (imported.isEmpty) return 0;
    if (replaceAll) { inventory = imported; }
    else {
      for (final item in imported) {
        final idx = inventory.indexWhere((e) => e.name.toLowerCase() == item.name.toLowerCase());
        if (idx >= 0) {
          inventory = [...inventory]..[idx] = InventoryItem(id: inventory[idx].id, name: item.name, unit: item.unit, quantity: item.quantity, lowStockThreshold: item.lowStockThreshold, linkedMenuItemId: inventory[idx].linkedMenuItemId);
        } else { inventory = [...inventory, item]; }
      }
    }
    _server?.broadcast('state.replace', fullState()); _schedulePersist(); notifyListeners();
    return imported.length;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') { inQuotes = !inQuotes; }
      else if ((c == ',' && !inQuotes) || (c == ';' && !inQuotes)) { result.add(sb.toString()); sb.clear(); }
      else { sb.write(c); }
    }
    result.add(sb.toString());
    return result;
  }

  int importInventoryLines(String raw) {
    final buf = StringBuffer();
    for (final line in raw.split(RegExp(r'[\r\n]+'))) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final m = RegExp(r'^(.+?)\s+(\d+(?:\.\d+)?)\s*$').firstMatch(t);
      if (m != null) buf.writeln('${m.group(1)},${m.group(2)},pcs,5');
      else buf.writeln('$t,0,pcs,5');
    }
    return importInventoryCsv(buf.toString());
  }

  Map<String, dynamic> salesReport({int days = 1}) {
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final paid = orders.where((o) => o.isPaid && o.paidAt != null && !o.paidAt!.isBefore(start)).toList();
    final total = paid.fold<double>(0, (s, o) => s + o.total.asDouble);
    return {'days': days, 'orders': paid.length, 'total': total, 'currency': bill.currencySymbol, 'lowStock': lowStockItems.length};
  }

  Future<void> setLocale(String code) async {
    localeCode = (code == 'ur') ? 'ur' : 'en';
    final p = await SharedPreferences.getInstance();
    await p.setString('locale_code', localeCode);
    notifyListeners();
  }

  /// Public signup – stores name + email in SaaS customers table so the seller dashboard shows contact emails.
  Future<void> registerSignup({required String name, required String email}) async {
    final n = name.trim();
    final e = email.trim().toLowerCase();
    if (n.isEmpty && e.isEmpty) return;
    try {
      await http
          .post(
            Uri.parse('$licenseApiBase/api/v1/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': n.isEmpty ? (e.isNotEmpty ? e.split('@').first : 'Restaurant') : n,
              'email': e.isEmpty ? null : e,
              'deviceId': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Offline / network – ignore; license activation still works offline with grace.
    }
  }

  Future<bool> activateLicense(String key) async {
    licenseMessage = null;
    notifyListeners();
    try {
      final res = await http
          .post(
            Uri.parse('$licenseApiBase/api/v1/license/validate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'licenseKey': key.trim(), 'deviceId': deviceId}),
          )
          .timeout(const Duration(seconds: 12));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final p = await SharedPreferences.getInstance();

      // Reject: invalid / expired / revoked / bound to another device
      if (res.statusCode != 200 || data['valid'] != true) {
        final err = data['error']?.toString() ?? 'Invalid license';
        licenseMessage = err;
        // Do NOT grant access when server explicitly rejects (e.g. other device bound)
        if (res.statusCode == 401 || res.statusCode == 403) {
          license = null;
          notifyListeners();
          return false;
        }
        // Soft fail for other cases – short pending window only if key format ok
        license = LicenseInfo(
          key: key.trim(),
          customerId: '',
          customerName: 'Pending',
          expiresAt: DateTime.now().add(const Duration(days: 3)),
          isActive: true,
        );
        await p.setString('license_key', key.trim());
        notifyListeners();
        return false;
      }

      await p.setString('license_key', key.trim());
      license = LicenseInfo(
        key: key.trim(),
        customerId: '${data['customerId'] ?? ''}',
        customerName: '${data['customerName'] ?? ''}',
        expiresAt: DateTime.tryParse('${data['expiresAt']}') ??
            DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        lastValidatedAt: DateTime.now().toUtc(),
      );
      await p.setString('license_customer_id', license!.customerId);
      await p.setString('license_customer_name', license!.customerName);
      await p.setString('license_expires', license!.expiresAt.toIso8601String());
      final first = data['firstActivation'] == true;
      licenseMessage = first
          ? 'Activated & bound to this device until ${license!.expiresAt.toLocal().toString().split(' ').first}'
          : 'License active until ${license!.expiresAt.toLocal().toString().split(' ').first}';
      notifyListeners();
      return true;
    } catch (e) {
      // Offline only: allow grace if we already had a stored key for this device
      final p = await SharedPreferences.getInstance();
      final stored = p.getString('license_key');
      if (stored != null && stored == key.trim()) {
        license = LicenseInfo(
          key: key.trim(),
          customerId: p.getString('license_customer_id') ?? '',
          customerName: p.getString('license_customer_name') ?? 'Offline grace',
          expiresAt: DateTime.tryParse(p.getString('license_expires') ?? '') ??
              DateTime.now().add(const Duration(days: 14)),
          isActive: true,
        );
        licenseMessage = 'Offline – using saved license (reconnect to re-validate).';
        notifyListeners();
        return true;
      }
      licenseMessage = 'Need internet once to activate. Then works offline.';
      license = null;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _persistDebounce?.cancel(); _wsSub?.cancel(); _ws?.sink.close(); _server?.stop();
    super.dispose();
  }
}

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) => AppController());
