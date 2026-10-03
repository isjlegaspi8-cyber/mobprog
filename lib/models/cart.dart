class Cart {
  final int id;
  final int userId;
  final List<CartItem> products;
  final int totalProducts;
  final int totalQuantity;
  final double total;
  final double discountedTotal;

  Cart({
    required this.id,
    required this.userId,
    required this.products,
    required this.totalProducts,
    required this.totalQuantity,
    required this.total,
    required this.discountedTotal,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      products: (json['products'] as List? ?? [])
          .map((item) => CartItem.fromJson(item))
          .toList(),
      totalProducts: json['totalProducts'] ?? 0,
      totalQuantity: json['totalQuantity'] ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountedTotal: (json['discountedTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CartItem {
  final int id;
  final String title;
  final double price;
  final int quantity;
  final double total;
  final double discountPercentage;
  final double discountedPrice;
  final String thumbnail;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    required this.discountPercentage,
    required this.discountedPrice,
    this.thumbnail = '',
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble() ?? 0.0,
      thumbnail: json['thumbnail'] ?? json['image'] ?? '',
    );
  }
}
