import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 2: full details page navigated to from a tapped product card.
class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isAdding = false;

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);

    try {
      await CartService().addToCart(
        userId: 1,
        productId: widget.product.id,
        quantity: 1,
        product: widget.product,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/cart');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    widget.product.thumbnail,
                    width: double.infinity,
                    height: 260.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 260.h,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, size: 48),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: widget.product.title,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 4.h),
                        CustomText(
                          text: '\$${widget.product.price.toStringAsFixed(2)}',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(height: 12.h),
                        CustomText(
                          text: widget.product.description,
                          fontSize: 14.sp,
                        ),
                        SizedBox(height: 16.h),
                        CustomText(
                          text: 'Brand: ${widget.product.brand}',
                          fontSize: 13.sp,
                        ),
                        CustomText(
                          text: 'Rating: ${widget.product.rating}',
                          fontSize: 13.sp,
                        ),
                        CustomText(
                          text: 'Stock: ${widget.product.stock}',
                          fontSize: 13.sp,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: SizedBox(
                  width: 220.w,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _isAdding ? null : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isAdding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const CustomText(
                            text: 'Add to cart',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
