import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();

  bool _nameFocused = false;
  bool _emailFocused = false;
  String? _nameError;
  String? _emailError;
  bool _saving = false;

  final List<String> _avatars = [
    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
    'https://cdn-icons-png.flaticon.com/512/3135/3135768.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140037.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140061.png',
    'https://cdn-icons-png.flaticon.com/512/4139/4139981.png',
  ];

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profile = authProvider.profile;

    final initialName = profile?.name == 'Customer' ? '' : (profile?.name ?? '');
    final isDummyEmail = profile?.email != null && profile!.email.contains('@customer.joharfix.com');
    final initialEmail = isDummyEmail ? '' : (profile?.email ?? '');
    final initialPhone = profile?.phone ?? '';

    _nameController = TextEditingController(text: initialName);
    _emailController = TextEditingController(text: initialEmail);
    _phoneController = TextEditingController(text: initialPhone);

    _nameFocusNode.addListener(() {
      setState(() {
        _nameFocused = _nameFocusNode.hasFocus;
      });
    });

    _emailFocusNode.addListener(() {
      setState(() {
        _emailFocused = _emailFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _showAvatarPicker(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select an illustrated character for your JoharFix account',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _avatars.length,
                  itemBuilder: (context, idx) {
                    final isSelected = authProvider.avatarIndex == idx;
                    return GestureDetector(
                      onTap: () async {
                        await authProvider.saveAvatarIndex(idx);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
                                width: 3,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(_avatars[idx]),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 10, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    setState(() {
      _nameError = null;
      _emailError = null;
    });

    final nameText = _nameController.text.trim();
    final emailText = _emailController.text.trim();
    bool hasError = false;

    if (nameText.isEmpty) {
      setState(() {
        _nameError = 'Full Name is required.';
      });
      hasError = true;
    }

    if (emailText.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(emailText)) {
        setState(() {
          _emailError = 'Please enter a valid email address.';
        });
        hasError = true;
      }
    }

    if (hasError) return;

    setState(() {
      _saving = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final finalEmail = emailText.isEmpty ? '${_phoneController.text}@customer.joharfix.com' : emailText;

    final success = await authProvider.updateProfile({
      'name': nameText,
      'email': finalEmail,
    });

    setState(() {
      _saving = false;
    });

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Success', style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('Profile updated successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                context.pop(); // Go back to profile page
              },
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
            )
          ],
        ),
      );
    } else if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Update Failed', style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('Could not update your profile details. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final avatarUrl = _avatars[authProvider.avatarIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // --- PROFILE PICTURE SECTION ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showAvatarPicker(context, authProvider),
                          child: Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF64748B).withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundImage: NetworkImage(avatarUrl),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Tap profile picture to change avatar',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- FORM INPUTS ---
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // FULL NAME FIELD
                          _buildFieldLabel('Full Name'),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: _nameFocused ? Colors.white : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _nameError != null
                                    ? Colors.red
                                    : (_nameFocused ? AppTheme.primary : const Color(0xFFF1F5F9)),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: _nameError != null
                                      ? Colors.red
                                      : (_nameFocused ? AppTheme.primary : const Color(0xFF64748B)),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    focusNode: _nameFocusNode,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Enter your full name',
                                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                                    ),
                                    onChanged: (val) {
                                      if (val.trim().isNotEmpty && _nameError != null) {
                                        setState(() {
                                          _nameError = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_nameError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                _nameError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // EMAIL ADDRESS FIELD
                          _buildFieldLabel('Email Address'),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: _emailFocused ? Colors.white : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _emailError != null
                                    ? Colors.red
                                    : (_emailFocused ? AppTheme.primary : const Color(0xFFF1F5F9)),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mail_outline,
                                  color: _emailError != null
                                      ? Colors.red
                                      : (_emailFocused ? AppTheme.primary : const Color(0xFF64748B)),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Enter your email address',
                                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                                    ),
                                    onChanged: (val) {
                                      if (val.trim().isNotEmpty && _emailError != null) {
                                        setState(() {
                                          _emailError = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_emailError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                _emailError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // PHONE FIELD (DISABLED / LOCK)
                          _buildFieldLabel('Phone Number'),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.call_outlined, color: Color(0xFF94A3B8), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    enabled: false,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'No phone number linked',
                                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock, size: 11, color: Color(0xFF64748B)),
                                      SizedBox(width: 3),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 6, left: 4),
                            child: Text(
                              'Phone number cannot be modified as it is verified via OTP.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
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

          // --- SAVE BUTTON FOOTER ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Profile Changes',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
          letterSpacing: 1,
        ),
      ),
    );
  }
}
