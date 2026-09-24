import 'shop.dart';

abstract interface class ShopRepository {
  Stream<Shop?> watchShop(String shopId);

  Stream<List<Shop>> watchAllShops();

  Future<Shop> createShop({required String name, required String code});

  Future<void> updateShop({required Shop shop});
}
