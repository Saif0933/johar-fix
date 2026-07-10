import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../models/service_model.dart';

class CategoryServicesScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryServicesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  List<ServiceModel> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final res = await ApiClient.instance.get('/customer/categories/${widget.categoryId}/services');
      if (res.data != null && res.data['success'] == true) {
        final List<dynamic> list = res.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _services = list.map((json) => ServiceModel.fromJson(json)).toList();
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching category services: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildTrustBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light blue
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'JoharFix Guarantee',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '• Verified Service Partners Only\n• 15-Day Quality Warranty\n• Damage Protection Cover',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF1E40AF),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelinesCard() {
    final guidelines = [
      {'icon': Icons.check_circle_outline, 'text': 'Service completed in 60-90 minutes by experts.'},
      {'icon': Icons.verified_user_outlined, 'text': '100% safe, background-verified professionals.'},
      {'icon': Icons.calendar_today_outlined, 'text': 'Free reschedule option up to 2 hours before schedule.'},
      {'icon': Icons.autorenew_outlined, 'text': '15-days free warranty on completed jobs.'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Instructions & Guidelines',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 14),
          ...guidelines.map((g) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(g['icon'] as IconData, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      g['text'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final itemCount = cartProvider.itemCount;
    final cartTotal = cartProvider.cartTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline, size: 64, color: AppTheme.textSecondary),
                          const SizedBox(height: 16),
                          const Text(
                            'No services available in this category.',
                            style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => context.go('/home'),
                            style: ElevatedButton.styleFrom(minimumSize: const Size(180, 44)),
                            child: const Text('Back to Home'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: itemCount > 0 ? 110 : 30,
                      ),
                      itemCount: _services.length + 2, // 1 header, 1 footer, and services
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildTrustBanner();
                        } else if (index == _services.length + 1) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildGuidelinesCard(),
                          );
                        }

                        final service = _services[index - 1];
                        final cartItem = cartProvider.cart.firstWhere(
                          (item) => item.id == service.id,
                          orElse: () => ServiceModel(id: '', name: '', description: '', basePrice: 0),
                        );
                        final quantity = cartItem.id.isNotEmpty ? cartItem.qty : 0;
                        
                        final price = service.basePrice;
                        final originalPrice = service.originalPrice ?? (price * 1.3).roundToDouble();
                        final discountPercent = ((originalPrice - price) / originalPrice * 100).round();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => context.push('/service-details', extra: {'id': service.id}),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Left side: image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      service.image ?? 'https://joharfix.com/assets/images/logo.jpeg',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_outlined),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Right side: details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${service.rating ?? "4.8"} (${service.reviewsCount ?? "120"} reviews)',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          service.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Price Info
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      '₹${price.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w900,
                                                        color: AppTheme.textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    if (originalPrice > price)
                                                      Text(
                                                        '₹${originalPrice.toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                          decoration: TextDecoration.lineThrough,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                if (originalPrice > price)
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 2),
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFE1FFE4),
                                                      borderRadius: BorderRadius.circular(3),
                                                    ),
                                                    child: Text(
                                                      '$discountPercent% OFF',
                                                      style: const TextStyle(
                                                        color: Color(0xFF00B894),
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            // Action Button
                                            SizedBox(
                                              width: 80,
                                              height: 30,
                                              child: quantity > 0
                                                  ? Container(
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.primary,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          IconButton(
                                                            onPressed: () => cartProvider.updateQty(service.id, 'dec'),
                                                            icon: const Icon(Icons.remove, size: 12, color: Colors.white),
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(),
                                                          ),
                                                          Text(
                                                            '$quantity',
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w900,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                          IconButton(
                                                            onPressed: () => cartProvider.updateQty(service.id, 'inc'),
                                                            icon: const Icon(Icons.add, size: 12, color: Colors.white),
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : OutlinedButton(
                                                      onPressed: () => cartProvider.addToCart(service),
                                                      style: OutlinedButton.styleFrom(
                                                        side: const BorderSide(color: AppTheme.primary, width: 1.5),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        padding: EdgeInsets.zero,
                                                      ),
                                                      child: const Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            'ADD',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w900,
                                                              color: AppTheme.primary,
                                                            ),
                                                          ),
                                                          Icon(Icons.add, size: 10, color: AppTheme.primary),
                                                        ],
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

          // --- STICKY BOTTOM CART BAR ---
          if (itemCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${cartTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '$itemCount ${itemCount == 1 ? "service" : "services"} added',
                          style: const TextStyle(
                            color: Color(0xFFEFF6FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => context.go('/cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 36),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Row(
                        children: [
                          Text('View Cart', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          Icon(Icons.keyboard_arrow_right, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
