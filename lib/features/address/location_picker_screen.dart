import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(22.7196, 75.8577); // Default Indore (India) coords
  bool _loadingAddress = false;
  String _formattedAddress = 'Select location on map';
  
  // Geocoded details to pass to address form
  String _houseNo = '';
  String _landmark = '';
  String _city = '';
  String _state = '';
  String _pincode = '';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Request GPS hardware position
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      _reverseGeocode(latLng);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  // Google Reverse Geocoding API call
  Future<void> _reverseGeocode(LatLng position) async {
    if (_loadingAddress) return;
    setState(() {
      _loadingAddress = true;
    });

    final url = 'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${position.latitude},${position.longitude}'
        '&key=${AppConstants.googleMapsApiKey}';

    try {
      final response = await Dio().get(url);
      if (response.data != null && response.data['status'] == 'OK') {
        final results = response.data['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          final firstResult = results.first;
          final formatted = firstResult['formatted_address'] as String;
          final addressComponents = firstResult['address_components'] as List<dynamic>;

          String tempHouseNo = '';
          String tempLandmark = '';
          String tempCity = '';
          String tempState = '';
          String tempPincode = '';

          for (var component in addressComponents) {
            final types = component['types'] as List<dynamic>;
            if (types.contains('premise') || types.contains('street_number')) {
              tempHouseNo = component['long_name'] as String;
            } else if (types.contains('sublocality') || types.contains('neighborhood')) {
              tempLandmark = component['long_name'] as String;
            } else if (types.contains('locality')) {
              tempCity = component['long_name'] as String;
            } else if (types.contains('administrative_area_level_1')) {
              tempState = component['long_name'] as String;
            } else if (types.contains('postal_code')) {
              tempPincode = component['long_name'] as String;
            }
          }

          if (mounted) {
            setState(() {
              _formattedAddress = formatted;
              _houseNo = tempHouseNo;
              _landmark = tempLandmark;
              _city = tempCity;
              _state = tempState;
              _pincode = tempPincode;
              _loadingAddress = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }

    if (mounted) {
      setState(() {
        _formattedAddress = 'Location selected (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        _loadingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Delivery Location'),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 16.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _reverseGeocode(_currentPosition);
            },
            onCameraMove: (position) {
              _currentPosition = position.target;
            },
            onCameraIdle: () {
              _reverseGeocode(_currentPosition);
            },
          ),

          // Central Draggable Pin Icon
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppTheme.secondary,
                  size: 44,
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 38), // Offset to account for icon bounds height
              ],
            ),
          ),

          // Locate Me GPS floating button
          Positioned(
            right: 20,
            bottom: 230,
            child: FloatingActionButton(
              onPressed: _determinePosition,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              mini: true,
              elevation: 4,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Bottom details drawer
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.secondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Confirm Location Details',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _loadingAddress
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                            ),
                          ),
                        )
                      : Text(
                          _formattedAddress,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadingAddress
                        ? null
                        : () {
                            context.push(
                              '/add-address',
                              extra: {
                                'lat': _currentPosition.latitude,
                                'lng': _currentPosition.longitude,
                                'house_no': _houseNo,
                                'landmark': _landmark,
                                'city': _city,
                                'state': _state,
                                'pincode': _pincode,
                              },
                            );
                          },
                    child: const Text('Confirm & Continue'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
