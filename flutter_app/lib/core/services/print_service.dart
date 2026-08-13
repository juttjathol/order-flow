import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';

import '../models/models.dart';

final _log = Logger();

class BillProfile {
  final String restaurantName;
  final String address;
  final String phone;
  final String taxId;
  final String footer;
  final String currencySymbol;

  const BillProfile({
    this.restaurantName = 'My Restaurant',
    this.address = '',
    this.phone = '',
    this.taxId = '',
    this.footer = 'Thank you!',
    this.currencySymbol = '\$',
  });

  Map<String, dynamic> toJson() => {
        'restaurantName': restaurantName,
        'address': address,
        'phone': phone,
        'taxId': taxId,
        'footer': footer,
        'currencySymbol': currencySymbol,
      };

  factory BillProfile.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const BillProfile();
    return BillProfile(
      restaurantName: j['restaurantName'] as String? ?? 'My Restaurant',
      address: j['address'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      taxId: j['taxId'] as String? ?? '',
      footer: j['footer'] as String? ?? 'Thank you!',
      currencySymbol: j['currencySymbol'] as String? ?? '\$',
    );
  }
}

class PrintService {
  static Uint8List buildKitchenTicket({
    required Order order,
    required BillProfile bill,
    bool onlyNewItems = false,
  }) {
    final buffer = BytesBuilder();
    void write(String s) => buffer.add(utf8.encode(s));
    void cmd(List<int> bytes) => buffer.add(bytes);

    cmd([0x1B, 0x40]);
    cmd([0x1B, 0x61, 0x01]);
    write('${bill.restaurantName}\n');
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
    write('--------------------------------\n\n\n\n');
    cmd([0x1D, 0x56, 0x00]);
    return buffer.toBytes();
  }

  static Uint8List buildPaymentTicket({
    required Order order,
    required BillProfile bill,
  }) {
    final buffer = BytesBuilder();
    void write(String s) => buffer.add(utf8.encode(s));
    void cmd(List<int> bytes) => buffer.add(bytes);
    final sym = bill.currencySymbol;

    cmd([0x1B, 0x40]);
    cmd([0x1B, 0x61, 0x01]);
    write('${bill.restaurantName}\n');
    if (bill.address.isNotEmpty) write('${bill.address}\n');
    if (bill.phone.isNotEmpty) write('Tel: ${bill.phone}\n');
    if (bill.taxId.isNotEmpty) write('Tax ID: ${bill.taxId}\n');
    write('RECEIPT\n');
    cmd([0x1B, 0x61, 0x00]);
    write('--------------------------------\n');
    write('Order #: ${order.orderNumber}\n');
    if (order.tableNumber != null) write('Table: ${order.tableNumber}\n');
    if (order.ticketNumber != null) write('Ticket: ${order.ticketNumber}\n');
    write('Time: ${order.paidAt?.toLocal() ?? order.createdAt.toLocal()}\n');
    write('--------------------------------\n');

    for (final item in order.items) {
      write('${item.quantity}x ${item.nameSnapshot}\n');
      write('  $sym${item.lineTotal.asDouble.toStringAsFixed(2)}\n');
    }
    write('--------------------------------\n');
    write('TOTAL: $sym${order.total.asDouble.toStringAsFixed(2)}\n');
    write('--------------------------------\n');
    cmd([0x1B, 0x61, 0x01]);
    write('${bill.footer}\n\n\n\n');
    cmd([0x1D, 0x56, 0x00]);
    return buffer.toBytes();
  }

  static String buildBillPreview({
    required Order order,
    required BillProfile bill,
  }) {
    final sym = bill.currencySymbol;
    final b = StringBuffer();
    b.writeln(bill.restaurantName);
    if (bill.address.isNotEmpty) b.writeln(bill.address);
    if (bill.phone.isNotEmpty) b.writeln('Tel: ${bill.phone}');
    if (bill.taxId.isNotEmpty) b.writeln('Tax ID: ${bill.taxId}');
    b.writeln('--- RECEIPT ---');
    b.writeln('Order #${order.orderNumber}');
    if (order.tableNumber != null) b.writeln('Table: ${order.tableNumber}');
    if (order.ticketNumber != null) b.writeln('Ticket: ${order.ticketNumber}');
    b.writeln('---');
    for (final item in order.items) {
      b.writeln('${item.quantity}x ${item.nameSnapshot}  $sym${item.lineTotal.asDouble.toStringAsFixed(2)}');
    }
    b.writeln('---');
    b.writeln('TOTAL: $sym${order.total.asDouble.toStringAsFixed(2)}');
    b.writeln(bill.footer);
    return b.toString();
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
    required BillProfile bill,
    String? networkIp,
    bool onlyNewItems = false,
  }) async {
    final bytes = buildKitchenTicket(order: order, bill: bill, onlyNewItems: onlyNewItems);
    if (networkIp != null && networkIp.isNotEmpty) {
      return sendToNetworkPrinter(ip: networkIp, data: bytes);
    }
    return false;
  }

  static Future<bool> printPaymentTicket({
    required Order order,
    required BillProfile bill,
    String? networkIp,
  }) async {
    final bytes = buildPaymentTicket(order: order, bill: bill);
    if (networkIp != null && networkIp.isNotEmpty) {
      return sendToNetworkPrinter(ip: networkIp, data: bytes);
    }
    return false;
  }

  static Future<bool> testPrint({
    required BillProfile bill,
    required String ip,
  }) async {
    final buffer = BytesBuilder();
    void write(String s) => buffer.add(utf8.encode(s));
    buffer.add([0x1B, 0x40]);
    write('TEST PRINT\n${bill.restaurantName}\nOK\n\n\n');
    buffer.add([0x1D, 0x56, 0x00]);
    return sendToNetworkPrinter(ip: ip, data: buffer.toBytes());
  }
}
