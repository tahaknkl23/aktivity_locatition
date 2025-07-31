import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class RealMapLocationPicker extends StatefulWidget {
  final String? initialCoordinates; // "lat, lng" formatında
  final String title;

  const RealMapLocationPicker({
    super.key,
    this.initialCoordinates,
    this.title = 'Konum Seç',
  });

  @override
  State<RealMapLocationPicker> createState() => _RealMapLocationPickerState();
}

class _RealMapLocationPickerState extends State<RealMapLocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  MapLocationData? _selectedLocation;
  bool _isLoading = false;
  bool _isGettingCurrentLocation = false;
  List<SearchResult> _searchResults = [];
  bool _showSearchResults = false;

  // Varsayılan konum (Türkiye - Ankara)
  static const LatLng _defaultLocation = LatLng(39.9334, 32.8597);

  @override
  void initState() {
    super.initState();

    // Mevcut koordinatları yükle
    if (widget.initialCoordinates != null && widget.initialCoordinates!.isNotEmpty) {
      _parseInitialCoordinates(widget.initialCoordinates!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _parseInitialCoordinates(String coordinates) {
    try {
      final parts = coordinates.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());

        if (mounted) {
          setState(() {
            _selectedLocation = MapLocationData(
              latitude: lat,
              longitude: lng,
              address: 'Seçilen konum',
              coordinates: coordinates,
            );
          });

          // Haritayı başlangıç konumuna taşı
          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted) {
              _mapController.move(LatLng(lat, lng), 15.0);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Invalid initial coordinates: $coordinates');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isGettingCurrentLocation = true;
    });

    try {
      // Konum iznini kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Konum izni reddedildi';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Konum izni kalıcı olarak reddedildi. Ayarlardan açın.';
      }

      // Mevcut konumu al
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      if (!mounted) return;

      final location = MapLocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Mevcut konum',
        coordinates: '${position.latitude}, ${position.longitude}',
      );

      setState(() {
        _selectedLocation = location;
      });

      // Haritayı mevcut konuma taşı
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );

      _showSuccessMessage('✅ Mevcut konum alındı');
    } catch (e) {
      if (mounted) {
        _showErrorMessage('❌ Konum alınamadı: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingCurrentLocation = false;
        });
      }
    }
  }

  Future<void> _onMapTapped(LatLng position) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _showSearchResults = false;
    });

    try {
      // Reverse geocoding ile adres al
      final address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      final location = MapLocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        coordinates: '${position.latitude}, ${position.longitude}',
      );

      setState(() {
        _selectedLocation = location;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Adres alınamadı: ${e.toString()}');
      }
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      // Nominatim (OpenStreetMap) reverse geocoding
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Flutter-App/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _formatAddress(data);
      } else {
        return 'Adres bulunamadı';
      }
    } catch (e) {
      debugPrint('Address lookup error: $e');
      return 'Konum: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }
  }

  String _formatAddress(Map<String, dynamic> data) {
    try {
      final address = data['address'] ?? {};
      List<String> parts = [];

      if (address['road'] != null) parts.add(address['road']);
      if (address['neighbourhood'] != null) parts.add(address['neighbourhood']);
      if (address['district'] != null) parts.add(address['district']);
      if (address['state'] != null) parts.add(address['state']);
      if (address['country'] != null) parts.add(address['country']);

      return parts.isNotEmpty ? parts.join(', ') : data['display_name'] ?? 'Bilinmeyen konum';
    } catch (e) {
      return data['display_name'] ?? 'Bilinmeyen konum';
    }
  }

  Future<void> _searchLocation(String query) async {
    if (!mounted || query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _showSearchResults = false;
        });
      }
      return;
    }

    try {
      // Türkiye odaklı gelişmiş arama
      String searchQuery = query.trim();

      // Eğer Türkiye yazılmamışsa ekle
      if (!searchQuery.toLowerCase().contains('türkiye') && !searchQuery.toLowerCase().contains('turkey')) {
        searchQuery += ', Türkiye';
      }

      // Nominatim search - Türkiye'ye odaklanmış
      final url = 'https://nominatim.openstreetmap.org/search'
          '?format=json'
          '&q=${Uri.encodeComponent(searchQuery)}'
          '&limit=8'
          '&addressdetails=1'
          '&countrycodes=tr' // Sadece Türkiye
          '&bounded=1' // Sınırlar dahilinde
          '&viewbox=25.66,35.81,44.83,42.11' // Türkiye koordinat kutusu
          '&accept-language=tr'; // Türkçe sonuçlar

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'AktivityApp/1.0 (Flutter Mobile App)',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Sonuçları kalite kontrolünden geçir
        final results = data
            .map((item) => SearchResult.fromJson(item))
            .where((result) => result.displayName.toLowerCase().contains('türkiye') || result.displayName.toLowerCase().contains('turkey'))
            .toList();

        if (mounted) {
          setState(() {
            _searchResults = results;
            _showSearchResults = results.isNotEmpty;
          });

          // Eğer hiç sonuç yoksa, daha geniş arama yap
          if (results.isEmpty && !searchQuery.contains('türkiye')) {
            _searchLocationFallback(query);
          }
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      // Hata durumunda basit arama dene
      if (mounted) {
        _searchLocationFallback(query);
      }
    }
  }

  // Fallback arama metodu
  Future<void> _searchLocationFallback(String query) async {
    if (!mounted) return;

    try {
      final url = 'https://nominatim.openstreetmap.org/search'
          '?format=json'
          '&q=${Uri.encodeComponent(query)}'
          '&limit=5'
          '&addressdetails=1'
          '&accept-language=tr';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'AktivityApp/1.0',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data.map((item) => SearchResult.fromJson(item)).toList();

        if (mounted) {
          setState(() {
            _searchResults = results;
            _showSearchResults = results.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint('Fallback search error: $e');
    }
  }

  void _selectSearchResult(SearchResult result) {
    if (!mounted) return;

    final location = MapLocationData(
      latitude: result.lat,
      longitude: result.lon,
      address: result.displayName,
      coordinates: '${result.lat}, ${result.lon}',
    );

    setState(() {
      _selectedLocation = location;
      _showSearchResults = false;
      _searchController.clear();
      _searchResults = [];
    });

    // Haritayı seçilen konuma taşı
    _mapController.move(LatLng(result.lat, result.lon), 15.0);
  }

  void _clearLocation() {
    if (!mounted) return;

    setState(() {
      _selectedLocation = null;
    });
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(8),
      child: Container(
        height: size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildHeader(size),
            _buildSearchBar(size),
            if (_showSearchResults) _buildSearchResults(size),
            Expanded(child: _buildMap(size)),
            if (_selectedLocation != null) _buildLocationInfo(size),
            _buildActions(size),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.map, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Adres ara... (örn: Atatürk Caddesi Ankara)',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    // 2 karakterden sonra ara
                    if (value.length >= 2) {
                      _searchLocation(value);
                    } else if (mounted) {
                      setState(() {
                        _searchResults = [];
                        _showSearchResults = false;
                      });
                    }
                  },
                ),
              ),
              SizedBox(width: 12),
              _isGettingCurrentLocation
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: _getCurrentLocation,
                      icon: Icon(Icons.my_location, color: AppColors.primary),
                      tooltip: 'Mevcut konumu al',
                    ),
            ],
          ),

          // Arama örnekleri
          SizedBox(height: 8),
          Text(
            'Örnekler: "Kızılay Ankara", "Atatürk Caddesi", "Migros Malatya"',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AppSizes size) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return ListTile(
            leading: Icon(Icons.location_on, color: AppColors.primary),
            title: Text(
              result.displayName,
              style: TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _selectSearchResult(result),
          );
        },
      ),
    );
  }

  Widget _buildMap(AppSizes size) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation != null ? LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude) : _defaultLocation,
                initialZoom: _selectedLocation != null ? 15.0 : 6.0,
                onTap: (tapPosition, point) => _onMapTapped(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.aktivity_location_app',
                  maxZoom: 19,
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude),
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (_isLoading)
              Container(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Zoom controls
            Positioned(
              right: 16,
              top: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: "zoom_in",
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    },
                    backgroundColor: Colors.white,
                    child: Icon(Icons.add),
                  ),
                  SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: "zoom_out",
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    },
                    backgroundColor: Colors.white,
                    child: Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(AppSizes size) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.success),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seçilen Konum:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedLocation!.address,
                  style: TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selectedLocation!.coordinates,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearLocation,
            icon: Icon(Icons.clear, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _selectedLocation != null ? () => Navigator.of(context).pop(_selectedLocation) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 20),
                  SizedBox(width: 8),
                  Text('Konumu Seç'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapLocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String coordinates;

  MapLocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.coordinates,
  });
}

class SearchResult {
  final String displayName;
  final double lat;
  final double lon;

  SearchResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat'].toString()),
      lon: double.parse(json['lon'].toString()),
    );
  }
}
