import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../core/network/api_client.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  // Local state for scheduling
  String _scheduleType = 'ASAP';
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = 'ASAP';
  bool _showSlotsPicker = false;

  // Local state for coupons and settings
  Map<String, dynamic> _settings = {};
  List<dynamic> _coupons = [];
  List<dynamic> _slots = [];
  bool _loadingSlots = false;
  // ignore: unused_field
  bool _loadingSettings = false;
  bool _loadingCoupons = false;

  // Applied Coupon state
  Map<String, dynamic>? _appliedCoupon;
  bool _couponRemovedManually = false;
  bool _isManualSelection = false;

  // Track the previous subtotal to detect cart total changes
  double _prevCartTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
    _fetchCoupons();
  }

  // Load initial settings
  Future<void> _fetchSettings() async {
    if (!mounted) return;
    setState(() {
      _loadingSettings = true;
    });
    try {
      final response = await ApiClient.instance.get('/customer/settings');
      if (response.data != null && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _settings = Map<String, dynamic>.from(response.data['data'] ?? {});
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch settings: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingSettings = false;
        });
      }
    }
  }

  // Load coupons list
  Future<void> _fetchCoupons() async {
    if (!mounted) return;
    setState(() {
      _loadingCoupons = true;
    });
    try {
      final response = await ApiClient.instance.get('/customer/coupons');
      if (response.data != null && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _coupons = List<dynamic>.from(response.data['data'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch coupons: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingCoupons = false;
        });
      }
    }
  }

  // Fetch slots for selected date
  Future<void> _fetchSlots(DateTime date) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.cart.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _loadingSlots = true;
    });
    try {
      final formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final serviceId = cartProvider.cart[0].id;
      final response = await ApiClient.instance.get(
        '/customer/slots',
        queryParameters: {'date': formattedDate, 'service_id': serviceId},
      );

      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> fetchedSlots = response.data['data'] ?? [];

        // Deduplicate slots by label
        final uniqueSlots = <Map<String, dynamic>>[];
        final seenLabels = <String>{};
        for (final slot in fetchedSlots) {
          final label = slot['label']?.toString() ?? '';
          if (!seenLabels.contains(label)) {
            seenLabels.add(label);
            uniqueSlots.add(Map<String, dynamic>.from(slot));
          }
        }

        if (mounted) {
          setState(() {
            _slots = uniqueSlots;
          });

          // Check if previous selected slot is still available, otherwise auto-select first available
          final stillAvailable = uniqueSlots.any((s) =>
              s['label'] == _selectedTimeSlot && s['is_available'] == true);
          if (!stillAvailable) {
            final firstAvailable = uniqueSlots.firstWhere(
                (s) => s['is_available'] == true,
                orElse: () => {});
            setState(() {
              _selectedTimeSlot = firstAvailable.isNotEmpty
                  ? firstAvailable['label'].toString()
                  : 'No Slot Available';
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch slots: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingSlots = false;
        });
      }
    }
  }

  // Coupon Discount calculation
  double getCouponDiscount(Map<String, dynamic>? coupon, double total) {
    if (coupon == null) return 0.0;
    final val = double.tryParse(coupon['value']?.toString() ?? '0') ?? 0.0;
    final minAmount =
        double.tryParse(coupon['min_order_amount']?.toString() ?? '0') ?? 0.0;
    if (total < minAmount) return 0.0;

    if (coupon['type'] == 'fixed') {
      return val;
    } else if (coupon['type'] == 'percent') {
      final discount = (total * (val / 100)).roundToDouble();
      if (coupon['max_discount'] != null) {
        final maxDisc =
            double.tryParse(coupon['max_discount'].toString()) ?? 0.0;
        return discount > maxDisc ? maxDisc : discount;
      }
      return discount;
    }
    return 0.0;
  }

  // Coupon Eligibility check
  Map<String, dynamic> getOfferEligibility(Map<String, dynamic>? coupon, double total) {
    if (coupon == null) return {'eligible': false, 'message': ''};
    final minAmount =
        double.tryParse(coupon['min_order_amount']?.toString() ?? '0') ?? 0.0;
    if (total < minAmount) {
      return {
        'eligible': false,
        'message': 'Add ₹${(minAmount - total).round()} more to apply'
      };
    }
    return {'eligible': true, 'message': ''};
  }

  // Auto-apply Coupon Logic
  void _autoApplyCoupon(double cartTotal) {
    if (_couponRemovedManually || _coupons.isEmpty) return;

    // Validate manual selection if active
    if (_isManualSelection && _appliedCoupon != null) {
      final eligibility = getOfferEligibility(_appliedCoupon, cartTotal);
      if (!eligibility['eligible']) {
        setState(() {
          _appliedCoupon = null;
          _isManualSelection = false;
        });
      } else {
        final discount = getCouponDiscount(_appliedCoupon, cartTotal);
        setState(() {
          _appliedCoupon = Map<String, dynamic>.from(_appliedCoupon!)
            ..['discount'] = discount;
        });
      }
      return;
    }

    Map<String, dynamic>? bestCoupon;
    double maxDiscount = 0.0;

    for (final offer in _coupons) {
      final offerMap = Map<String, dynamic>.from(offer);
      final eligibility = getOfferEligibility(offerMap, cartTotal);
      if (eligibility['eligible']) {
        final discount = getCouponDiscount(offerMap, cartTotal);
        if (discount > maxDiscount) {
          maxDiscount = discount;
          bestCoupon = offerMap..['discount'] = discount;
        }
      }
    }

    setState(() {
      _appliedCoupon = bestCoupon;
    });
  }

  // Helper date methods
  String formatDateLabel(DateTime date) {
    final today = DateTime.now();
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }

    final weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return weekdays[date.weekday % 7];
  }

  String formatDateLabelSub(DateTime date) {
    final monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return "${date.day} ${monthNames[date.month - 1]}";
  }

  String formatSelectedDateTime() {
    if (_scheduleType == 'ASAP') {
      return "Today, ASAP ($_selectedTimeSlot)";
    }

    final today = DateTime.now();
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    String dateStr = '';
    if (_selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day) {
      dateStr = 'Today';
    } else if (_selectedDate.year == tomorrow.year &&
        _selectedDate.month == tomorrow.month &&
        _selectedDate.day == tomorrow.day) {
      dateStr = 'Tomorrow';
    } else {
      final weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
      final monthNames = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      dateStr =
          "${weekdays[_selectedDate.weekday % 7]}, ${_selectedDate.day} ${monthNames[_selectedDate.month - 1]}";
    }

    return "$dateStr at $_selectedTimeSlot";
  }

  // Show coupons bottom sheet modal
  void _showCouponsModal(double cartTotal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Apply Coupon',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _loadingCoupons
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primary))
                          : _coupons.isEmpty
                              ? Center(
                                  child: Text(
                                    'No coupons available at the moment.',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _coupons.length,
                                  itemBuilder: (context, index) {
                                    final offer = Map<String, dynamic>.from(
                                        _coupons[index]);
                                    final eligibility =
                                        getOfferEligibility(offer, cartTotal);
                                    final eligible = eligibility['eligible'];
                                    final message = eligibility['message'];
                                    final isCurrentlyApplied =
                                        _appliedCoupon?['code'] ==
                                            offer['code'];

                                    return Opacity(
                                      opacity: eligible ? 1.0 : 0.55,
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 14),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 18),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isCurrentlyApplied
                                                ? AppTheme.primary
                                                : const Color(0xFFE2E8F0),
                                            width: isCurrentlyApplied ? 2 : 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color(0xFFF1F5F9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                        color: const Color(
                                                            0xFFCBD5E1),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      offer['code'] ?? '',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color:
                                                            AppTheme.textPrimary,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    offer['description'] ??
                                                        offer['desc'] ??
                                                        '',
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppTheme.textSecondary,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                  if (!eligible)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 6),
                                                      child: Text(
                                                        message,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.red,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            GestureDetector(
                                              onTap: (eligible &&
                                                      !isCurrentlyApplied)
                                                  ? () {
                                                      final discount =
                                                          getCouponDiscount(
                                                              offer, cartTotal);
                                                      setState(() {
                                                        _appliedCoupon = offer
                                                          ..['discount'] =
                                                              discount;
                                                        _couponRemovedManually =
                                                            false;
                                                        _isManualSelection =
                                                            true;
                                                      });
                                                      Navigator.pop(context);
                                                    }
                                                  : null,
                                              child: Text(
                                                isCurrentlyApplied
                                                    ? 'APPLIED'
                                                    : 'APPLY',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w900,
                                                  color: isCurrentlyApplied
                                                      ? AppTheme.success
                                                      : (eligible
                                                          ? AppTheme.primary
                                                          : Colors.grey),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final addressProvider = Provider.of<AddressProvider>(context);

    final cart = cartProvider.cart;
    final selectedAddress = addressProvider.selectedAddress;
    final cartTotal = cartProvider.cartTotal;

    // Detect cart changes to auto-apply coupons
    if (cartTotal != _prevCartTotal) {
      _prevCartTotal = cartTotal;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoApplyCoupon(cartTotal);
      });
    }

    // Calculations based on settings and coupon
    final double serviceFee =
        double.tryParse(_settings['service_fee']?.toString() ?? '49') ?? 49.0;
    final double rawGstRate =
        double.tryParse(_settings['gst_rate']?.toString() ?? '18') ?? 18.0;
    final bool gstEnabled =
        _settings['gst_enabled'] == 'true' || _settings['gst_rate'] != null;
    final String companyState =
        _settings['company_state']?.toString() ?? 'Jharkhand';
    final double cgstRate =
        (double.tryParse(_settings['cgst_percentage']?.toString() ?? '') ??
                (rawGstRate / 2)) /
            100;
    final double sgstRate =
        (double.tryParse(_settings['sgst_percentage']?.toString() ?? '') ??
                (rawGstRate / 2)) /
            100;
    final double igstRate =
        (double.tryParse(_settings['igst_percentage']?.toString() ?? '') ??
                rawGstRate) /
            100;

    bool isSameState = true;
    if (selectedAddress != null) {
      final addrState = selectedAddress.state.toString();
      isSameState = addrState.toLowerCase() == companyState.toLowerCase();
    }

    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;

    if (gstEnabled) {
      if (isSameState) {
        cgst = (cartTotal * cgstRate).roundToDouble();
        sgst = (cartTotal * sgstRate).roundToDouble();
      } else {
        igst = (cartTotal * igstRate).roundToDouble();
      }
    }

    final double totalTax = cgst + sgst + igst;
    final double couponDiscount =
        _appliedCoupon != null ? getCouponDiscount(_appliedCoupon, cartTotal) : 0.0;
    final double grandTotal =
        (cartTotal + (cart.isEmpty ? 0.0 : serviceFee) + totalTax - couponDiscount)
            .clamp(0.0, double.infinity);

    // Calculate total original price of cart items
    final double cartOriginalTotal = cart.fold(0.0, (sum, item) {
      final orig = item.originalPrice ?? item.basePrice;
      return sum + (orig * item.qty);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Cart'),
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1E293B),
        ),
      ),
      body: cart.isEmpty
          ? _buildEmptyCart(context)
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 140, left: 16, right: 16, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SELECTED SERVICES LIST CARD ---
                  _buildCartItemsList(context, cartProvider, cartOriginalTotal),

                  const SizedBox(height: 14),

                  // --- DATE & TIME SCHEDULING CARD ---
                  _buildSchedulingCard(cartProvider),

                  const SizedBox(height: 14),

                  // --- DELIVERY ADDRESS SELECTOR CARD ---
                  _buildAddressSection(context, selectedAddress),

                  const SizedBox(height: 14),

                  // --- COUPONS DASHBOARD TICKET CARD ---
                  _buildCouponCard(cartTotal, couponDiscount),

                  const SizedBox(height: 14),

                  // --- BILLING PAYMENT SUMMARY CARD ---
                  _buildPaymentSummary(
                    context,
                    cartTotal,
                    cartOriginalTotal,
                    couponDiscount,
                    serviceFee,
                    gstEnabled,
                    isSameState,
                    cgstRate,
                    sgstRate,
                    igstRate,
                    cgst,
                    sgst,
                    igst,
                    grandTotal,
                  ),

                  const SizedBox(height: 16),

                  // --- CANCELLATION POLICY BOX ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF64748B), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cancellation policy: Free cancellation until 4 hours before scheduled slot.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

      // --- STICKY BOTTOM CHECKOUT ACTION BAR ---
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${grandTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'Total Pay Amount',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedAddress == null) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Address Required'),
                                content: const Text(
                                    'Please select or add a service address before proceeding.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          final formattedDate =
                              "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
                          context.push(
                            Uri(
                              path: '/payment-selection',
                              queryParameters: {
                                'booking_date': formattedDate,
                                'time_slot': _selectedTimeSlot,
                                'coupon_code': _appliedCoupon != null
                                    ? _appliedCoupon!['code']?.toString()
                                    : '',
                                'total_amount': grandTotal.toStringAsFixed(0),
                              },
                            ).toString(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Proceed to Pay',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward,
                                size: 18, color: Colors.white),
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

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFEBF4FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Color(0xFF004680),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your cart is empty',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add some services from our curated checklist to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF004680),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Browse Services',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsList(
      BuildContext context, CartProvider cartProvider, double cartOriginalTotal) {
    final cart = cartProvider.cart;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of items card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.shopping_basket_outlined,
                    color: Color(0xFF004680), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Selected Services',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF4FA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${cartProvider.itemCount} Items',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF004680),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Items rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.length,
            padding: const EdgeInsets.all(16),
            separatorBuilder: (context, index) =>
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final item = cart[index];
              final orig = item.originalPrice ?? item.basePrice;

              return Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.image ??
                          'https://joharfix.com/assets/images/logo.jpeg',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.image_outlined,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '₹${item.basePrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF004680),
                              ),
                            ),
                            if (orig > item.basePrice) ...[
                              const SizedBox(width: 6),
                              Text(
                                '₹${orig.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Qty controller matching design
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              cartProvider.updateQty(item.id, 'dec'),
                          icon: const Icon(Icons.remove,
                              size: 14, color: Color(0xFF004680)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28),
                        ),
                        Text(
                          '${item.qty}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF004680),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              cartProvider.updateQty(item.id, 'inc'),
                          icon: const Icon(Icons.add,
                              size: 14, color: Color(0xFF004680)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Add more services button
          InkWell(
            onTap: () => context.go('/home'),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline,
                      color: Color(0xFF004680), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add more services',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF004680),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulingCard(CartProvider cartProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFF004680), size: 18),
              const SizedBox(width: 8),
              Text(
                'Arriving & Scheduling',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ASAP vs Schedule Segmented Control
          if (_scheduleType == 'ASAP' || _showSlotsPicker)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _scheduleType = 'ASAP';
                          _selectedDate = DateTime.now();
                          _selectedTimeSlot = 'ASAP';
                          _showSlotsPicker = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _scheduleType == 'ASAP'
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _scheduleType == 'ASAP'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flash_on,
                              size: 15,
                              color: _scheduleType == 'ASAP'
                                  ? const Color(0xFF004680)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Arrive ASAP',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _scheduleType == 'ASAP'
                                    ? const Color(0xFF004680)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _scheduleType = 'Later';
                          final tomorrow =
                              DateTime.now().add(const Duration(days: 1));
                          _selectedDate = tomorrow;
                          _selectedTimeSlot = '10:00 AM - 12:00 PM';
                          _showSlotsPicker = true;
                        });
                        _fetchSlots(_selectedDate);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _scheduleType == 'Later'
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _scheduleType == 'Later'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time_filled,
                              size: 15,
                              color: _scheduleType == 'Later'
                                  ? const Color(0xFF004680)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Schedule Later',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _scheduleType == 'Later'
                                    ? const Color(0xFF004680)
                                    : const Color(0xFF64748B),
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

          // Date and Time Slot Picker (Schedule Later mode)
          if (_scheduleType == 'Later' && _showSlotsPicker) ...[
            const SizedBox(height: 16),
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = _selectedDate.year == date.year &&
                      _selectedDate.month == date.month &&
                      _selectedDate.day == date.day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                        if (_selectedTimeSlot == 'ASAP') {
                          _selectedTimeSlot = '10:00 AM - 12:00 PM';
                        }
                      });
                      _fetchSlots(date);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 76,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF004680) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF004680)
                              : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formatDateLabel(date),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            formatDateLabelSub(date),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Time Slot',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            _loadingSlots
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Loading slots...',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  )
                : _slots.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('No slots available for this date.',
                            style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _slots.length,
                        itemBuilder: (context, idx) {
                          final slot = _slots[idx];
                          final label = slot['label']?.toString() ?? '';
                          final isAvailable = slot['is_available'] == true;
                          final isSelected = _selectedTimeSlot == label;

                          return GestureDetector(
                            onTap: isAvailable
                                ? () {
                                    setState(() {
                                      _selectedTimeSlot = label;
                                      _showSlotsPicker = false;
                                    });
                                  }
                                : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF004680)
                                    : (isAvailable
                                        ? Colors.white
                                        : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF004680)
                                      : const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : (isAvailable
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFF94A3B8)),
                                    ),
                                  ),
                                  if (!isAvailable)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Text(
                                        'FULL',
                                        style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],

          // Collapsed Schedule details
          if (_scheduleType == 'Later' && !_showSlotsPicker) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                setState(() {
                  _showSlotsPicker = true;
                });
                _fetchSlots(_selectedDate);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBF4FA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.access_time_filled,
                          color: Color(0xFF004680), size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scheduled Arrival',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatSelectedDateTime(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Change',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF004680),
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Color(0xFF004680), size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Safe Arrival status notification banner
          if (_scheduleType == 'ASAP' || !_showSlotsPicker) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _scheduleType == 'ASAP'
                          ? 'Expert will reach you ASAP today'
                          : 'Scheduled arrival: ${formatSelectedDateTime()}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context, dynamic selectedAddress) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Color(0xFF004680), size: 18),
              const SizedBox(width: 8),
              Text(
                'Service Address',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Address info row
          InkWell(
            onTap: () => context.push('/address-management'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBF4FA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selectedAddress != null
                          ? _getAddressIcon(selectedAddress.type)
                          : Icons.home_outlined,
                      color: const Color(0xFF004680),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedAddress != null
                              ? selectedAddress.type.toString().toUpperCase()
                              : 'Select Address',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selectedAddress != null
                              ? "${selectedAddress.houseNo != null ? selectedAddress.houseNo + ', ' : ''}${selectedAddress.landmark}, ${selectedAddress.city}"
                              : 'Please add/select a service address',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Text(
                        selectedAddress != null ? 'Change' : 'Add',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF004680),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Color(0xFF004680), size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAddressIcon(dynamic type) {
    final typeStr = type?.toString().toLowerCase() ?? '';
    if (typeStr.contains('home')) return Icons.home;
    if (typeStr.contains('work') || typeStr.contains('office')) {
      return Icons.business;
    }
    return Icons.location_on;
  }

  Widget _buildCouponCard(double cartTotal, double couponDiscount) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _appliedCoupon != null ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _appliedCoupon != null
              ? const Color(0xFFA7F3D0)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Left Ticket punch cutout representation
          Positioned(
            left: -8,
            top: 26,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Right Ticket punch cutout representation
          Positioned(
            right: -8,
            top: 26,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Ticket content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _appliedCoupon != null
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : const Color(0xFFEBF4FA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_offer,
                    color: _appliedCoupon != null
                        ? const Color(0xFF10B981)
                        : const Color(0xFF004680),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _appliedCoupon != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _appliedCoupon!['code'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Saved ₹${couponDiscount.toStringAsFixed(0)} on this service',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF047857),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Apply Coupon / Offers',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                ),
                if (_appliedCoupon != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _appliedCoupon = null;
                        _couponRemovedManually = true;
                        _isManualSelection = false;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      'Remove',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () => _showCouponsModal(cartTotal),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            'View Offers',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF004680),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 15,
                            color: Color(0xFF004680),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(
    BuildContext context,
    double cartTotal,
    double cartOriginalTotal,
    double couponDiscount,
    double serviceFee,
    bool gstEnabled,
    bool isSameState,
    double cgstRate,
    double sgstRate,
    double igstRate,
    double cgst,
    double sgst,
    double igst,
    double grandTotal,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.payment, color: Color(0xFF004680), size: 18),
              const SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Item Total
          _buildSummaryRow(
            'Item Total',
            '₹${cartTotal.toStringAsFixed(0)}',
            originalPrice: cartOriginalTotal > cartTotal
                ? '₹${cartOriginalTotal.toStringAsFixed(0)}'
                : null,
          ),
          const SizedBox(height: 10),

          // Coupon Discount
          if (couponDiscount > 0) ...[
            _buildSummaryRow(
              'Coupon Discount (${_appliedCoupon?['code'] ?? ''})',
              '- ₹${couponDiscount.toStringAsFixed(0)}',
              isGreen: true,
            ),
            const SizedBox(height: 10),
          ],

          // Convenience Fee
          _buildSummaryRow(
            'Service & Convenience Fee',
            '₹${serviceFee.toStringAsFixed(0)}',
          ),

          // GST Lines
          if (gstEnabled) ...[
            const SizedBox(height: 10),
            if (isSameState) ...[
              _buildSummaryRow(
                'CGST (${(cgstRate * 100).toStringAsFixed(1)}%)',
                '₹${cgst.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 10),
              _buildSummaryRow(
                'SGST (${(sgstRate * 100).toStringAsFixed(1)}%)',
                '₹${sgst.toStringAsFixed(0)}',
              ),
            ] else ...[
              _buildSummaryRow(
                'IGST (${(igstRate * 100).toStringAsFixed(1)}%)',
                '₹${igst.toStringAsFixed(0)}',
              ),
            ],
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'To Pay',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                '₹${grandTotal.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF004680),
                ),
              ),
            ],
          ),

          // GSTIN note from settings
          if (gstEnabled && _settings['company_gstin'] != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'GSTIN: ${_settings['company_gstin']}',
                style: const TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isGreen = false, String? originalPrice}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isGreen ? FontWeight.w700 : FontWeight.w500,
            color: isGreen ? const Color(0xFF10B981) : const Color(0xFF64748B),
          ),
        ),
        Row(
          children: [
            if (originalPrice != null) ...[
              Text(
                originalPrice,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isGreen ? const Color(0xFF10B981) : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
