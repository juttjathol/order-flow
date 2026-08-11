import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';

import '../models/models.dart';

final _log = Logger();

/// ESC/POS printing via network (IP:9100).
/// Bluetooth can be re-added later with a maintained package.
class PrintService {
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
      write('${item.quantity}x ${item.nameSnapshot}  ${item.lineTotal.asDouble.toStringAsFixed(2)}\n');
    }
    write('--------------------------------\n');
    write('TOTAL: ${order.total.asDouble.toStringAsFixed(2)}\n');
    write('Thank you!\n\n\n\n');
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
    if (networkIp != null && networkIp.isNotEmpty) {
      return sendToNetworkPrinter(ip: networkIp, data: bytes);
    }
    _log.w('No network printer configured');
    return false;
  }
}
