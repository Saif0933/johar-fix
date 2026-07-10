import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/category_model.dart';
import '../../models/service_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CategoryModel> _categories = [];
  List<ServiceModel> _featuredServices = [];
  List<ServiceModel> _bestsellers = [];
  
  bool _categoriesLoading = true;
  bool _featuredLoading = true;
  bool _bestsellersLoading = true;
  final int _activePromoIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    _fetchCategories();
    _fetchFeaturedServices();
    _fetchBestsellers();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiClient.instance.get('/customer/categories');
      if (res.data != null && res.data['success'] == true) {
        final List<dynamic> list = res.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _categories = list.map((json) => CategoryModel.fromJson(json)).toList();
            _categoriesLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _fetchFeaturedServices() async {
    try {
      final res = await ApiClient.instance.get('/customer/services/featured');
      if (res.data != null && res.data['success'] == true) {
        final List<dynamic> list = res.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _featuredServices = list.map((json) => ServiceModel.fromJson(json)).toList();
            _featuredLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching featured services: $e');
      if (mounted) setState(() => _featuredLoading = false);
    }
  }

  Future<void> _fetchBestsellers() async {
    try {
      final res = await ApiClient.instance.get('/customer/services/bestseller');
      if (res.data != null && res.data['success'] == true) {
        final List<dynamic> list = res.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _bestsellers = list.map((json) => ServiceModel.fromJson(json)).toList();
            _bestsellersLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching bestseller services: $e');
      if (mounted) setState(() => _bestsellersLoading = false);
    }
  }

  Widget _buildShimmerBox({required double width, required double height, double borderRadius = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(duration: 1200.ms, color: Colors.grey[100]);
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    
    final selectedAddress = addressProvider.selectedAddress;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER TOP ROW (Address, Search, Profile) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppTheme.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // App Brand Logo + Address Details
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/location-picker'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.build_rounded, size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 14, color: AppTheme.secondary),
                                      const SizedBox(width: 3),
                                      Text(
                                        selectedAddress != null 
                                            ? selectedAddress.type.toUpperCase() 
                                            : 'SELECT LOCATION',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down, size: 14, color: AppTheme.textPrimary),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedAddress != null
                                        ? '${selectedAddress.houseNo ?? ""}, ${selectedAddress.landmark}, ${selectedAddress.city}'
                                        : 'Find and set your address...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Header Action Buttons
                  Row(
                    children: [
                      // Search button
                      IconButton(
                        onPressed: () => context.push('/search'),
                        icon: const Icon(Icons.search, color: AppTheme.primary),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.surface,
                          side: const BorderSide(color: AppTheme.border, width: 1.2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Profile Avatar
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: AppTheme.border,
                          backgroundImage: NetworkImage(
                            'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- MAIN SCROLL CONTENT ---
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ApiClient.instance.clearCache();
                  await _fetchDashboardData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- POPULAR SEARCH CHIPS ---
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            'AC Service ❄️',
                            'Deep Cleaning 🧹',
                            'Electrician ⚡',
                            'Plumbing 🔧',
                            'Salon 💇'
                          ].map((tag) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                backgroundColor: AppTheme.surface,
                                side: const BorderSide(color: AppTheme.border, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                onPressed: () {
                                  final query = tag.split(' ').first;
                                  context.push('/search', extra: {'query': query});
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // --- PROMO BANNER CAROUSEL ---
                      _buildPromoSlider(),

                      const SizedBox(height: 24),

                      // --- CATEGORIES SECTIONS ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Category',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Choose from our verified professional services',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCategoriesGrid(),

                      const SizedBox(height: 28),

                      // --- BEST SELLERS SECTIONS ---
                      _buildBestsellersSection(cartProvider),

                      const SizedBox(height: 24),

                      // --- FOOTER SAFETY BADGE ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border, width: 1),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_outlined, color: AppTheme.primary, size: 20),
                              SizedBox(width: 10),
                              Text(
                                '100% Safe & Standard doorstep services',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Promo Slider widget
  Widget _buildPromoSlider() {
    if (_featuredLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildShimmerBox(width: double.infinity, height: 160, borderRadius: 20),
      );
    }

    if (_featuredServices.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.78;

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _featuredServices.length,
            itemExtent: cardWidth + 14,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final service = _featuredServices[index];
              final hasDiscount = service.originalPrice != null && service.originalPrice! > service.basePrice;
              final discountPct = hasDiscount 
                  ? ((service.originalPrice! - service.basePrice) / service.originalPrice! * 100).round()
                  : null;

              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () => context.push('/service-details', extra: {'id': service.id}),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Background Banner Image
                          Positioned.fill(
                            child: Image.network(
                              service.image ?? 'https://joharfix.com/assets/images/logo.jpeg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(color: AppTheme.primary);
                              },
                            ),
                          ),
                          // Dark gradient overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppTheme.primary.withValues(alpha: 0.15),
                                    Colors.black.withValues(alpha: 0.85),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Card content
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    discountPct != null 
                                        ? 'SPECIAL OFFER • $discountPct% OFF' 
                                        : 'RECOMMENDED SERVICE',
                                    style: const TextStyle(
                                      color: AppTheme.secondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Book @ ₹${service.basePrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
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
                ),
              );
            },
          ),
        ),
        
        // Indicator Dots
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_featuredServices.length, (idx) {
            return AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _activePromoIndex == idx ? 12 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _activePromoIndex == idx ? AppTheme.primary : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Categories Grid widget
  Widget _buildCategoriesGrid() {
    if (_categoriesLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 100,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => _buildShimmerBox(width: double.infinity, height: 100, borderRadius: 16),
        ),
      );
    }

    if (_categories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 100,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return GestureDetector(
            onTap: () => context.push('/category-services', extra: {
              'id': cat.id,
              'category': cat.name,
            }),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Category Background Image
                    Positioned.fill(
                      child: Image.network(
                        cat.image ?? 'https://joharfix.com/assets/images/logo.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: AppTheme.primary),
                      ),
                    ),
                    // Dark Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Watermark Icon
                    if (cat.image == null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.15), size: 36),
                      ),
                    // Category Title Name
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Text(
                        cat.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Bestsellers list widget
  Widget _buildBestsellersSection(CartProvider cartProvider) {
    if (_bestsellersLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildShimmerBox(width: double.infinity, height: 110),
            const SizedBox(height: 12),
            _buildShimmerBox(width: double.infinity, height: 110),
          ],
        ),
      );
    }

    if (_bestsellers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Best Sellers Near You',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Most booked and highly rated services in your area',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              mainAxisExtent: 220,
            ),
            itemCount: _bestsellers.length,
            itemBuilder: (context, index) {
              final service = _bestsellers[index];
              final cartItem = cartProvider.cart.firstWhere(
                (item) => item.id == service.id,
                orElse: () => ServiceModel(id: '', name: '', description: '', basePrice: 0),
              );
              final quantity = cartItem.id.isNotEmpty ? cartItem.qty : 0;

              return GestureDetector(
                onTap: () => context.push('/service-details', extra: {'id': service.id}),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.network(
                                  service.image ?? 'https://joharfix.com/assets/images/logo.jpeg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
                                ),
                              ),
                              // Rating Badge
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 10),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${service.rating ?? "4.9"} (${service.reviewsCount ?? "150+"})',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Details & Actions
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${service.basePrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              
                              // Add / Qty Control button
                              SizedBox(
                                height: 32,
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
                                              icon: const Icon(Icons.remove, size: 14, color: Colors.white),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            Text(
                                              '$quantity',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => cartProvider.updateQty(service.id, 'inc'),
                                              icon: const Icon(Icons.add, size: 14, color: Colors.white),
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
                                          minimumSize: const Size(double.infinity, 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'ADD',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                            Icon(Icons.add, size: 12, color: AppTheme.primary),
                                          ],
                                        ),
                                      ),
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
        ),
      ],
    );
  }
}
