import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../models/service_model.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  ServiceModel? _service;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
  }

  Future<void> _fetchServiceDetails() async {
    try {
      final res = await ApiClient.instance.get('/customer/services/${widget.serviceId}');
      if (res.data != null && res.data['success'] == true) {
        if (mounted) {
          setState(() {
            _service = ServiceModel.fromJson(res.data['data']);
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching service details: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    
    // Find matching item in cart to display quantity
    final cartItem = _service != null
        ? cartProvider.cart.firstWhere(
            (item) => item.id == _service!.id,
            orElse: () => ServiceModel(id: '', name: '', description: '', basePrice: 0),
          )
        : null;
    final quantity = (cartItem != null && cartItem.id.isNotEmpty) ? cartItem.qty : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _service == null
              ? const Center(child: Text('Service details not found.'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Banner Header
                      Image.network(
                        _service!.image ?? 'https://joharfix.com/assets/images/logo.jpeg',
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_outlined, size: 48),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Price Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _service!.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_service!.rating ?? "4.9"} (120+ reviews)',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '₹${_service!.basePrice.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 32, color: AppTheme.border),

                            // Description Section
                            Text(
                              'Service Description',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _service!.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),

                            const Divider(height: 32, color: AppTheme.border),

                            // What is included
                            Text(
                              'What is Included',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildBulletItem('Professional diagnosis of faults'),
                            _buildBulletItem('Complete cleanup after completion of work'),
                            _buildBulletItem('High quality materials and service parts'),
                            _buildBulletItem('15-day service quality warranty protection'),

                            const SizedBox(height: 20),

                            // What is excluded
                            Text(
                              'What is Excluded',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildBulletItem('Any extra spare parts required will be charged extra', isCross: true),
                            _buildBulletItem('Pre-existing device damage unrelated to requested service', isCross: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _service == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.border, width: 1.2)),
              ),
              child: Row(
                children: [
                  // Qty adjust
                  Expanded(
                    child: quantity > 0
                        ? Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => cartProvider.updateQty(_service!.id, 'dec'),
                                  icon: const Icon(Icons.remove, color: AppTheme.primary),
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => cartProvider.updateQty(_service!.id, 'inc'),
                                  icon: const Icon(Icons.add, color: AppTheme.primary),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () => cartProvider.addToCart(_service!),
                            child: const Text('Add to Cart'),
                          ),
                  ),
                  
                  if (quantity > 0) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/cart'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                        child: const Text('Go to Cart'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBulletItem(String text, {bool isCross = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCross ? Icons.cancel_outlined : Icons.check_circle_outline,
            color: isCross ? AppTheme.error : AppTheme.success,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
