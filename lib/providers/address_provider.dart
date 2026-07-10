import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/storage_service.dart';
import '../models/address_model.dart';

class AddressProvider extends ChangeNotifier {
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  bool _loading = false;

  List<AddressModel> get addresses => List.unmodifiable(_addresses);
  AddressModel? get selectedAddress => _selectedAddress;
  bool get loading => _loading;

  AddressProvider() {
    loadAddresses();
  }

  // Load addresses from API with secure local storage caching
  Future<void> loadAddresses() async {
    _loading = true;
    notifyListeners();

    try {
      final token = await StorageService.instance.getUserToken();
      if (token != null) {
        final response = await ApiClient.instance.get('/customer/addresses');
        if (response.data != null && response.data['status'] == 'success') {
          final List<dynamic> data = response.data['data'] ?? [];
          _addresses = data.map((json) => AddressModel.fromJson(json)).toList();

          final storedSelectedId = await StorageService.instance.read(AppConstants.keySelectedAddressId);
          AddressModel? selected;
          if (storedSelectedId != null) {
            selected = _addresses.firstWhere(
              (a) => a.id == storedSelectedId,
              orElse: () => _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.isNotEmpty ? _addresses.first : _addresses.first), // will check length below
            );
          }
          
          if (selected == null && _addresses.isNotEmpty) {
            selected = _addresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => _addresses.first,
            );
          }

          _selectedAddress = selected;
          
          // Cache locally
          final cacheJson = jsonEncode(_addresses.map((a) => a.toJson()).toList());
          await StorageService.instance.write(AppConstants.keyUserAddresses, cacheJson);
          _loading = false;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load addresses from API, trying offline fallback: $e');
    }

    // Offline Fallback
    try {
      final cachedJson = await StorageService.instance.read(AppConstants.keyUserAddresses);
      final storedSelectedId = await StorageService.instance.read(AppConstants.keySelectedAddressId);
      
      if (cachedJson != null) {
        final List<dynamic> parsed = jsonDecode(cachedJson);
        _addresses = parsed.map((json) => AddressModel.fromJson(json)).toList();

        if (storedSelectedId != null && _addresses.isNotEmpty) {
          _selectedAddress = _addresses.firstWhere(
            (a) => a.id == storedSelectedId,
            orElse: () => _addresses.first,
          );
        } else if (_addresses.isNotEmpty) {
          _selectedAddress = _addresses.first;
        }
      }
    } catch (e) {
      debugPrint('Error reading address cache: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Reload addresses manually
  Future<void> refreshAddresses() async {
    ApiClient.instance.clearCache();
    await loadAddresses();
  }

  // Set the default selected address
  Future<void> selectAddress(String id) async {
    final selected = _addresses.firstWhere((a) => a.id == id);
    // Optimistic UI updates
    _addresses = _addresses.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    _selectedAddress = selected.copyWith(isDefault: true);
    notifyListeners();

    await StorageService.instance.write(AppConstants.keySelectedAddressId, id);
    final cacheJson = jsonEncode(_addresses.map((a) => a.toJson()).toList());
    await StorageService.instance.write(AppConstants.keyUserAddresses, cacheJson);

    try {
      await ApiClient.instance.put('/customer/addresses/$id', data: {
        'is_default': true,
        'type': selected.type,
        'landmark': selected.landmark,
        'city': selected.city,
        'state': selected.state,
        'pincode': selected.pincode,
        'lat': selected.lat,
        'lng': selected.lng,
      });
    } catch (e) {
      debugPrint('Failed to update default address on API: $e');
    }
  }

  // Generate next automatic label (e.g. "Home 2" if "Home" already exists)
  String _generateNextLabel(String type) {
    final sameType = _addresses.where((a) => a.type == type).toList();
    if (sameType.isEmpty) return type;
    
    // Find numeric suffixes
    final suffixes = sameType.map((a) {
      final label = a.label ?? type;
      final parts = label.split(' ');
      if (parts.length > 1) {
        final last = parts.last;
        final num = int.tryParse(last);
        if (num != null) return num;
      }
      return 1; // Default suffix is 1 if just type name
    }).toList();

    if (suffixes.isEmpty) return type;
    final max = suffixes.fold(0, (maxVal, val) => val > maxVal ? val : maxVal);
    return max == 0 ? '$type 2' : '$type ${max + 1}';
  }

  // Add Address
  Future<bool> addAddress(Map<String, dynamic> addressData) async {
    _loading = true;
    notifyListeners();

    final label = _generateNextLabel(addressData['type'] as String? ?? 'Home');

    final payload = {
      ...addressData,
      'label': label,
      'is_default': _addresses.isEmpty,
    };

    try {
      final response = await ApiClient.instance.post('/customer/addresses', data: payload);
      if (response.data != null && response.data['status'] == 'success') {
        final newAddress = AddressModel.fromJson(response.data['data']);
        
        _addresses.add(newAddress);
        _selectedAddress = newAddress;
        await StorageService.instance.write(AppConstants.keySelectedAddressId, newAddress.id);
        
        final cacheJson = jsonEncode(_addresses.map((a) => a.toJson()).toList());
        await StorageService.instance.write(AppConstants.keyUserAddresses, cacheJson);
        
        _loading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Failed to add address via API, creating local temp address: $e');
      
      // Fallback local temp address
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final newAddress = AddressModel(
        id: tempId,
        type: addressData['type'] as String? ?? 'Home',
        label: label,
        houseNo: addressData['house_no'] as String?,
        landmark: addressData['landmark'] as String? ?? '',
        city: addressData['city'] as String? ?? '',
        state: addressData['state'] as String? ?? '',
        pincode: addressData['pincode'] as String? ?? '',
        lat: addressData['lat'] as double? ?? 0.0,
        lng: addressData['lng'] as double? ?? 0.0,
        contactName: addressData['contact_name'] as String?,
        contactNumber: addressData['contact_number'] as String?,
        isDefault: _addresses.isEmpty,
      );

      _addresses.add(newAddress);
      _selectedAddress = newAddress;
      await StorageService.instance.write(AppConstants.keySelectedAddressId, tempId);

      final cacheJson = jsonEncode(_addresses.map((a) => a.toJson()).toList());
      await StorageService.instance.write(AppConstants.keyUserAddresses, cacheJson);
    }

    _loading = false;
    notifyListeners();
    return true;
  }

  // Update Address
  Future<bool> updateAddress(String id, Map<String, dynamic> addressData) async {
    _loading = true;
    notifyListeners();

    try {
      final response = await ApiClient.instance.put('/customer/addresses/$id', data: addressData);
      if (response.data != null && response.data['status'] == 'success') {
        final updatedAddress = AddressModel.fromJson(response.data['data']);
        
        _addresses = _addresses.map((a) => a.id == id ? updatedAddress : a).toList();
        if (_selectedAddress?.id == id) {
          _selectedAddress = updatedAddress;
        }

        final cacheJson = jsonEncode(_addresses.map((a) => a.toJson()).toList());
        await StorageService.instance.write(AppConstants.keyUserAddresses, cacheJson);
        
        _loading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Failed to update address via API, updating locally: $e');

      // Local fallback
      _addresses = _addresses.map((addr) {
        if (addr.id == id) {
          return addr.copyWith(
            type: addressData['type'] as String?,
            houseNo: addressData['house_no'] as String?,
            landmark: addressData['landmark'] as String?,
            city: addressData['city'] as String?,
            state: addressData['state'] as String?,
            pincode: addressData['pincode'] as String?,
            lat: addressData['lat'] as double?,
            lng: addressData['lng'] as double?,
            contactName: addressData['contact_name'] as String?,
            contactNumber: addressData['contact_number'] as String?,
          );
        }
        return addr;
      }).toList();

      if (_selectedAddress?.id == id) {
        _selectedAddress = _addresses.firstWhere((a) => a.id == id);
      }

      final cacheJson = jsonEncode(_addresses.map((a) => a.toJson()).toList());
      await StorageService.instance.write(AppConstants.keyUserAddresses, cacheJson);
    }

    _loading = false;
    notifyListeners();
    return true;
  }

  // Delete Address
  Future<bool> deleteAddress(String id) async {
    _loading = true;
    notifyListeners();

    try {
      await ApiClient.instance.delete('/customer/addresses/$id');
      await loadAddresses();
      return true;
    } catch (e) {
      debugPrint('Failed to delete address via API, deleting locally: $e');
      
      _addresses = _addresses.where((a) => a.id != id).toList();
      if (_selectedAddress?.id == id) {
        _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
      }

      final cacheJson = jsonEncode(_addresses.map((a) => a.toJson()).toList());
      await StorageService.instance.write(AppConstants.keyUserAddresses, cacheJson);
      
      _loading = false;
      notifyListeners();
      return true;
    }
  }
}
