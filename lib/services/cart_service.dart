import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';
import 'product_service.dart';

class CartService {
  static const int _defaultUserId = 1;
  static Cart _cart = Cart(
    id: 0,
    userId: _defaultUserId,
    products: const [],
    totalProducts: 0,
    totalQuantity: 0,
    total: 0,
    discountedTotal: 0,
  );
  static int? _cartUserId;
  static bool _hasLocalCartUpdate = false;

  static Cart get cart => _cart;

  static Cart parseCartResponse(dynamic raw) {
    if (raw is! Map<String, dynamic> && raw is Map) {
      raw = Map<String, dynamic>.from(raw);
    }

    final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};

    if (map['carts'] is List && (map['carts'] as List).isNotEmpty) {
      final firstCart = (map['carts'] as List).first;
      if (firstCart is Map) {
        return Cart.fromJson(Map<String, dynamic>.from(firstCart));
      }
    }

    if (map.containsKey('products') || map.containsKey('userId')) {
      return Cart.fromJson(map);
    }

    return Cart(
      id: 0,
      userId: _defaultUserId,
      products: const [],
      totalProducts: 0,
      totalQuantity: 0,
      total: 0,
      discountedTotal: 0,
    );
  }

  Future<Cart> getUserCart({int userId = 1}) async {
    final resolvedUserId = userId > 0 ? userId : _defaultUserId;

    if (_hasLocalCartUpdate && _cartUserId == resolvedUserId) {
      return _cart;
    }

    final response = await http.get(Uri.parse('$host/carts/user/$resolvedUserId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load cart for user $resolvedUserId');
    }

    final decoded = jsonDecode(response.body);
    _cart = parseCartResponse(decoded);
    _cartUserId = resolvedUserId;
    return _cart;
  }

  Future<Cart> addToCart({
    required int userId,
    required int productId,
    required int quantity,
    Product? product,
  }) async {
    Product currentProduct =
        product ??
        (await ProductService().getAllProducts()).firstWhere(
          (item) => item.id == productId,
          orElse: () => Product(
            id: productId,
            title: 'Product $productId',
            description: '',
            category: '',
            price: 0,
            discountPercentage: 0,
            rating: 0,
            stock: 0,
            tags: const [],
            brand: '',
            sku: '',
            weight: 0,
            dimensions: ProductDimensions(width: 0, height: 0, depth: 0),
            warrantyInformation: '',
            shippingInformation: '',
            availabilityStatus: '',
            reviews: const [],
            returnPolicy: '',
            minimumOrderQuantity: 1,
            meta: ProductMeta(
              createdAt: '',
              updatedAt: '',
              barcode: '',
              qrCode: '',
            ),
            images: const [],
            thumbnail: '',
          ),
        );

    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': currentProduct.id, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to add product to cart (status ${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    final addedCart = parseCartResponse(decoded);
    final mergedItems = List<CartItem>.from(_cart.products);

    for (final addedItem in addedCart.products) {
      final index = mergedItems.indexWhere((item) => item.id == addedItem.id);
      if (index >= 0) {
        final existingItem = mergedItems[index];
        mergedItems[index] = CartItem(
          id: existingItem.id,
          title: existingItem.title,
          price: existingItem.price,
          quantity: existingItem.quantity + addedItem.quantity,
          total: existingItem.price * (existingItem.quantity + addedItem.quantity),
          discountPercentage: existingItem.discountPercentage,
          discountedPrice: existingItem.price * (existingItem.quantity + addedItem.quantity),
          thumbnail: existingItem.thumbnail,
        );
      } else {
        mergedItems.add(addedItem);
      }
    }

    final newTotalQuantity = mergedItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final newTotal = mergedItems.fold<double>(0, (sum, item) => sum + item.total);

    _cart = Cart(
      id: _cart.id,
      userId: _cart.userId,
      products: mergedItems,
      totalProducts: mergedItems.length,
      totalQuantity: newTotalQuantity,
      total: newTotal,
      discountedTotal: newTotal,
    );
    _cartUserId = userId;
    _hasLocalCartUpdate = true;

    return _cart;
  }

  Future<Cart> updateQuantity({
    required int productId,
    required int delta,
  }) async {
    final items = List<CartItem>.from(_cart.products);
    final index = items.indexWhere((item) => item.id == productId);
    if (index < 0) return _cart;

    final item = items[index];
    final nextQty = item.quantity + delta;

    if (nextQty <= 0) {
      items.removeAt(index);
    } else {
      items[index] = CartItem(
        id: item.id,
        title: item.title,
        price: item.price,
        quantity: nextQty,
        total: item.price * nextQty,
        discountPercentage: item.discountPercentage,
        discountedPrice: item.price * nextQty,
        thumbnail: item.thumbnail,
      );
    }

    final totalQuantity = items.fold<int>(0, (sum, e) => sum + e.quantity);
    final total = items.fold<double>(0, (sum, e) => sum + e.total);

    _cart = Cart(
      id: _cart.id,
      userId: _cart.userId,
      products: items,
      totalProducts: items.length,
      totalQuantity: totalQuantity,
      total: total,
      discountedTotal: total,
    );
    _cartUserId = _cart.userId;
    _hasLocalCartUpdate = true;

    return _cart;
  }
}
