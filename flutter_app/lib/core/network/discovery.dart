import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:multicast_dns/multicast_dns.dart';

final _log = Logger();

class DiscoveredServer {
  final String name;
  final String host;
  final int port;
  final String? txt;

  DiscoveredServer({
    required this.name,
    required this.host,
    required this.port,
    this.txt,
  });

  @override
  String toString() => '$name @ $host:$port';
}

/// mDNS discovery for OrderFlow Main devices.
/// Service type: _orderflow._tcp
class ServerDiscovery {
  static const serviceType = '_orderflow._tcp';
  final MDnsClient _client = MDnsClient();
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    await _client.start();
    _started = true;
  }

  Future<void> stop() async {
    if (!_started) return;
    _client.stop();
    _started = false;
  }

  /// One-shot search for Main servers on the local network.
  Future<List<DiscoveredServer>> discover({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    await start();
    final results = <DiscoveredServer>[];
    final seen = <String>{};

    try {
      await for (final ptr in _client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(serviceType),
        timeout: timeout,
      )) {
        await for (final srv in _client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
          timeout: const Duration(seconds: 2),
        )) {
          final host = srv.target;
          final port = srv.port;
          // Resolve IP
          String? ip;
          await for (final ipRec in _client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(host),
            timeout: const Duration(seconds: 1),
          )) {
            ip = ipRec.address.address;
            break;
          }
          if (ip != null && seen.add('$ip:$port')) {
            results.add(DiscoveredServer(
              name: ptr.domainName,
              host: ip,
              port: port,
            ));
          }
        }
      }
    } catch (e) {
      _log.w('mDNS discovery error: $e');
    }

    return results;
  }
}

/// Advertises the Main server via mDNS so other devices can find it.
class ServerAdvertiser {
  static const serviceType = '_orderflow._tcp';
  // Note: full mDNS registration on Flutter is limited.
  // On many platforms we rely on the device showing IP + QR.
  // For production you can use a native plugin or just QR / manual IP.
  // This class is a placeholder that logs the intended advertisement.

  final String serviceName;
  final int port;

  ServerAdvertiser({
    required this.serviceName,
    required this.port,
  });

  Future<void> start() async {
    _log.i('Would advertise $serviceName.$serviceType on port $port');
    // Real implementation would use platform channels or a package that
    // supports service registration. For now Main device always shows
    // its local IP + QR code for clients to join.
  }

  Future<void> stop() async {}
}

/// Helper to get the device's likely LAN IP
Future<String?> getLocalIpAddress() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) {
          return addr.address;
        }
      }
    }
  } catch (e) {
    _log.w('Could not determine local IP: $e');
  }
  return null;
}
