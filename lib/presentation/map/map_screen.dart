import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

// NUEVO: ubicación/permisos
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../explore/viewmodel/explore_viewmodel.dart';
import '../details/space_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _prefetchMyLocation(); // opcional: intenta precargar al abrir
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
    final rnd = Random(42);
    final set = <Marker>{};

    for (final s in vm.spaces) {
      final loc = _parseLatLng(s.geo);
      if (loc == null) {
        // Sin geo: jitter cerca del campus (demo)
        final dx = (rnd.nextDouble() - 0.5) / 500;
        final dy = (rnd.nextDouble() - 0.5) / 500;
        final jitter = LatLng(_campusCenter.latitude + dx, _campusCenter.longitude + dy);
        set.add(_markerForSpace(s.id, s.title, s.subtitle ?? '', s.price, jitter, s));
      } else {
        set.add(_markerForSpace(s.id, s.title, s.subtitle ?? '', s.price, loc, s));
      }
    }
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
        final parts = geo.split(',');
        if (parts.length == 2) {
          final lat = double.parse(parts[0].trim());
          final lng = double.parse(parts[1].trim());
          return LatLng(lat, lng);
        }
      } else if (geo is Map) {
        final lat = geo['lat'] ?? geo['latitude'];
        final lng = geo['lng'] ?? geo['lon'] ?? geo['longitude'];
        if (lat != null && lng != null) {
          return LatLng((lat as num).toDouble(), (lng as num).toDouble());
        }
      } else if (geo is List && geo.length >= 2) {
        return LatLng((geo[0] as num).toDouble(), (geo[1] as num).toDouble());
      }
    } catch (_) {}
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
}
