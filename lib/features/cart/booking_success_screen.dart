import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String? bookingId;
  final String? totalAmount;
  final String? paymentMethod;
  final String? bookingDate;
  final String? timeSlot;
  final String? serviceName;

  const BookingSuccessScreen({
    super.key,
    this.bookingId,
    this.totalAmount,
    this.paymentMethod,
    this.bookingDate,
    this.timeSlot,
    this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = paymentMethod == 'online';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Booking Status',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.close, color: AppTheme.textPrimary, size: 24),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.border,
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    // Hero Section (Checkmark & Text)
                    Column(
                      children: [
                        // Animated green checkmark
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFDCFCE7),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF86EFAC),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF16A34A),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x4D16A34A),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .scale(
                              duration: 500.ms,
                              curve: Curves.elasticOut,
                              begin: const Offset(0.4, 0.4),
                              end: const Offset(1.0, 1.0),
                            )
                            .fadeIn(duration: 250.ms),

                        const SizedBox(height: 20),

                        // Title
                        Text(
                          'Booking Confirmed!',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 300.ms)
                            .slideY(begin: 0.15, end: 0.0),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Your service has been booked successfully.\nWe\'ll notify you when a provider is assigned.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 250.ms, duration: 300.ms)
                            .slideY(begin: 0.15, end: 0.0),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Booking Details Card
                    Card(
                      elevation: 3,
                      shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppTheme.border, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.assignment_outlined, color: AppTheme.primary, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'BOOKING DETAILS',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isPaid ? 'Paid' : 'Pay Later',
                                        style: GoogleFonts.inter(
                                          color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Service Name Chip
                            if (serviceName != null && serviceName!.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.construction_outlined, color: AppTheme.primary, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        serviceName!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Details Grid (2 columns, 2 rows)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final itemWidth = constraints.maxWidth / 2;
                                return Wrap(
                                  runSpacing: 16,
                                  children: [
                                    // Booking ID
                                    SizedBox(
                                      width: itemWidth,
                                      child: Row(
                                        children: [
                                          _buildIconBox(Icons.receipt_long_outlined),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildGridLabel('BOOKING ID'),
                                                _buildGridValue('#${bookingId ?? "N/A"}'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Amount
                                    SizedBox(
                                      width: itemWidth,
                                      child: Row(
                                        children: [
                                          _buildIconBox(Icons.local_offer_outlined),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildGridLabel('AMOUNT'),
                                                Text(
                                                  '₹${totalAmount ?? "0.00"}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
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
                                    // Date
                                    SizedBox(
                                      width: itemWidth,
                                      child: Row(
                                        children: [
                                          _buildIconBox(Icons.calendar_today_outlined),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildGridLabel('DATE'),
                                                _buildGridValue(bookingDate ?? "N/A"),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Time slot
                                    SizedBox(
                                      width: itemWidth,
                                      child: Row(
                                        children: [
                                          _buildIconBox(Icons.access_time),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildGridLabel('TIME SLOT'),
                                                _buildGridValue(timeSlot ?? "N/A"),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Payment Method Row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPaid ? Icons.credit_card_outlined : Icons.payments_outlined,
                                    size: 16,
                                    color: const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isPaid
                                          ? 'Paid via Online Payment (Razorpay)'
                                          : 'Cash on Service - Pay after completion',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
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
                        .fadeIn(delay: 350.ms, duration: 350.ms)
                        .slideY(begin: 0.1, end: 0.0),

                    const SizedBox(height: 14),

                    // Notice Bar
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.notifications_outlined, color: AppTheme.primary, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Our service provider will contact you shortly to coordinate their arrival.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF1D4ED8),
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 450.ms, duration: 350.ms),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Buttons Container
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 12
                    : 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go('/bookings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppTheme.primary.withValues(alpha: 0.25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'View My Bookings',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.home_outlined, size: 18, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Back to Home',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 550.ms, duration: 300.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppTheme.primary, size: 16),
    );
  }

  Widget _buildGridLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGridValue(String value) {
    return Text(
      value,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1E293B),
        height: 1.25,
      ),
    );
  }
}
