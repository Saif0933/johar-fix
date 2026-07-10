import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';

class PaymentSelectionScreen extends StatefulWidget {
  final String? bookingDate;
  final String? timeSlot;
  final String? couponCode;
  final double? totalAmount;

  const PaymentSelectionScreen({
    super.key,
    this.bookingDate,
    this.timeSlot,
    this.couponCode,
    this.totalAmount,
  });

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  String _selectedMode = 'cod'; // default Cash on Delivery (cod / online)
  bool _submitting = false;
  String _errorMessage = '';

  // Razorpay simulation state
  String _bookingId = '';
  String _razorpayOrderId = '';
  double _razorpayAmount = 0.0;

  Future<void> _handlePlaceOrder() async {
    setState(() {
      _submitting = true;
      _errorMessage = '';
    });

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    
    final itemsPayload = cartProvider.cart.map((item) => {
      'service_id': item.id,
      'qty': item.qty,
    }).toList();

    final payload = {
      'items': itemsPayload,
      'address_id': addressProvider.selectedAddress?.id,
      'payment_mode': _selectedMode,
      'total_amount': widget.totalAmount ?? cartProvider.grandTotal,
      if (widget.bookingDate != null) 'booking_date': widget.bookingDate,
      if (widget.timeSlot != null) 'time_slot': widget.timeSlot,
      if (widget.couponCode != null && widget.couponCode!.isNotEmpty) 'coupon_code': widget.couponCode,
    };

    final serviceName = cartProvider.cart.isNotEmpty ? cartProvider.cart.first.name : '';

    try {
      final res = await ApiClient.instance.post('/customer/bookings', data: payload);
      if (res.data != null && res.data['success'] == true) {
        final resData = res.data['data'];
        
        if (mounted) {
          if (_selectedMode == 'online') {
            setState(() {
              _bookingId = resData['booking_id']?.toString() ?? '';
              _razorpayOrderId = resData['razorpay_order_id']?.toString() ?? '';
              _razorpayAmount = double.tryParse(resData['amount']?.toString() ?? '') ?? widget.totalAmount ?? cartProvider.grandTotal;
              _submitting = false;
            });
            _showRazorpaySimulationSheet();
          } else {
            final double finalAmount = widget.totalAmount ?? cartProvider.grandTotal;
            final bookingIdVal = resData['booking_id']?.toString() ?? '';
            final bookingDateVal = widget.bookingDate ?? '';
            final timeSlotVal = widget.timeSlot ?? '';

            cartProvider.clearCart();
            setState(() => _submitting = false);
            context.go(
              '/booking-success',
              extra: {
                'booking_id': bookingIdVal,
                'total_amount': finalAmount.toStringAsFixed(2),
                'payment_method': 'cod',
                'booking_date': bookingDateVal,
                'time_slot': timeSlotVal,
                'service_name': serviceName,
              },
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = res.data['message'] ?? 'Failed to place booking. Please try again.';
          _submitting = false;
        });
      }
    } catch (e) {
      debugPrint('Error creating booking: $e');
      setState(() {
        _errorMessage = 'An error occurred during booking. Please try again.';
        _submitting = false;
      });
    }
  }

  void _showRazorpaySimulationSheet() {
    String step = 'options';
    String selectedUpiApp = '';

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            void simulateSuccess() async {
              setModalState(() {
                step = 'processing';
              });

              final cartProv = Provider.of<CartProvider>(this.context, listen: false);
              final router = GoRouter.of(this.context);
              final bookingDateVal = widget.bookingDate ?? '';
              final timeSlotVal = widget.timeSlot ?? '';
              
              await Future.delayed(const Duration(seconds: 2));
              
              try {
                final verifyPayload = {
                  'booking_id': _bookingId,
                  'razorpay_payment_id': 'pay_mock_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                  'razorpay_order_id': _razorpayOrderId,
                  'razorpay_signature': 'mock_sig',
                };
                final verifyRes = await ApiClient.instance.post('/customer/bookings/verify', data: verifyPayload);
                if (verifyRes.data != null && verifyRes.data['success'] == true) {
                  setModalState(() {
                    step = 'success';
                  });
                  
                  final serviceName = cartProv.cart.isNotEmpty
                      ? cartProv.cart.first.name
                      : '';

                  cartProv.clearCart();
                  await Future.delayed(const Duration(milliseconds: 1500));
                  if (mounted) {
                    Navigator.pop(context); // Close sheet
                    router.go(
                      '/booking-success',
                      extra: {
                        'booking_id': _bookingId,
                        'total_amount': _razorpayAmount.toStringAsFixed(2),
                        'payment_method': 'online',
                        'booking_date': bookingDateVal,
                        'time_slot': timeSlotVal,
                        'service_name': serviceName,
                      },
                    );
                  }
                } else {
                  setModalState(() {
                    step = 'failed';
                  });
                }
              } catch (e) {
                debugPrint('Verify payment error: $e');
                setModalState(() {
                  step = 'failed';
                });
              }
            }

            void simulateFailure() async {
              setModalState(() {
                step = 'processing';
              });
              await Future.delayed(const Duration(milliseconds: 1500));
              setModalState(() {
                step = 'failed';
              });
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.shield_outlined, color: Color(0xFF002970), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Razorpay Secure Checkout',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Order: $_razorpayOrderId',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (step != 'processing' && step != 'success')
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 22),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount to Pay',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '₹${_razorpayAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (step == 'options') ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'UPI Apps',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildUpiAppItem(
                          name: 'Google Pay',
                          icon: Icons.account_balance,
                          color: const Color(0xFFEA4335),
                          onTap: () {
                            selectedUpiApp = 'Google Pay';
                            simulateSuccess();
                          },
                        ),
                        _buildUpiAppItem(
                          name: 'PhonePe',
                          icon: Icons.bolt,
                          color: const Color(0xFF5F259F),
                          onTap: () {
                            selectedUpiApp = 'PhonePe';
                            simulateSuccess();
                          },
                        ),
                        _buildUpiAppItem(
                          name: 'Paytm',
                          icon: Icons.wallet,
                          color: const Color(0xFF00B9F1),
                          onTap: () {
                            selectedUpiApp = 'Paytm';
                            simulateSuccess();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Other Methods',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildChannelItem(
                      name: 'Debit / Credit Card',
                      desc: 'Visa, Mastercard, RuPay',
                      icon: Icons.credit_card_outlined,
                      onTap: simulateSuccess,
                    ),
                    _buildChannelItem(
                      name: 'Net Banking',
                      desc: 'SBI, HDFC, ICICI & more',
                      icon: Icons.business_outlined,
                      onTap: simulateSuccess,
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: simulateFailure,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Simulate Payment Failure',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFDC2626),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (step == 'processing') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: AppTheme.primary),
                          const SizedBox(height: 20),
                          Text(
                            'Processing Payment',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            selectedUpiApp.isNotEmpty
                                ? 'Waiting for $selectedUpiApp response...'
                                : 'Authorizing with your bank...',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Do not close or go back',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (step == 'success') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFDCFCE7),
                            ),
                            child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 36),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Payment Successful!',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Redirecting to confirmation...',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (step == 'failed') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFEE2E2),
                            ),
                            child: const Icon(Icons.close, color: Color(0xFFDC2626), size: 36),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Payment Failed',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Transaction was declined or cancelled',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setModalState(() {
                                step = 'options';
                                selectedUpiApp = '';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              minimumSize: const Size(140, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh, size: 18, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'Try Again',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUpiAppItem({
    required String name,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelItem({
    required String name,
    required String desc,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String mode,
    required String title,
    required String desc,
    required IconData icon,
    required bool showBadge,
  }) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? AppTheme.primary : const Color(0xFF334155),
                        ),
                      ),
                      if (showBadge) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF002970),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Razorpay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final addressProvider = Provider.of<AddressProvider>(context);
    final selectedAddress = addressProvider.selectedAddress;

    final String selectedAddressText;
    if (selectedAddress != null) {
      final parts = [
        selectedAddress.houseNo,
        selectedAddress.landmark,
        selectedAddress.city,
        selectedAddress.state
      ].where((p) => p != null && p.trim().isNotEmpty).toList();
      selectedAddressText = parts.join(', ') +
          (selectedAddress.pincode.isNotEmpty ? ' - ${selectedAddress.pincode}' : '');
    } else {
      selectedAddressText = 'No address selected';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Select Payment Method',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.border,
            height: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt_long_outlined, color: AppTheme.primary, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ORDER SUMMARY',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Service Info
                        if (cartProvider.cart.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  cartProvider.cart.first.image ?? 'https://joharfix.com/assets/images/logo.jpeg',
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cartProvider.cart.first.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${cartProvider.cart.first.basePrice.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (cartProvider.cart.length > 1) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+${cartProvider.cart.length - 1} more',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: AppTheme.border, height: 1),
                          const SizedBox(height: 14),
                        ],

                        // Schedule row
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.calendar_today_outlined, color: AppTheme.primary, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SCHEDULE',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.bookingDate ?? "Not Scheduled"}  •  ${widget.timeSlot ?? ""}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Address row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SERVICE ADDRESS',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedAddressText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Payment Method Card
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primary, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'PAYMENT METHOD',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildPaymentOption(
                          mode: 'online',
                          title: 'Pay Online',
                          desc: 'UPI, Debit/Credit Cards, Net Banking',
                          icon: Icons.credit_card_outlined,
                          showBadge: true,
                        ),

                        _buildPaymentOption(
                          mode: 'cod',
                          title: 'Cash on Service',
                          desc: 'Pay cash or scan QR after service completion',
                          icon: Icons.payments_outlined,
                          showBadge: false,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bill Details Card
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_offer_outlined, color: AppTheme.primary, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'BILL DETAILS',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${(widget.totalAmount ?? cartProvider.grandTotal).toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount to Pay',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '₹${(widget.totalAmount ?? cartProvider.grandTotal).toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inclusive of all taxes & fees',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Secure Badge
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '100% Safe & Secure Payment',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          if (_submitting)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        SizedBox(height: 16),
                        Text(
                          'Scheduling Your Booking...',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).padding.bottom > 0
              ? MediaQuery.of(context).padding.bottom + 12
              : 20,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${(widget.totalAmount ?? cartProvider.grandTotal).toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Total Amount',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: _submitting ? null : _handlePlaceOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedMode == 'online' ? 'Pay Now' : 'Confirm Booking',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
