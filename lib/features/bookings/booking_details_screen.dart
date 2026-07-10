import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  BookingModel? _booking;
  bool _loading = true;
  bool _error = false;
  bool _cancelling = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_booking != null &&
          _booking!.status.toLowerCase() != 'completed' &&
          _booking!.status.toLowerCase() != 'cancelled') {
        _fetchBookingDetails(silent: true);
      }
    });
  }

  Future<void> _fetchBookingDetails({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }

    try {
      final res = await ApiClient.instance.get('/customer/bookings');
      if (res.data != null && res.data['success'] == true) {
        final List<dynamic> list = res.data['data'] ?? [];
        final foundJson = list.firstWhere(
          (json) => json['id']?.toString() == widget.bookingId,
          orElse: () => null,
        );

        if (foundJson != null) {
          if (mounted) {
            setState(() {
              _booking = BookingModel.fromJson(foundJson);
              _loading = false;
              _error = false;
            });
          }
        } else {
          // If not found in list, try to request directly as fallback
          try {
            final singleRes = await ApiClient.instance.get('/customer/bookings/${widget.bookingId}');
            if (singleRes.data != null && singleRes.data['success'] == true) {
              if (mounted) {
                setState(() {
                  _booking = BookingModel.fromJson(singleRes.data['data']);
                  _loading = false;
                  _error = false;
                });
              }
              return;
            }
          } catch (singleErr) {
            debugPrint('Error fetching fallback single booking: $singleErr');
          }

          if (!silent && mounted) {
            setState(() {
              _loading = false;
              _error = true;
            });
          }
        }
      } else {
        if (!silent && mounted) {
          setState(() {
            _loading = false;
            _error = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching booking details: $e');
      if (!silent && mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint('Could not launch phone call dialer: $e');
    }
  }

  Future<void> _handleCancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Booking',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _cancelling = true);
      try {
        final res = await ApiClient.instance.post('/customer/bookings/${widget.bookingId}/cancel');
        if (res.data != null && res.data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking has been cancelled successfully.')),
            );
            _fetchBookingDetails();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res.data?['message'] ?? 'Failed to cancel booking.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Something went wrong. Please try again.')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _cancelling = false);
        }
      }
    }
  }

  Map<String, dynamic> _getStatusDetails(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return {
          'label': 'Completed',
          'bg': const Color(0xFFECFDF5),
          'color': const Color(0xFF10B981),
          'icon': Icons.check_circle_outline
        };
      case 'ongoing':
      case 'in progress':
      case 'in_progress':
        return {
          'label': 'In Progress',
          'bg': const Color(0xFFFFF7ED),
          'color': const Color(0xFFF59E0B),
          'icon': Icons.sync
        };
      case 'on the way':
      case 'on_the_way':
        return {
          'label': 'On The Way',
          'bg': const Color(0xFFEFF6FF),
          'color': const Color(0xFF3B82F6),
          'icon': Icons.directions_bike
        };
      case 'confirmed':
        return {
          'label': 'Confirmed',
          'bg': const Color(0xFFEBF4FA),
          'color': const Color(0xFF004680),
          'icon': Icons.calendar_today_outlined
        };
      case 'cancelled':
        return {
          'label': 'Cancelled',
          'bg': const Color(0xFFFEF2F2),
          'color': const Color(0xFFEF4444),
          'icon': Icons.cancel_outlined
        };
      default:
        return {
          'label': 'Pending',
          'bg': const Color(0xFFF1F5F9),
          'color': const Color(0xFF64748B),
          'icon': Icons.access_time
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 14),
              Text(
                'Loading details...',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (_error || _booking == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Booking Not Found',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Text(
                  'We couldn\'t load this booking details. Please try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final booking = _booking!;
    final statusInfo = _getStatusDetails(booking.status);
    final hasPartner = booking.partner.isNotEmpty && booking.partner != 'Not Assigned' && booking.partner != 'Assigning partner...';

    // Map Coordinates Check
    final hasValidCoords = booking.latitude != null &&
        booking.longitude != null &&
        booking.partnerLatitude != null &&
        booking.partnerLongitude != null &&
        booking.latitude != 0 &&
        booking.partnerLatitude != 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Booking Details',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- SERVICE HERO CARD ---
            Card(
              elevation: 3,
              shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Image.network(
                      booking.image.isNotEmpty ? booking.image : 'https://joharfix.com/assets/images/logo.jpeg',
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 120,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.image_outlined, size: 40, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.bookingNumber ?? '#URB00${booking.id}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  booking.service,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusInfo['bg'] as Color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusInfo['icon'] as IconData,
                                  size: 13,
                                  color: statusInfo['color'] as Color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusInfo['label'] as String,
                                  style: GoogleFonts.inter(
                                    color: statusInfo['color'] as Color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1, end: 0.0),

            const SizedBox(height: 12),

            // --- STATUS TIMELINE ---
            _buildStatusTimeline(booking)
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 12),

            // --- OTP CARD ---
            if (booking.status.toLowerCase() != 'completed' && booking.status.toLowerCase() != 'cancelled')
              _buildOtpCard(booking)
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 300.ms),

            const SizedBox(height: 12),

            // --- PARTNER EXPERT DETAILS ---
            _buildPartnerCard(booking, hasPartner)
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),

            const SizedBox(height: 12),

            // --- SCHEDULE & LOCATION CARD ---
            _buildScheduleLocationCard(booking, hasValidCoords)
                .animate()
                .fadeIn(delay: 250.ms, duration: 300.ms),

            const SizedBox(height: 12),

            // --- PAYMENT SUMMARY CARD ---
            _buildPaymentSummaryCard(booking)
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 12),

            // --- BOTTOM ACTIONS ---
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  if (booking.status.toLowerCase() == 'upcoming' || booking.status.toLowerCase() == 'pending' || booking.status.toLowerCase() == 'confirmed')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _cancelling ? null : _handleCancelBooking,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF5F5),
                            side: const BorderSide(color: Color(0xFFFFD2D2), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _cancelling
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          label: Text(
                            'Cancel Booking',
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _makeCall('1800123456'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFEBF4FA),
                        side: const BorderSide(color: Color(0xFFBDD6E6), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.help_outline, size: 18, color: AppTheme.primary),
                      label: Text(
                        'Need Help? Call Support',
                        style: GoogleFonts.inter(
                          color: AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 350.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(BookingModel booking) {
    if (booking.status.toLowerCase() == 'cancelled') {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking Status',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Cancelled',
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'This booking was cancelled and is no longer active.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final raw = booking.rawStatus?.toLowerCase() ?? '';
    final hasPartner = booking.partner.isNotEmpty &&
        booking.partner != 'Not Assigned' &&
        booking.partner != 'Assigning partner...';

    final steps = [
      {
        'title': 'Booking Placed',
        'desc': 'Created on ${booking.createdAt ?? booking.date}',
        'completed': true,
        'active': true
      },
      {
        'title': hasPartner ? 'Partner Assigned' : 'Assigning Partner',
        'desc': hasPartner ? 'Assigned to ${booking.partner}' : 'Finding the best expert near you',
        'completed': hasPartner,
        'active': true
      },
      {
        'title': 'Partner On The Way',
        'desc': raw == 'on_the_way'
            ? 'Partner is heading to your location'
            : (raw == 'started' || raw == 'completed'
                ? 'Partner reached your location'
                : 'Partner will start journey soon'),
        'completed': raw == 'on_the_way' || raw == 'started' || raw == 'completed',
        'active': raw == 'on_the_way' || raw == 'started' || raw == 'completed'
      },
      {
        'title': 'Service in Progress',
        'desc': raw == 'started'
            ? 'Expert is working at your location'
            : (raw == 'completed' ? 'Service was successfully done' : 'OTP verification pending to start'),
        'completed': raw == 'started' || raw == 'completed',
        'active': raw == 'started' || raw == 'completed'
      },
      {
        'title': 'Service Completed',
        'desc': raw == 'completed' ? 'Thank you for choosing us!' : 'Pending completion',
        'completed': raw == 'completed',
        'active': raw == 'completed'
      }
    ];

    return Card(
      elevation: 2,
      shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Progress',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                final isLast = index == steps.length - 1;
                final isCompleted = step['completed'] as bool;
                final isActive = step['active'] as bool;
                final color = isCompleted
                    ? const Color(0xFF10B981)
                    : (isActive ? AppTheme.primary : const Color(0xFF94A3B8));

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                          alignment: Alignment.center,
                          child: isCompleted
                              ? const Icon(Icons.check, size: 10, color: Colors.white)
                              : null,
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 35,
                            color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                              color: isActive ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step['desc'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpCard(BookingModel booking) {
    final raw = booking.rawStatus?.toLowerCase() ?? '';
    if (raw == 'confirmed' || raw == 'on_the_way') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Text(
              'Start Job OTP',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF004680),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.otpStart ?? '••••',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF004680),
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Share this OTP with the partner when they arrive at your location to start the service.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    } else if (raw == 'started') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Text(
              'End Job OTP',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF065F46),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.otpEnd ?? '••••',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF065F46),
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Share this OTP with the partner once the service is successfully completed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPartnerCard(BookingModel booking, bool hasPartner) {
    if (!hasPartner) {
      return Card(
        elevation: 2,
        shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        color: Colors.white,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
              SizedBox(height: 12),
              Text(
                'Finding Your Expert...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary),
              ),
              SizedBox(height: 6),
              Text(
                'We are assigning the best professional near you. You will receive an alert once accepted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Expert Details',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (booking.partnerAvatar != null && booking.partnerAvatar!.isNotEmpty)
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(booking.partnerAvatar!),
                    backgroundColor: Colors.white,
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEBF4FA),
                      border: Border.all(color: const Color(0xFFBDD6E6)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      booking.partner.isNotEmpty ? booking.partner[0].toUpperCase() : 'P',
                      style: GoogleFonts.inter(
                        color: AppTheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.partner,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            booking.partnerRating?.toString() ?? '4.8',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '• Professional',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      if (booking.estimatedArrivalMinutes != null &&
                          booking.status.toLowerCase() != 'completed' &&
                          booking.status.toLowerCase() != 'cancelled')
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF4FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 12, color: AppTheme.primary),
                              const SizedBox(width: 3),
                              Text(
                                'Arriving in ~${booking.estimatedArrivalMinutes} mins',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (booking.partnerPhone != null &&
                    booking.partnerPhone!.isNotEmpty &&
                    booking.status.toLowerCase() != 'completed' &&
                    booking.status.toLowerCase() != 'cancelled')
                  GestureDetector(
                    onTap: () => _makeCall(booking.partnerPhone!),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.phone, size: 18, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleLocationCard(BookingModel booking, bool hasValidCoords) {
    return Card(
      elevation: 2,
      shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule & Location',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF4FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.calendar_today, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule Date & Time',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${booking.date} at ${booking.time}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (booking.address != null && booking.address!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF4FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.location_on, size: 18, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Address',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.address!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (hasValidCoords &&
                booking.status.toLowerCase() != 'completed' &&
                booking.status.toLowerCase() != 'cancelled') ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        (booking.latitude! + booking.partnerLatitude!) / 2,
                        (booking.longitude! + booking.partnerLongitude!) / 2,
                      ),
                      zoom: 14.0,
                    ),
                    mapType: MapType.hybrid,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('customer'),
                        position: LatLng(booking.latitude!, booking.longitude!),
                        infoWindow: const InfoWindow(title: 'My Location'),
                      ),
                      Marker(
                        markerId: const MarkerId('partner'),
                        position: LatLng(booking.partnerLatitude!, booking.partnerLongitude!),
                        infoWindow: InfoWindow(title: booking.partner),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                      ),
                    },
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: [
                          LatLng(booking.partnerLatitude!, booking.partnerLongitude!),
                          LatLng(booking.latitude!, booking.longitude!),
                        ],
                        color: AppTheme.primary,
                        width: 4,
                        patterns: [PatternItem.dash(10), PatternItem.gap(10)],
                      ),
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard(BookingModel booking) {
    if (booking.paymentSummary == null) {
      return const SizedBox.shrink();
    }

    final summary = booking.paymentSummary!;
    final isCash = booking.paymentMethod?.toLowerCase() == 'cash';

    return Card(
      elevation: 2,
      shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            // Item Total
            _buildBillRow('Item Total', '₹${summary.subtotal.toStringAsFixed(2)}'),

            // Coupon Discount
            if (summary.discount > 0)
              _buildBillRow(
                'Coupon Discount',
                '- ₹${summary.discount.toStringAsFixed(2)}',
                valueColor: const Color(0xFF10B981),
                labelColor: const Color(0xFF10B981),
                isBold: true,
              ),

            // Convenience Fee
            if (summary.serviceFee > 0)
              _buildBillRow('Service & Convenience Fee', '₹${summary.serviceFee.toStringAsFixed(2)}'),

            // Taxes
            if (summary.gstAmount > 0) ...[
              if (summary.cgst > 0) ...[
                _buildBillRow('CGST (${(summary.gstRate / 2).toStringAsFixed(1)}%)', '₹${summary.cgst.toStringAsFixed(2)}'),
                _buildBillRow('SGST (${(summary.gstRate / 2).toStringAsFixed(1)}%)', '₹${summary.sgst.toStringAsFixed(2)}'),
              ] else ...[
                _buildBillRow('IGST (${summary.gstRate.toStringAsFixed(1)}%)', '₹${summary.gstAmount.toStringAsFixed(2)}'),
              ],
            ],

            // Addons list
            if (booking.addons != null && booking.addons!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              Text(
                'Addons & Extra Charges',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              ...booking.addons!.map((addon) {
                final isOutside = addon['is_outside'] == true;
                final name = addon['name']?.toString() ?? 'Addon';
                final price = double.tryParse(addon['price']?.toString() ?? '0.0') ?? 0.0;
                return _buildBillRow(
                  isOutside ? '[Outside Part] $name' : name,
                  '₹${price.toStringAsFixed(2)}',
                );
              }),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // To Pay
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'To Pay',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                    fontSize: 15,
                  ),
                ),
                Text(
                  '₹${summary.total.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),

            if (booking.paymentMethod != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCash ? Icons.payments_outlined : Icons.credit_card_outlined,
                      size: 14,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Paid via ${booking.paymentMethod!.toUpperCase()} (${booking.paymentStatus ?? "Pending"})',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: labelColor ?? const Color(0xFF64748B),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: valueColor ?? const Color(0xFF1E293B),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
