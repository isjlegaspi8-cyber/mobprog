import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class CartScreen extends StatefulWidget {
  final bool showAppBar;

  const CartScreen({super.key, this.showAppBar = true});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<Cart> _cartFuture;

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  /// Enhancement 3: the cart is rendered **by userId** taken from the saved
  /// SharedPreferences data instead of the hardcoded id used before.
  void _refreshCart() {
    setState(() {
      _cartFuture = _loadCartForSavedUser();
    });
  }

  /// Reads the persisted user, then asks CartService for that user's cart.
  Future<Cart> _loadCartForSavedUser() async {
    final user = await UserService().getUser();
    if (!user.isValid) {
      throw Exception('No saved user id - please sign in again.');
    }
    return CartService().getUserCart(userId: user.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              title: const CustomText(
                text: 'Cart',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),
              ],
            )
          : null,
      body: FutureBuilder<Cart>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: CustomText(
                text: 'Error: ${snapshot.error}',
                fontSize: 14.sp,
              ),
            );
          }

          final cart = snapshot.data ?? CartService.cart;
          if (cart.products.isEmpty) {
            return const Center(
              child: CustomText(text: 'Your cart is empty.', fontSize: 16),
            );
          }

          return Center(
            child: Container(
              width: 360.w,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.products.length,
                      itemBuilder: (context, index) {
                        final item = cart.products[index];

                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10.r),
                                child: item.thumbnail.isNotEmpty
                                    ? Image.network(
                                        item.thumbnail,
                                        width: 62.w,
                                        height: 62.h,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 62.w,
                                                  height: 62.h,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(
                                                    Icons.image,
                                                  ),
                                                ),
                                      )
                                    : Container(
                                        width: 62.w,
                                        height: 62.h,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image),
                                      ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: item.title,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4.h),
                                    CustomText(
                                      text:
                                          '\$${item.price.toStringAsFixed(2)}',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    SizedBox(height: 4.h),
                                    CustomText(
                                      text:
                                          '${item.quantity}x  -  \$${item.total.toStringAsFixed(2)} total',
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Column(
                                children: [
                                  SizedBox(
                                    width: 28.w,
                                    height: 28.h,
                                    child: FloatingActionButton.small(
                                      heroTag: 'add_${item.id}',
                                      backgroundColor: const Color(0xFFF5D76E),
                                      foregroundColor: Colors.black,
                                      onPressed: () async {
                                        await CartService().updateQuantity(
                                          productId: item.id,
                                          delta: 1,
                                        );
                                        _refreshCart();
                                      },
                                      child: const Icon(Icons.add, size: 18),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  CustomText(
                                    text: item.quantity.toString(),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  SizedBox(height: 8.h),
                                  SizedBox(
                                    width: 28.w,
                                    height: 28.h,
                                    child: FloatingActionButton.small(
                                      heroTag: 'remove_${item.id}',
                                      backgroundColor: const Color(0xFFF5D76E),
                                      foregroundColor: Colors.black,
                                      onPressed: () async {
                                        await CartService().updateQuantity(
                                          productId: item.id,
                                          delta: -1,
                                        );
                                        _refreshCart();
                                      },
                                      child: const Icon(Icons.remove, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const CustomText(
                          text: 'Subtotal:',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        CustomText(
                          text: '\$${cart.discountedTotal.toStringAsFixed(2)}',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const CustomText(
                        text: 'Confirm Order',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
