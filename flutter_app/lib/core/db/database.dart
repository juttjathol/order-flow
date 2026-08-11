// Drift database definition.
// Run: dart run build_runner build --delete-conflicting-outputs
// after changing this file.

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class MenuCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class MenuItems extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get priceAmount => integer()(); // minor units
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  TextColumn get modifiersJson => text().withDefault(const Constant('[]'))();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get orderNumber => text()();
  TextColumn get tableNumber => text().nullable()();
  TextColumn get ticketNumber => text().nullable()();
  TextColumn get itemsJson => text()(); // full OrderItem list
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdByDeviceId => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get discountAmount => integer().nullable()();
  IntColumn get taxAmount => integer().nullable()();
  IntColumn get serviceChargeAmount => integer().nullable()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get paidAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class InventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get quantity => real().withDefault(const Constant(0.0))();
  RealColumn get lowStockThreshold => real().withDefault(const Constant(5.0))();
  TextColumn get linkedMenuItemId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get ip => text().nullable()();
  DateTimeColumn get lastSeen => dateTime()();
  BoolColumn get isOnline => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettingsTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))(); // singleton
  TextColumn get dataJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LicenseTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get dataJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  MenuCategories,
  MenuItems,
  Orders,
  InventoryItems,
  Devices,
  AppSettingsTable,
  LicenseTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Convenience helpers will be added in repository layer.
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'orderflow.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
