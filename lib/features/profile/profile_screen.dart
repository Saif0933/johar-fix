import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> _avatars = [
    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png', // Default Male/General
    'https://cdn-icons-png.flaticon.com/512/3135/3135768.png', // Female General
    'https://cdn-icons-png.flaticon.com/512/4140/4140037.png', // Male Illustrated Beard
    'https://cdn-icons-png.flaticon.com/512/4140/4140048.png', // Female Illustrated Glasses
    'https://cdn-icons-png.flaticon.com/512/4140/4140061.png', // Male Illustrated Cap
    'https://cdn-icons-png.flaticon.com/512/4139/4139981.png', // Female Illustrated Smile
  ];

  final List<Map<String, String>> _faqItems = [
    {
      'q': 'How do I cancel my service booking?',
      'a': 'You can cancel any booking up to 2 hours before the scheduled time slot free of charge. Go to "My Bookings", select the booking, and tap "Cancel Booking".'
    },
    {
      'q': 'How does the payment process work?',
      'a': 'You can pay online via UPI, Credit/Debit cards, Net Banking, or choose Cash on Delivery (COD). Online payments are handled securely through Razorpay.'
    },
    {
      'q': 'Is there a service warranty?',
      'a': 'Yes! JoharFix offers a 15-day service warranty on all completed jobs. If any issue arises from the completed service, we will resolve it free of charge.'
    },
    {
      'q': 'Are the service professionals verified?',
      'a': 'Absolutely. Every service partner on JoharFix goes through a rigorous criminal background check, technical assessment test, and behavior training before being onboarded.'
    }
  ];

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showAvatarPicker(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Avatar',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const Text(
                'Select an illustrated character for your JoharFix account',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _avatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final isSelected = authProvider.avatarIndex == index;
                  return GestureDetector(
                    onTap: () {
                      authProvider.saveAvatarIndex(index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.transparent,
                          width: 3.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(_avatars[index]),
                            backgroundColor: AppTheme.surface,
                          ),
                          if (isSelected)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 10),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReferModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.85,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Refer & Earn Rewards',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFCE7F3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.card_giftcard, size: 54, color: Color(0xFFDB2777)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Invite friends, earn ₹100!',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Get ₹100 cashback in your JoharFix wallet when your friend completes their first service. Your friend also gets ₹100 discount!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Code Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'YOUR REFERRAL CODE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'JOHAR100',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Clipboard.setData(const ClipboardData(text: 'JOHAR100'));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Referral code JOHAR100 copied to clipboard.')),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('COPY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'How it works:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        _buildReferStep(1, 'Share your unique referral code with friends.'),
                        _buildReferStep(2, 'Your friend signs up & gets ₹100 off their first booking.'),
                        _buildReferStep(3, 'Once their booking is completed, you receive ₹100 in your wallet!'),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            _launchUrl('https://wa.me/?text=Hey! Use my referral code JOHAR100 on JoharFix to get ₹100 cashback on your first premium home service. Download the app now!');
                          },
                          icon: const Icon(Icons.share, color: Colors.white),
                          label: const Text('Share via WhatsApp', style: TextStyle(fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReferStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$num',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Help Center',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Common Queries & FAQs',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        // FAQ List
                        ...List.generate(_faqItems.length, (idx) {
                          final item = _faqItems[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border, width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ExpansionTile(
                                title: Text(
                                  item['q']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                iconColor: AppTheme.textSecondary,
                                collapsedIconColor: AppTheme.textSecondary,
                                childrenPadding: const EdgeInsets.all(16),
                                expandedAlignment: Alignment.topLeft,
                                shape: const Border(),
                                children: [
                                  Text(
                                    item['a']!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                        const Text(
                          'Still need assistance?',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Our executive team is available 24/7 to help you.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),
                        // Quick Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _launchUrl('tel:+919999999999'),
                                icon: const Icon(Icons.call, size: 16, color: Colors.white),
                                label: const Text('Call Support', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _launchUrl('https://wa.me/919999999999?text=Hello JoharFix Support, I need help with my booking.'),
                                icon: const Icon(Icons.chat, size: 16, color: Color(0xFF059669)),
                                label: const Text('WhatsApp Chat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFD1FAE5), width: 1.5),
                                  backgroundColor: const Color(0xFFECFDF5),
                                  foregroundColor: const Color(0xFF059669),
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            );
          },
        );
      },
    );
  }

  void _showTermsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.85,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terms & Privacy Policies',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        const SizedBox(height: 16),
                        _buildLegalSection(
                          '1. Agreement to Terms',
                          'Welcome to JoharFix. By using our mobile application and related premium home services, you agree to comply with and be bound by the following terms and conditions. Please read them carefully.',
                        ),
                        _buildLegalSection(
                          '2. Privacy Policy',
                          'We respect your personal privacy. All sensitive customer information collected (including full name, phone number, and location address details) is securely encrypted and used solely for fulfilling requested on-demand services. We do not sell or lease user information to third-party marketing companies.',
                        ),
                        _buildLegalSection(
                          '3. Cancellation & Refunds',
                          'Bookings can be cancelled up to 2 hours before the service schedule window. Any cancellation made after this timeframe may be subject to a nominal convenience fee to compensate service partners. Refunds on online payments are processed back to the original source bank account within 5-7 business working days.',
                        ),
                        _buildLegalSection(
                          '4. Limitation of Liability',
                          'While all service partners are thoroughly background-verified and expert technicians, JoharFix acts as an aggregator platform and is not directly liable for accidental property damage. However, we provide a 15-day service quality warranty to ensure maximum customer satisfaction.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegalSection(String header, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Logout Session', style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('Are you sure you want to logout from the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;
    final stats = profile?.orderStats;

    final avatarUrl = _avatars[authProvider.avatarIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // --- PROFILE HEADER GRADIENT BLOCK ---
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF004680), Color(0xFF002A4E)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x26004680),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      left: 20,
                      right: 20,
                      bottom: 24,
                    ),
                    child: Column(
                      children: [
                        // Profile Info Row
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showAvatarPicker(context, authProvider),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(avatarUrl),
                                      backgroundColor: AppTheme.surface,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        profile?.name ?? 'Customer',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0x3334D399),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Color(0xFF34D399), size: 12),
                                            SizedBox(width: 3),
                                            Text(
                                              'Verified',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF34D399),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (profile?.email != null && !profile!.email.contains('@customer.joharfix.com'))
                                        ? profile.email
                                        : 'No email added',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFFE2E8F0),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (profile?.phone != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '+91 ${profile!.phone}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFFCBD5E1),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Loyalty Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3364748B),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.military_tech, size: 16, color: Color(0xFF1E293B)),
                                      SizedBox(width: 6),
                                      Text(
                                        'JOHARFIX REGULAR',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF1E293B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Free Priority Booking & Support',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Active Tier',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFF1F5F9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- QUICK ACTIONS FLOATING ROW ---
                  Transform.translate(
                    offset: const Offset(0, -15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildQuickActionBox(
                            gradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                            icon: Icons.receipt_long,
                            iconColor: const Color(0xFF1D4ED8),
                            val: '₹${stats?.totalSpend != null ? stats!.totalSpend.toStringAsFixed(0) : '0'}',
                            label: 'Total Spend',
                            onTap: () => context.push('/bookings'),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickActionBox(
                            gradient: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                            icon: Icons.location_on,
                            iconColor: const Color(0xFF047857),
                            val: 'Addresses',
                            label: 'Saved Locations',
                            onTap: () => context.push('/address-management'),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickActionBox(
                            gradient: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                            icon: Icons.calendar_month,
                            iconColor: const Color(0xFFC2410C),
                            val: 'Bookings',
                            label: 'Order History',
                            onTap: () => context.push('/bookings'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- STATS PERFORMANCE GRID ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Performance',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF64748B),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatGridItem('Total', '${stats?.totalCount ?? 0}', const Color(0xFF004680), const Color(0xFFEFF6FF), Icons.list_alt),
                            const SizedBox(width: 8),
                            _buildStatGridItem('Pending', '${stats?.pending ?? 0}', const Color(0xFFD97706), const Color(0xFFFEF3C7), Icons.access_time),
                            const SizedBox(width: 8),
                            _buildStatGridItem('Completed', '${stats?.completed ?? 0}', const Color(0xFF059669), const Color(0xFFECFDF5), Icons.check_circle_outline),
                            const SizedBox(width: 8),
                            _buildStatGridItem('Cancelled', '${stats?.cancelled ?? 0}', const Color(0xFFDC2626), const Color(0xFFFEF2F2), Icons.cancel_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- PERSONAL SETTINGS MENU ---
                  _buildMenuGroupTitle('Personal Settings'),
                  _buildMenuContainer([
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF004680),
                      title: 'Edit Profile Info',
                      onTap: () => context.push('/edit-profile'),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF059669),
                      title: 'Saved Addresses',
                      onTap: () => context.push('/address-management'),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    _buildMenuItem(
                      icon: Icons.calendar_today_outlined,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFD97706),
                      title: 'My Service Bookings',
                      onTap: () => context.push('/bookings'),
                    ),
                  ]),

                  // --- OFFERS & REWARDS MENU ---
                  _buildMenuGroupTitle('Offers & Rewards'),
                  _buildMenuContainer([
                    _buildMenuItem(
                      icon: Icons.card_giftcard,
                      iconBg: const Color(0xFFFDF2F8),
                      iconColor: const Color(0xFFDB2777),
                      title: 'Refer & Earn ₹100',
                      badge: 'NEW',
                      onTap: () => _showReferModal(context),
                    ),
                  ]),

                  // --- SUPPORT & POLICIES MENU ---
                  _buildMenuGroupTitle('Support & Policies'),
                  _buildMenuContainer([
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      iconBg: const Color(0xFFFEF2F2),
                      iconColor: const Color(0xFFEF4444),
                      title: 'Help Center & FAQ',
                      onTap: () => _showHelpModal(context),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    _buildMenuItem(
                      icon: Icons.document_scanner_outlined,
                      iconBg: const Color(0xFFF1F5F9),
                      iconColor: const Color(0xFF475569),
                      title: 'Terms of Service & Privacy',
                      onTap: () => _showTermsModal(context),
                    ),
                  ]),

                  // --- LOGOUT BUTTON ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                    child: InkWell(
                      onTap: () => _showLogoutDialog(context, authProvider),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFEE2E2), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08EF4444),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Logout current session',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Version Tag
                  const Text(
                    'JoharFix v1.2.5 (Premium Build)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionBox({
    required List<Color> gradient,
    required IconData icon,
    required Color iconColor,
    required String val,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1464748B),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(height: 6),
              Text(
                val,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatGridItem(String label, String count, Color color, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0864748B),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 14, color: color),
                Text(
                  count,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGroupTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 24, top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A64748B),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
              ),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
