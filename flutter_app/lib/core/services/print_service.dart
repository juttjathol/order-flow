import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:logger/logger.dart';

import '../models/models.dart';

final _log = Logger();

/// Builds ESC/POS byte commands and sends them to Network or Bluetooth thermal printers.
class PrintService {
  static final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  static Uint8List buildKitchenTicket({
    required Order order,
    required String restaurantName,
    bool onlyNewItems = false,
    int paperWidth = 32,
  }) {
    final buffer = BytesBuilder();
    void write(String s) => buffer.add(utf8.encode(s));
    void cmd(List<int> bytes) => buffer.add(bytes);

    cmd([0x1B, 0x40]);
    cmd([0x1B, 0x61, 0x01]);
    write('$restaurantName\n');
    write('KITCHEN TICKET\n');
    cmd([0x1B, 0x61, 0x00]);

    write('--------------------------------\n');
    write('Order #: ${order.orderNumber}\n');
    if (order.tableNumber != null) write('TABLE: ${order.tableNumber}\n');
    if (order.ticketNumber != null) write('Ticket: ${order.ticketNumber}\n');
    write('Time: ${order.createdAt.toLocal()}\n');
    write('--------------------------------\n');

    final items = onlyNewItems
        ? order.items.where((i) => !i.isKitchenPrinted).toList()
        : order.items;

    for (final item in items) {
      write('${item.quantity}x ${item.nameSnapshot}\n');
      for (final mod in item.selectedModifiers) {
        write('   + ${mod.name}\n');
      }
      if (item.notes != null && item.notes!.isNotEmpty) {
        write('   NOTE: ${item.notes}\n');
      }
      write('\n');
    }

    if (order.notes != null && order.notes!.isNotEmpty) {
      write('Order note: ${order.notes}\n');
    }

    write('--------------------------------\n');
    write('\n\n\n');
    cmd([0x1D, 0x56, 0x00]);

    return buffer.toBytes();
  }

  static Uint8List buildPaymentTicket({
    required Order order,
    required String restaurantName,
    int paperWidth = 32,
  }) {
    final buffer = BytesBuilder();
    void write(String s) => buffer.add(utf8.encode(s));
    void cmd(List<int> bytes) => buffer.add(bytes);

    cmd([0x1B, 0x40]);
    cmd([0x1B, 0x61, 0x01]);
    write('$restaurantName\n');
    write('RECEIPT\n');
    cmd([0x1B, 0x61, 0x00]);

    write('--------------------------------\n');
    write('Order #: ${order.orderNumber}\n');
    if (order.tableNumber != null) write('Table: ${order.tableNumber}\n');
    if (order.ticketNumber != null) write('Ticket: ${order.ticketNumber}\n');
    write('--------------------------------\n');

    for (final item in order.items) {
      final name = '${item.quantity}x ${item.nameSnapshot}';
      final price = item.lineTotal.asDouble.toStringAsFixed(2);
      write('$name  $price\n');
      for (final mod in item.selectedModifiers) {
        write('   + ${mod.name}\n');
      }
    }

    write('--------------------------------\n');
    write('Subtotal: ${order.subtotal.asDouble.toStringAsFixed(2)}\n');
    if (order.discount != null) {
      write('Discount: -${order.discount!.asDouble.toStringAsFixed(2)}\n');
    }
    if (order.tax != null) {
      write('Tax: ${order.tax!.asDouble.toStringAsFixed(2)}\n');
    }
    if (order.serviceCharge != null) {
      write('Service: ${order.serviceCharge!.asDouble.toStringAsFixed(2)}\n');
    }
    write('TOTAL: ${order.total.asDouble.toStringAsFixed(2)}\n');
    write('--------------------------------\n');
    write('Thank you!\n');
    write('\n\n\n');
    cmd([0x1D, 0x56, 0x00]);

    return buffer.toBytes();
  }

  static Future<bool> sendToNetworkPrinter({
    required String ip,
    int port = 9100,
    required Uint8List data,
  }) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      socket.add(data);
      await socket.flush();
      await socket.close();
      _log.i('Printed to network $ip:$port (${data.length} bytes)');
      return true;
    } catch (e) {
      _log.e('Network print failed: $e');
      return false;
    }
  }

  static Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      return devices ?? [];
    } catch (e) {
      _log.e('Failed to list Bluetooth devices: $e');
      return [];
    }
  }

  static Future<bool> isBluetoothConnected() async {
    try {
      return await _bluetooth.isConnected ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> connectBluetooth(BluetoothDevice device) async {
    try {
      final connected = await _bluetooth.connect(device);
      _log.i('Bluetooth connect result: $connected → ${device.name}');
      return connected ?? false;
    } catch (e) {
      _log.e('Bluetooth connect failed: $e');
      return false;
    }
  }

  static Future<void> disconnectBluetooth() async {
    try {
      await _bluetooth.disconnect();
    } catch (_) {}
  }

  static Future<bool> sendToBluetoothPrinter(Uint8List data) async {
    try {
      final connected = await isBluetoothConnected();
      if (!connected) {
        _log.w('No Bluetooth printer connected');
        return false;
      }
      await _bluetooth.writeBytes(data);
      _log.i('Printed ${data.length} bytes via Bluetooth');
      return true;
    } catch (e) {
      _log.e('Bluetooth print failed: $e');
      return false;
    }
  }

  static Future<bool> printKitchenTicket({
    required Order order,
    required String restaurantName,
    String? networkIp,
    bool useBluetooth = false,
    bool onlyNewItems = false,
  }) async {
    final bytes = buildKitchenTicket(
      order: order,
      restaurantName: restaurantName,
      onlyNewItems: onlyNewItems,
    );

    if (useBluetooth) {
      return sendToBluetoothPrinter(bytes);
    }
    if (networkIp != null && networkIp.isNotEmpty) {
      return sendToNetworkPrinter(ip: networkIp, data: bytes);
    }
    _log.w('No printer configured');
    return false;
  }
}
