import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

// NUEVO: ubicación/permisos
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../explore/viewmodel/explore_viewmodel.dart';
import '../details/space_detail_screen.dart';
import '../../domain/entities/space.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapCtrl;
  MapType _mapType = MapType.normal;

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
    _prefetchMyLocation(); // opcional: intenta precargar al abrir
    
    // Cargar espacios para mostrar en el mapa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreViewModel>().load();
    });
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
  Widget build(BuildContext context) {
    final vm = context.watch<ExploreViewModel>();
    final markers = _buildMarkers(vm); // ← mantiene pines del backend

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
            markers: markers,
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

          // Indicador de carga de espacios
          if (vm.isLoading)
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
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    const Text('Cargando espacios...'),
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

          // FABs: Mi ubicación + Campus + Lista
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // NUEVO: Ir a mi ubicación
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
                const SizedBox(height: 12),

                // Botón existente: centrar en campus
                FloatingActionButton.small(
                  heroTag: 'fab-campus',
                  tooltip: 'Centrar en campus',
                  onPressed: () => _animateTo(_campusCenter, _defaultZoom),
                  child: const Icon(Icons.center_focus_strong),
                ),
                const SizedBox(height: 12),

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

  // Mantiene marcadores del backend (vm.spaces)
  Set<Marker> _buildMarkers(ExploreViewModel vm) {
    final set = <Marker>{};

    for (final s in vm.spaces) {
      final loc = _parseLatLng(s.geo);
      if (loc != null) {
        // Solo agregar espacios con coordenadas válidas
        set.add(_markerForSpace(s.id, s.title, s.subtitle ?? '', s.price, loc, s));
      } else {
        // Debug: espacios sin coordenadas válidas
        debugPrint('Espacio sin coordenadas válidas: ${s.id} - ${s.title}, geo: ${s.geo}');
      }
    }
    
    debugPrint('Total espacios: ${vm.spaces.length}, marcadores en mapa: ${set.length}');
    return set;
  }

  Marker _markerForSpace(
    String id,
    String title,
    String subtitle,
    double price,
    LatLng position,
    dynamic spaceObj,
  ) {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: subtitle.isNotEmpty ? subtitle : '\$${price.toStringAsFixed(0)} COP',
        onTap: () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SpaceDetailScreen(space: spaceObj)),
          );
        },
      ),
      onTap: () => _animateTo(position, 17.0),
    );
  }

  LatLng? _parseLatLng(dynamic geo) {
    try {
      if (geo == null) return null;
      
      if (geo is String) {
        // Formato "lat,long" del backend
        final parts = geo.split(',');
        if (parts.length == 2) {
          final lat = double.parse(parts[0].trim());
          final lng = double.parse(parts[1].trim());
          return LatLng(lat, lng);
        }
      } else if (geo is Map) {
        // Formato objeto con propiedades lat/lng
        final lat = geo['lat'] ?? geo['latitude'];
        final lng = geo['lng'] ?? geo['lon'] ?? geo['longitude'];
        if (lat != null && lng != null) {
          return LatLng((lat as num).toDouble(), (lng as num).toDouble());
        }
      } else if (geo is List && geo.length >= 2) {
        // Formato array [lat, lng]
        return LatLng((geo[0] as num).toDouble(), (geo[1] as num).toDouble());
      }
    } catch (e) {
      debugPrint('Error parsing geo: $geo, error: $e');
    }
    return null;
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
}
