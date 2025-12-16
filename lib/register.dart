import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glowvita/calender.dart';
import 'package:glowvita/login.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui';
import 'package:flutter/services.dart';


class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _Signup();
}

class _Signup extends State<Signup> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController salonNameController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String selectedCountry = 'India';
  String selectedState = 'Select State';
  String selectedCity = 'Select City';
  List<String> getCitiesForState(String state) {
    return stateCityMap[state] ?? [];
  }

  List<String> cityList = ['Select City'];

  final Map<String, List<String>> stateCityMap = {
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore'],
    'Arunachal Pradesh': ['Itanagar', 'Tawang', 'Ziro', 'Pasighat'],
    'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat'],
    'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur'],
    'Chhattisgarh': ['Raipur', 'Bilaspur', 'Durg', 'Korba'],
    'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Mapusa'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot'],
    'Haryana': ['Chandigarh', 'Faridabad', 'Gurugram', 'Hisar'],
    'Himachal Pradesh': ['Shimla', 'Manali', 'Dharamshala', 'Kullu'],
    'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Hubli', 'Mangalore'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur'],
    'Madhya Pradesh': ['Bhopal', 'Indore', 'Jabalpur', 'Gwalior'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik'],
    'Manipur': ['Imphal', 'Thoubal', 'Churachandpur', 'Bishnupur'],
    'Meghalaya': ['Shillong', 'Tura', 'Nongpoh', 'Jowai'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Champhai', 'Serchhip'],
    'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Tuensang'],
    'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Puri'],
    'Punjab': ['Amritsar', 'Ludhiana', 'Jalandhar', 'Patiala'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota'],
    'Sikkim': ['Gangtok', 'Namchi', 'Geyzing', 'Mangan'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Khammam'],
    'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar', 'Kailashahar'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Agra', 'Varanasi'],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Nainital', 'Roorkee'],
    'West Bengal': ['Kolkata', 'Asansol', 'Siliguri', 'Durgapur'],
    'Delhi': ['New Delhi', 'Dwarka', 'Rohini', 'Saket'],
  };

  double selectedLatitude = 0.0;
  double selectedLongitude = 0.0;
  String selectedAddress = '';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Stack(
            children: [
              // Background Image
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/splash.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Blur Layer
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0), // Adjust blur intensity
                  child: Container(
                    color: Colors.black.withOpacity(0), // Transparent color for blur effect
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      'Let’s Get Started',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color:Colors.blue, // Your highlight text color
                        shadows: [
                          Shadow(
                            offset: Offset(1.5, 1.5),
                            blurRadius: 1.5,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      'Create your account by filling the form below',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF5F5F5), // Your highlight text color
                        shadows: [
                          Shadow(
                            offset: Offset(3.0, 3.0),
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(controller: firstNameController, label: 'First Name')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(controller: lastNameController, label: 'Last Name')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(controller: emailController, label: 'Email Address'),
                    const SizedBox(height: 16),
                    _buildTextField(controller: mobileController, label: 'Mobile Number', type: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(controller: salonNameController, label: 'Salon Name'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Country',
                            value: selectedCountry,
                            items: ['India'],
                            onChanged: (val) => setState(() => selectedCountry = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDropdown(
                            label: 'State',
                            value: selectedState,
                            items: ['Select State', ...stateCityMap.keys.toSet().toList()],
                            onChanged: (val) {
                              setState(() {
                                selectedState = val!;
                                selectedCity = 'Select City';
                                cityList = ['Select City', ...getCitiesForState(selectedState)];
                              });
                            },

                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'City',
                            value: cityList.contains(selectedCity) ? selectedCity : cityList[0],
                            items: cityList,
                            onChanged: (val) => setState(() => selectedCity = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(controller: pinController, label: 'PIN Code', type: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Location',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final location = await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (context) => const LocationPickerDialog(),
                              );
                              if (location != null) {
                                setState(() {
                                  selectedLatitude = location['lat'];
                                  selectedLongitude = location['lng'];
                                  selectedAddress = location['address'];
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                selectedAddress.isNotEmpty ? selectedAddress : "Select Location on Map",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(controller: passwordController, label: 'Password', obscure: _obscurePassword, toggleVisibility: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    }),
                    const SizedBox(height: 16),
                    _buildPasswordField(controller: confirmPasswordController, label: 'Confirm Password', obscure: _obscureConfirmPassword, toggleVisibility: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    }),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Calendar(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Sign Up', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold,
                        )),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account ? ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF5F5F5), // Your highlight text color
                            shadows: [
                              Shadow(
                                offset: Offset(3.0, 3.0),
                                blurRadius: 3.0,
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: ()
                          {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const Login()),
                            );
                          },
                          child:  Text("Log in", style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue, // Your highlight text color
                            shadows: [
                          Shadow(
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.50),
                            offset: Offset(1.5, 1.5),
                          ),
                        ],
                          ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType type = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: type,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          label: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String label, required bool obscure, required VoidCallback toggleVisibility}) {
    return _buildTextField(
      controller: controller,
      label: label,
      obscureText: obscure,
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility : Icons.visibility_off,
          color: Colors.blue.shade700,
          size: 18,
        ),
        onPressed: toggleVisibility,
      ),
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        items: items.map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        )).toList(),
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          label: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          isDense: true,
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
        dropdownColor: Colors.white,
        isExpanded: true,
      ),
    );
  }

}

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  LatLng selectedLocation = LatLng(28.598392, 77.163469);
  String address = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  final MapController _mapController = MapController();

  Future<void> _updateAddress(LatLng point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          address = '${p.street ?? ''} ${p.subLocality ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''} ${p.postalCode ?? ''}'.replaceAll('  ', ' ').trim();
          if (address.endsWith(',')) {
            address = address.substring(0, address.length - 1).trim();
          }
          _searchController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        address = '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
        _searchController.text = address;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          bool? serviceEnabledRequested = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text('Please enable location services to find your current location.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    Geolocator.openLocationSettings();
                    Navigator.pop(context, true);
                  },
                  child: const Text('OPEN SETTINGS'),
                ),
              ],
            ),
          );
          
          if (serviceEnabledRequested != true) {
            return;
          }
        }
      } catch (e) {
        debugPrint('Error checking location service: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error checking location services. Please try again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to find your current location.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          bool? openSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                'Location permissions are permanently denied. Please enable them in app settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    Geolocator.openAppSettings();
                    Navigator.pop(context, true);
                  },
                  child: const Text('OPEN SETTINGS'),
                ),
              ],
            ),
          );
          
          if (openSettings == true) {
            // Wait a moment for the user to return from settings
            await Future.delayed(const Duration(seconds: 1));
            // Retry getting location after returning from settings
            _getCurrentLocation();
          }
        }
        return;
      }

      // Get the current position with timeout
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
        
        final newLocation = LatLng(position.latitude, position.longitude);
        
        if (mounted) {
          setState(() {
            selectedLocation = newLocation;
          });
          
          // Animate map to the new location
          _mapController.move(newLocation, 15.0);
          
          // Update address after a short delay to ensure map has moved
          await Future.delayed(const Duration(milliseconds: 300));
          await _updateAddress(newLocation);
        }
      } on TimeoutException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Getting location is taking longer than expected. Please check your connection.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error getting location: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      elevation: 4,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Your Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a location',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onSubmitted: (value) async {
                  if (value.isEmpty) return;
                  
                  setState(() => _isLoading = true);
                  
                  try {
                    List<Location> locations = await locationFromAddress(value).timeout(
                      const Duration(seconds: 10),
                      onTimeout: () {
                        throw TimeoutException('Location search timed out');
                      },
                    );
                    
                    if (locations.isEmpty) {
                      throw Exception('No matching locations found');
                    }
                    
                    final location = locations.first;
                    final newLocation = LatLng(location.latitude, location.longitude);
                    
                    setState(() {
                      selectedLocation = newLocation;
                    });
                    
                    // Animate map to the new location
                    _mapController.move(newLocation, 15.0);
                    
                    // Update address after a short delay to ensure map has moved
                    await Future.delayed(const Duration(milliseconds: 300));
                    await _updateAddress(newLocation);
                    
                  } on TimeoutException {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Search is taking too long. Please try again.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error searching location: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e is TimeoutException 
                              ? 'Search timed out. Please check your connection.'
                              : 'Could not find the location. Please try a different search term.'
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.my_location, size: 20),
                label: const Text('Use Current Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: selectedLocation,
                      zoom: 15.0,
                      onTap: (tapPosition, point) {
                        setState(() => selectedLocation = point);
                        _updateAddress(point);
                      },
                      onMapReady: () {
                        // Ensure map is properly centered on the selected location
                        if (_mapController.camera.center != selectedLocation) {
                          _mapController.move(selectedLocation, _mapController.camera.zoom);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.glowvita.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: selectedLocation,
                            child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Location:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.isNotEmpty ? address : 'Tap on the map to select a location',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCEL"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'lat': selectedLocation.latitude,
                        'lng': selectedLocation.longitude,
                        'address': address.isNotEmpty ? address : '${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}',
                      });
                    },
                    child: const Text("CONFIRM LOCATION", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
