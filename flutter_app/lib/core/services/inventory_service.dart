import 'package:logger/logger.dart';
import '../models/models.dart';

final _log = Logger();

/// Handles automatic inventory deduction when orders are placed / items added.
/// Linked via InventoryItem.linkedMenuItemId → MenuItem.id
class InventoryService {
  /// Deduct stock for every item in the order (or only the new ones).
  /// Returns list of items that went below low-stock threshold.
  static List<InventoryItem> deductForOrder({
    required Order order,
    required List<InventoryItem> currentInventory,
    required List<MenuItem> menu,
    bool onlyNewItems = false,
  }) {
    final lowStock = <InventoryItem>[];
    final itemsToProcess = onlyNewItems
        ? order.items.where((i) => !i.isKitchenPrinted).toList()
        : order.items;

    for (final orderItem in itemsToProcess) {
      final inv = currentInventory.cast<InventoryItem?>().firstWhere(
            (i) => i?.linkedMenuItemId == orderItem.menuItemId,
            orElse: () => null,
          );
      if (inv == null) continue;

      final newQty = inv.quantity - orderItem.quantity;
      final updated = InventoryItem(
        id: inv.id,
        name: inv.name,
        unit: inv.unit,
        quantity: newQty < 0 ? 0 : newQty,
        lowStockThreshold: inv.lowStockThreshold,
        linkedMenuItemId: inv.linkedMenuItemId,
      );

      // Replace in list (caller must persist)
      final idx = currentInventory.indexWhere((i) => i.id == inv.id);
      if (idx >= 0) currentInventory[idx] = updated;

      if (updated.quantity <= updated.lowStockThreshold) {
        lowStock.add(updated);
        _log.w('Low stock: ${updated.name} = ${updated.quantity} ${updated.unit}');
      }
    }
    return lowStock;
  }
}
