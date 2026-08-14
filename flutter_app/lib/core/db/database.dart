// Drift schema design (menu, orders, inventory).
// Runtime storage uses SharedPreferences + JSON in AppController.
// To enable full Drift later: restore table classes and run
//   dart run build_runner build --delete-conflicting-outputs

/// Placeholder so the file compiles; app does not open SQLite at runtime yet.
class AppDatabase {
  AppDatabase();
  Future<void> close() async {}
}
