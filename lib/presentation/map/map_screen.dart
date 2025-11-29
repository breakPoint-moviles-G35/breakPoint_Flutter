import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:flutter/foundation.dart';

import '../explore/viewmodel/explore_viewmodel.dart';
import '../details/space_detail_screen.dart';
import '../../domain/entities/space.dart';
import '../../core/services/location_service.dart';

// Modelo para pasar datos al Isolate
class MarkerData {
  final String id;
  final String title;
  final String? subtitle;
  final double price;
  final dynamic geo;
  final String imageUrl;
  final double rating;

  MarkerData({
    required this.id,
    required this.title,
    this.subtitle,
    required this.price,
    required this.geo,
    required this.imageUrl,
    this.rating = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'price': price,
        'geo': geo,
        'imageUrl': imageUrl,
        'rating': rating,
      };

  factory MarkerData.fromJson(Map<String, dynamic> json) => MarkerData(
        id: json['id'],
        title: json['title'],
        subtitle: json['subtitle'],
        price: json['price'],
        geo: json['geo'],
        imageUrl: json['imageUrl'],
        rating: json['rating']?.toDouble() ?? 0.0,
      );
}

// Función que se ejecutará en un Isolate separado
Future<Set<Marker>> _createMarkersInIsolate(List<MarkerData> markersData) async {
  final port = ReceivePort();
  await Isolate.spawn(
    _isolateEntry,
    {
      'sendPort': port.sendPort,
      'markersData': markersData.map((m) => m.toJson()).toList(),
    },
  );

  return await port.first.then((result) {
    final markers = <Marker>{};
    for (final marker in (result as List)) {
      markers.add(Marker(
        markerId: MarkerId(marker['id']),
        position: LatLng(
          (marker['position'] as Map)['latitude'],
          (marker['position'] as Map)['longitude'],
        ),
        infoWindow: InfoWindow(
          title: marker['title'],
          snippet: marker['snippet'],
          onTap: () {
            // No se puede usar BuildContext aquí, manejaremos el tap desde el widget principal
          },
        ),
      ));
    }
    return markers;
  });
}

// Punto de entrada del Isolate
void _isolateEntry(Map<String, dynamic> message) {
  final sendPort = message['sendPort'] as SendPort;
  final markersData = (message['markersData'] as List)
      .map((m) => MarkerData.fromJson(Map<String, dynamic>.from(m)))
      .toList();

  final markers = <Map<String, dynamic>>[];
  
  for (final data in markersData) {
    final latLng = _parseLatLngInIsolate(data.geo);
    if (latLng != null) {
      markers.add({
        'id': data.id,
        'title': data.title,
        'snippet': data.subtitle?.isNotEmpty == true ? data.subtitle : '\$${data.price.toStringAsFixed(0)} COP',
        'position': {'latitude': latLng.latitude, 'longitude': latLng.longitude},
      });
    }
  }

  Isolate.exit(sendPort, markers);
}

// Función auxiliar para parsear coordenadas en el Isolate
LatLng? _parseLatLngInIsolate(dynamic geo) {
  try {
    if (geo == null) return null;
    
    if (geo is String) {
      final parts = geo.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) return LatLng(lat, lng);
      }
    } else if (geo is Map) {
      final lat = geo['lat'] ?? geo['latitude'];
      final lng = geo['lng'] ?? geo['lon'] ?? geo['longitude'];
      if (lat != null && lng != null) {
        return LatLng(
          (lat is num) ? lat.toDouble() : double.parse(lat.toString()),
          (lng is num) ? lng.toDouble() : double.parse(lng.toString()),
        );
      }
    } else if (geo is List && geo.length >= 2) {
      return LatLng(
        (geo[0] is num) ? geo[0].toDouble() : double.parse(geo[0].toString()),
        (geo[1] is num) ? geo[1].toDouble() : double.parse(geo[1].toString()),
      );
    }
  } catch (e) {
    debugPrint('Error parsing geo in isolate: $e');
  }
  return null;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapCtrl;
  MapType _mapType = MapType.normal;
  Set<Marker> _markers = {};
  bool _isLoadingMarkers = false;
  String? _markersError;

  // Centro por defecto (campus)
  static const _campusCenter = LatLng(4.60971, -74.08175);
  static const _defaultZoom = 15.0;

  LatLng? _myLatLng;
  bool _requestingLoc = false;

  // Nearest space state
  Space? _nearest;
  bool _loadingNearest = false;
  String? _nearestError;

  @override
  void initState() {
    super.initState();
    _prefetchMyLocation();
    
    // Cargar espacios para mostrar en el mapa
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<ExploreViewModel>();
      await vm.load();
      
      // Cargar marcadores en segundo plano
      _loadMarkers(vm.spaces);
      
      // Cargar última ubicación guardada
      final lastLocation = await LocationService.getLastLocation();
      if (lastLocation != null && mounted) {
        _myLatLng = lastLocation;
        _animateTo(_myLatLng!, 16);
      }
    });
  }
  
  // Cargar marcadores en un Isolate separado
  Future<void> _loadMarkers(List<Space> spaces) async {
    if (_isLoadingMarkers) return;
    
    setState(() {
      _isLoadingMarkers = true;
      _markersError = null;
    });
    
    try {
      // Convertir espacios a un formato serializable para el Isolate
      final markersData = spaces.map((space) => MarkerData(
        id: space.id,
        title: space.title,
        subtitle: space.subtitle,
        price: space.price,
        geo: space.geo,
        imageUrl: space.imageUrl,
        rating: space.rating,
      )).toList();
      
      // Generar marcadores en un Isolate separado
      final markers = await _createMarkersInIsolate(markersData);
      
      if (mounted) {
        setState(() {
          _markers = markers;
          _isLoadingMarkers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading markers: $e');
      if (mounted) {
        setState(() {
          _markersError = 'Error al cargar los marcadores';
          _isLoadingMarkers = false;
        });
      }
    }
  }

  Future<void> _prefetchMyLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _myLatLng = LatLng(pos.latitude, pos.longitude));
    } catch (_) {}
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar marcadores si la lista de espacios cambia
    final vm = context.read<ExploreViewModel>();
    if (vm.spaces.isNotEmpty && _markers.length != vm.spaces.length) {
      _loadMarkers(vm.spaces);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExploreViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de espacios'),
        actions: [
          IconButton(
            tooltip: 'Cambiar tipo de mapa',
            onPressed: () {
              setState(() {
                _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
              });
            },
            icon: const Icon(Icons.layers_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _campusCenter,
              zoom: _defaultZoom,
            ),
            mapType: _mapType,
            myLocationEnabled: true,        // ← punto azul
            myLocationButtonEnabled: false, // usamos nuestros FABs
            compassEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _mapCtrl = c,
            markers: _markers,
          ),

          // Bottom nearest card
          Positioned(
            left: 12,
            right: 12,
            bottom: 72,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildNearestCard(context),
            ),
          ),

          // Indicador de carga de espacios y marcadores
          if (vm.isLoading || _isLoadingMarkers)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      vm.isLoading
                          ? 'Cargando espacios...'
                          : 'Cargando marcadores...',
                    ),
                  ],
                ),
              ),
            ),
            
          // Mostrar error de carga de marcadores
          if (_markersError != null && !vm.isLoading)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_markersError!)),
                    TextButton(
                      onPressed: () => _loadMarkers(vm.spaces),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),

          if (vm.hasRange)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Align(
                alignment: Alignment.topLeft,
                child: InputChip(
                  label: Text('${vm.fmtIsoDay(vm.start!)} – ${vm.fmtIsoDay(vm.end!)}'),
                  onDeleted: () => vm.setStartEndFromRange(null),
                ),
              ),
            ),

          // FABs: Mi ubicación + Guardar ubicación + Campus + Lista
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Guardar ubicación actual
                FloatingActionButton.small(
                  heroTag: 'fab-save-loc',
                  tooltip: 'Guardar ubicación',
                  onPressed: _myLatLng != null 
                      ? () => _saveCurrentLocation(context) 
                      : null,
                  child: const Icon(Icons.bookmark_add),
                ),
                const SizedBox(height: 8),
                
                // Ir a mi ubicación
                FloatingActionButton.small(
                  heroTag: 'fab-my-loc',
                  tooltip: 'Ir a mi ubicación',
                  onPressed: _requestingLoc ? null : _goToMyLocation,
                  child: _requestingLoc
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),

                // Centrar en campus
                FloatingActionButton.small(
                  heroTag: 'fab-campus',
                  tooltip: 'Centrar en campus',
                  onPressed: () => _animateTo(_campusCenter, _defaultZoom),
                  child: const Icon(Icons.center_focus_strong),
                ),
                const SizedBox(height: 8),

                // Ver ubicaciones guardadas
                FloatingActionButton.small(
                  heroTag: 'fab-saved-locations',
                  tooltip: 'Ubicaciones guardadas',
                  onPressed: _showSavedLocations,
                  child: const Icon(Icons.bookmark),
                ),
                const SizedBox(height: 8),

                // Volver a la lista (Explore)
                FloatingActionButton.small(
                  heroTag: 'fab-list',
                  tooltip: 'Ver lista',
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.list_alt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Parsear coordenadas (versión optimizada para el Isolate)
  static LatLng? _parseLatLng(dynamic geo) {
    try {
      if (geo == null) return null;
      
      if (geo is String) {
        final parts = geo.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) return LatLng(lat, lng);
        }
      } else if (geo is Map) {
        final lat = geo['lat'] ?? geo['latitude'];
        final lng = geo['lng'] ?? geo['lon'] ?? geo['longitude'];
        if (lat != null && lng != null) {
          return LatLng(
            (lat is num) ? lat.toDouble() : double.parse(lat.toString()),
            (lng is num) ? lng.toDouble() : double.parse(lng.toString()),
          );
        }
      } else if (geo is List && geo.length >= 2) {
        return LatLng(
          (geo[0] is num) ? geo[0].toDouble() : double.parse(geo[0].toString()),
          (geo[1] is num) ? geo[1].toDouble() : double.parse(geo[1].toString()),
        );
      }
    } catch (e) {
      debugPrint('Error parsing geo: $e');
    }
    return null;
  }

  // Manejar el tap en un marcador
  void _onMarkerTapped(String spaceId) {
    if (!mounted) return;
    
    final vm = context.read<ExploreViewModel>();
    final space = vm.spaces.firstWhere(
      (s) => s.id == spaceId,
      orElse: () => null as Space,
    );
    
    if (space != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SpaceDetailScreen(space: space)),
      );
    }
  }

  Future<void> _animateTo(LatLng target, double zoom) async {
    final c = _mapCtrl;
    if (c == null) return;
    await c.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: zoom),
    ));
  }

  // === NUEVO: centrar a mi ubicación, con permisos ===
  Future<void> _goToMyLocation() async {
    if (_requestingLoc) return;
    setState(() => _requestingLoc = true);

    try {
      final servicesOn = await Geolocator.isLocationServiceEnabled();
      if (!servicesOn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activa el GPS para usar tu ubicación.')),
          );
        }
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        await ph.openAppSettings();
        return;
      }
      if (perm == LocationPermission.denied) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _myLatLng = LatLng(pos.latitude, pos.longitude);
      
      // Guardar la ubicación actual
      await LocationService.saveLastLocation(_myLatLng!);
      
      await _animateTo(_myLatLng!, 16);
      await _fetchNearestFor(_myLatLng!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener tu ubicación: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _requestingLoc = false);
    }
  }

  Future<void> _fetchNearestFor(LatLng loc) async {
    if (!mounted) return;
    setState(() { _loadingNearest = true; _nearestError = null; });
    try {
      final vm = context.read<ExploreViewModel>();
      final s = await vm.repo.getNearest(latitude: loc.latitude, longitude: loc.longitude);
      if (!mounted) return;
      setState(() { _nearest = s; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _nearestError = 'No se pudo cargar el más cercano'; });
    } finally {
      if (mounted) setState(() { _loadingNearest = false; });
    }
  }

  Widget _buildNearestCard(BuildContext context) {
    if (_loadingNearest) {
      return Card(
        key: const ValueKey('nearest-loading'),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Buscando el más cercano...'),
            ],
          ),
        ),
      );
    }
    if (_nearestError != null) {
      return const SizedBox.shrink();
    }
    final s = _nearest;
    if (s == null) return const SizedBox.shrink();

    return GestureDetector(
      key: const ValueKey('nearest-card'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => SpaceDetailScreen(space: s)));
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 92,
                  height: 72,
                  child: s.imageUrl.isNotEmpty
                      ? Image.network(s.imageUrl, fit: BoxFit.cover)
                      : Container(color: const Color(0xFFE6E4E8)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if ((s.subtitle ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(s.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('\$${s.price.toStringAsFixed(0)} COP', style: const TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        const Icon(Icons.star, size: 16),
                        const SizedBox(width: 4),
                        Text(s.rating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () { setState(() { _nearest = null; }); },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Guardar la ubicación actual
  Future<void> _saveCurrentLocation(BuildContext context) async {
    if (_myLatLng == null) return;

    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar ubicación'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la ubicación',
              hintText: 'Ej: Casa, Trabajo, Universidad',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa un nombre';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, nameController.text);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && _myLatLng != null) {
      await LocationService.saveLocation(_myLatLng!, name: result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación guardada correctamente')),
        );
      }
    }
  }

  // Mostrar diálogo con ubicaciones guardadas
  Future<void> _showSavedLocations() async {
    final savedLocations = await LocationService.getSavedLocations();
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubicaciones guardadas'),
        content: SizedBox(
          width: double.maxFinite,
          child: savedLocations.isEmpty
              ? const Text('No hay ubicaciones guardadas')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: savedLocations.length,
                  itemBuilder: (context, index) {
                    final loc = savedLocations[index];
                    final latLng = LatLng(
                      (loc['lat'] as num).toDouble(),
                      (loc['lng'] as num).toDouble(),
                    );
                    
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(loc['name'] ?? 'Ubicación ${index + 1}'),
                      subtitle: Text('${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}'),
                      onTap: () {
                        Navigator.pop(context);
                        _animateTo(latLng, 16);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteLocation(context, index),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Eliminar una ubicación guardada
  Future<void> _deleteLocation(BuildContext context, int index) async {
    final savedLocations = await LocationService.getSavedLocations();
    if (index < 0 || index >= savedLocations.length) return;
    
    final loc = savedLocations[index];
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ubicación'),
        content: Text('¿Estás seguro de que quieres eliminar "${loc['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (shouldDelete) {
      savedLocations.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'saved_locations',
        savedLocations.map(LocationService._encodeLocation).toList(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación eliminada')),
        );
        // Actualizar el diálogo
        _showSavedLocations();
      }
    }
  }
}
