import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpSent = false;
  int _timerSeconds = 30;
  Timer? _timer;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timerSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _handleSendOtp() async {
    setState(() {
      _errorMessage = '';
    });
    
    final phone = _phoneController.text.trim();
    if (phone.length != 10 || int.tryParse(phone) == null) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(phone);
    
    if (success) {
      setState(() {
        _isOtpSent = true;
      });
      _startTimer();
      // Auto focus first OTP field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otpFocusNodes[0].requestFocus();
      });
    } else {
      setState(() {
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_timerSeconds > 0) return;

    final phone = _phoneController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendOtp(phone);
    
    if (success) {
      setState(() {
        _errorMessage = '';
        for (var c in _otpControllers) {
          c.clear();
        }
      });
      _startTimer();
      _otpFocusNodes[0].requestFocus();
    } else {
      setState(() {
        _errorMessage = 'Failed to resend OTP. Please try again.';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() {
      _errorMessage = '';
    });

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6 || int.tryParse(otp) == null) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP code';
      });
      return;
    }

    final phone = _phoneController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.verifyOtp(phone, otp);

    if (result['success'] == true) {
      // GoRouter redirect handles moving to /home automatically
      if (mounted) {
        context.go('/home');
      }
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Invalid OTP code. Please try again.';
      });
    }
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile Number',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: 'Enter 10-digit phone number',
            prefixText: '+91 ',
            prefixStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            counterText: '',
          ),
          onSubmitted: (_) => _handleSendOtp(),
        ),
        const SizedBox(height: 24),
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return ElevatedButton(
              onPressed: auth.isLoading ? null : _handleSendOtp,
              child: auth.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Send OTP'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enter 6-digit OTP',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isOtpSent = false;
                  _errorMessage = '';
                });
              },
              child: Text(
                'Change Number',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF37920),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // OTP Inputs Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 54,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF004680),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF004680), width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    if (index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else {
                      _otpFocusNodes[index].unfocus();
                      _handleVerifyOtp();
                    }
                  } else {
                    if (index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  }
                },
              ),
            );
          }),
        ),
        
        const SizedBox(height: 20),
        
        // Resend Timer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _timerSeconds > 0 ? 'Resend OTP in 0:$_timerSeconds' : 'Did not receive OTP?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            TextButton(
              onPressed: _timerSeconds > 0 ? null : _handleResendOtp,
              child: Text(
                'Resend OTP',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _timerSeconds > 0 ? const Color(0xFFCBD5E1) : const Color(0xFF004680),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return ElevatedButton(
              onPressed: auth.isLoading ? null : _handleVerifyOtp,
              child: auth.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Verify & Proceed'),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // App Brand Header Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF004680),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.build_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Welcome Text Headers
              Text(
                _isOtpSent ? 'Verify OTP Code' : 'Welcome to JoharFix',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isOtpSent 
                    ? 'Enter the 6-digit code sent to +91 ${_phoneController.text}'
                    : 'Enter your phone number to proceed with verified home services.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Error feedback element
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
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
                const SizedBox(height: 20),
              ],
              
              // Input state block
              _isOtpSent ? _buildOtpInput() : _buildPhoneInput(),
              
              const SizedBox(height: 60),
              
              // Terms & Conditions footnote
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                    children: const [
                      TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
