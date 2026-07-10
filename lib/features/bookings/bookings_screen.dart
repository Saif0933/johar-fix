import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  List<BookingModel> _bookings = [];
  bool _loading = true;
  bool _error = false;
  String _activeTab = 'ongoing'; // 'ongoing' or 'history'
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _tabController.index == 0 ? 'ongoing' : 'history';
        });
      }
    });
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final res = await ApiClient.instance.get('/customer/bookings');
      if (res.data != null && res.data['success'] == true) {
        final List<dynamic> list = res.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _bookings = list.map((json) => BookingModel.fromJson(json)).toList();
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'icon': Icons.hourglass_empty,
          'color': const Color(0xFFF37920),
          'bg': const Color(0xFFFFF7ED),
          'label': 'Pending'
        };
      case 'upcoming':
        return {
          'icon': Icons.access_time,
          'color': const Color(0xFF004680),
          'bg': const Color(0xFFE8F1F8),
          'label': 'Upcoming'
        };
      case 'confirmed':
        return {
          'icon': Icons.check_circle_outline,
          'color': const Color(0xFF10B981),
          'bg': const Color(0xFFECFDF5),
          'label': 'Confirmed'
        };
      case 'completed':
        return {
          'icon': Icons.check_circle,
          'color': const Color(0xFF10B981),
          'bg': const Color(0xFFECFDF5),
          'label': 'Completed'
        };
      case 'cancelled':
        return {
          'icon': Icons.cancel_outlined,
          'color': const Color(0xFFEF4444),
          'bg': const Color(0xFFFEF2F2),
          'label': 'Cancelled'
        };
      case 'ongoing':
        return {
          'icon': Icons.build_outlined,
          'color': const Color(0xFFF59E0B),
          'bg': const Color(0xFFFFFBEB),
          'label': 'Ongoing'
        };
      default:
        return {
          'icon': Icons.circle_outlined,
          'color': const Color(0xFF64748B),
          'bg': const Color(0xFFF1F5F9),
          'label': status
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final selectedAddress = addressProvider.selectedAddress;

    // Filter bookings
    final historyStatuses = ['completed', 'cancelled'];
    final ongoingBookings = _bookings.where((b) => !historyStatuses.contains(b.status.toLowerCase())).toList();
    final historyBookings = _bookings.where((b) => historyStatuses.contains(b.status.toLowerCase())).toList();
    final filteredList = _activeTab == 'ongoing' ? ongoingBookings : historyBookings;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- HEADER MATCHING DASHBOARD ---
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 14,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Location selector
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/location-picker'),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://joharfix.com/assets/images/logo.jpeg',
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 34,
                              height: 34,
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.handyman, size: 18, color: AppTheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Color(0xFFF37920)),
                                  const SizedBox(width: 3),
                                  Text(
                                    selectedAddress != null
                                        ? (selectedAddress.label ?? selectedAddress.landmark)
                                        : 'Select Location',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.keyboard_arrow_down, size: 12, color: Color(0xFF1E293B)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedAddress != null
                                    ? [
                                        selectedAddress.houseNo,
                                        selectedAddress.landmark,
                                        selectedAddress.city
                                      ].where((s) => s != null && s.isNotEmpty).join(', ')
                                    : 'Select current location...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
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
                const SizedBox(width: 8),
                // Search & Profile action buttons
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.push('/search'),
                      borderRadius: BorderRadius.circular(19),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        child: const Icon(Icons.search, size: 22, color: Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            authProvider.avatarIndex >= 0 && authProvider.avatarIndex < 6
                                ? [
                                    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                                    'https://cdn-icons-png.flaticon.com/512/3135/3135768.png',
                                    'https://cdn-icons-png.flaticon.com/512/4140/4140037.png',
                                    'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
                                    'https://cdn-icons-png.flaticon.com/512/4140/4140061.png',
                                    'https://cdn-icons-png.flaticon.com/512/4139/4139981.png'
                                  ][authProvider.avatarIndex]
                                : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                          ),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- TAB SWITCHER ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  // Sliding white background pill
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: _activeTab == 'ongoing'
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Clickable tabs layer
                  Positioned.fill(
                    child: Row(
                      children: [
                        _buildTabItem('ongoing', 'Ongoing', Icons.access_time, ongoingBookings.length),
                        _buildTabItem('history', 'History', Icons.receipt_long_outlined, historyBookings.length),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOOKING LISTING ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ApiClient.instance.clearCache();
                await _fetchBookings();
              },
              color: AppTheme.primary,
              child: _loading
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildShimmerCard(),
                        _buildShimmerCard(),
                        _buildShimmerCard(),
                      ],
                    )
                  : _error
                      ? _buildErrorState()
                      : filteredList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                return _buildBookingCard(filteredList[index]);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String key, String label, IconData icon, int count) {
    final isSelected = _activeTab == key;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _activeTab = key;
          });
        },
        child: Container(
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppTheme.primary : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.primary : const Color(0xFF64748B),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8F1F8) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppTheme.primary : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 65, height: 12, color: const Color(0xFFE2E8F0)),
              Container(width: 55, height: 16, color: const Color(0xFFE2E8F0)),
            ],
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 900.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 48, height: 48, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 12, color: const Color(0xFFE2E8F0)),
                    const SizedBox(height: 6),
                    Container(width: 80, height: 10, color: const Color(0xFFE2E8F0)),
                  ],
                ),
              ),
            ],
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 900.ms),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off, size: 32, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              const Text(
                "Couldn't load bookings. Check your connection.",
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchBookings,
                icon: const Icon(Icons.refresh, size: 15, color: Colors.white),
                label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F1F8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _activeTab == 'ongoing' ? Icons.calendar_today : Icons.receipt_long,
                    size: 36,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${_activeTab == 'ongoing' ? 'active' : 'past'} bookings',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _activeTab == 'ongoing'
                      ? "You don't have any upcoming bookings"
                      : 'Your completed bookings will appear here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                if (_activeTab == 'ongoing') ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                    label: const Text('Book a Service', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final sc = _getStatusConfig(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Show bottom sheet or snackbar since detailed view is out of scope / not implemented
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Details for Booking #${booking.id.substring(booking.id.length - 8).toUpperCase()} coming soon!')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top category chip & status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      booking.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sc['bg'] as Color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sc['icon'] as IconData, size: 10, color: sc['color'] as Color),
                        const SizedBox(width: 4),
                        Text(
                          sc['label'] as String,
                          style: TextStyle(
                            color: sc['color'] as Color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Body info row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      booking.image.isNotEmpty ? booking.image : 'https://joharfix.com/assets/images/logo.jpeg',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 48,
                        height: 48,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.image_outlined, size: 20, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.service,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 11, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              booking.date,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.access_time, size: 11, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              booking.time,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 11, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking.partner,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
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
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.price.startsWith('₹') ? booking.price : '₹${booking.price}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 12, color: AppTheme.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
