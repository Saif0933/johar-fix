import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';

class AddAddressScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const AddAddressScreen({super.key, required this.initialData});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _houseController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  
  String _selectedType = 'Home';
  String _selectedContactType = 'Self';
  double _lat = 0.0;
  double _lng = 0.0;

  @override
  void initState() {
    super.initState();
    
    _lat = double.tryParse(widget.initialData['lat']?.toString() ?? '0.0') ?? 0.0;
    _lng = double.tryParse(widget.initialData['lng']?.toString() ?? '0.0') ?? 0.0;

    // Preset fields from geocoded values
    _houseController = TextEditingController(text: widget.initialData['house_no']?.toString() ?? '');
    _landmarkController = TextEditingController(text: widget.initialData['landmark']?.toString() ?? '');
    _cityController = TextEditingController(text: widget.initialData['city']?.toString() ?? '');
    _stateController = TextEditingController(text: widget.initialData['state']?.toString() ?? '');
    _pincodeController = TextEditingController(text: widget.initialData['pincode']?.toString() ?? '');
    
    // Preset contact info from user profile
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _contactNameController = TextEditingController(text: authProvider.profile?.name ?? 'Customer');
    _contactPhoneController = TextEditingController(text: authProvider.profile?.phone ?? '');
  }

  @override
  void dispose() {
    _houseController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    
    final payload = {
      'type': _selectedType,
      'house_no': _houseController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'lat': _lat,
      'lng': _lng,
      'contact_name': _contactNameController.text.trim(),
      'contact_number': _contactPhoneController.text.trim(),
    };

    final success = await addressProvider.addAddress(payload);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added successfully!')),
      );
      // Go back to address list or home
      context.pop(); // Pop AddAddressScreen
      context.pop(); // Pop LocationPickerScreen
    }
  }

  Widget _buildTypeButton(String type, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                type,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTypeButton(String type, IconData icon) {
    final isSelected = _selectedContactType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedContactType = type;
            if (type == 'Self') {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              _contactNameController.text = authProvider.profile?.name ?? 'Customer';
              _contactPhoneController.text = authProvider.profile?.phone ?? '';
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                type,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
            prefixText: prefixText,
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Add New Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map preview container
              Container(
                height: 180,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_lat, _lng),
                        zoom: 16.0,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('selected_loc'),
                          position: LatLng(_lat, _lng),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                        ),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppTheme.primary, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'LOCATION SELECTED',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                context.pop();
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'CHANGE',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Address Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADDRESS DETAILS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'HOUSE NO. / BUILDING NAME / FLAT NO',
                      controller: _houseController,
                      icon: Icons.apartment_outlined,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter flat or house details' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'ROAD / AREA / LANDMARK *',
                      controller: _landmarkController,
                      icon: Icons.map_outlined,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter landmark or street name' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'CITY *',
                            controller: _cityController,
                            icon: Icons.location_on_outlined,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Enter city' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormField(
                            label: 'STATE *',
                            controller: _stateController,
                            icon: Icons.explore_outlined,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Enter state' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'PINCODE *',
                      controller: _pincodeController,
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter pincode' : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SAVE ADDRESS AS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildTypeButton('Home', Icons.home_outlined),
                        const SizedBox(width: 10),
                        _buildTypeButton('Work', Icons.work_outline),
                        const SizedBox(width: 10),
                        _buildTypeButton('Other', Icons.location_on_outlined),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Contact Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTACT INFO',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildContactTypeButton('Self', Icons.person_outline),
                        const SizedBox(width: 10),
                        _buildContactTypeButton('Someone else', Icons.group_outlined),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedContactType == 'Self') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_contactNameController.text} • ${_contactPhoneController.text}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      _buildFormField(
                        label: 'CONTACT NAME',
                        controller: _contactNameController,
                        icon: Icons.person_outline,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        label: 'CONTACT PHONE NUMBER',
                        controller: _contactPhoneController,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        prefixText: '+91 ',
                        validator: (value) => value == null || value.trim().length != 10 ? 'Enter a valid 10-digit number' : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: addressProvider.loading ? null : _handleSaveAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 54),
            ),
            child: addressProvider.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Save Address',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
