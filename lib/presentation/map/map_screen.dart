import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../explore/viewmodel/explore_viewmodel.dart';
import '../details/space_detail_screen.dart';
//import '../../routes/app_router.dart'; // por si quieres navegar por nombre

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapCtrl;
  MapType _mapType = MapType.normal;

  // Centro por defecto (ej. campus); cambia a tus coords reales
  static const _campusCenter = LatLng(4.60971, -74.08175); // Bogotá centro
  static const _defaultZoom = 15.0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExploreViewModel>();
    final markers = _buildMarkers(vm);

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
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _mapCtrl = c,
            markers: markers,
          ),

          // Chip para rango (si lo tienes activo en ExploreViewModel)
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

          // Botones de UI
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Fab(
                  icon: Icons.center_focus_strong,
                  tooltip: 'Centrar en campus',
                  onPressed: () => _animateTo(_campusCenter, _defaultZoom),
                ),
                const SizedBox(height: 12),
                _Fab(
                  icon: Icons.list_alt,
                  tooltip: 'Ver lista',
                  onPressed: () => Navigator.pop(context), // vuelve a Explore
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Crea marcadores a partir de los espacios del VM
  Set<Marker> _buildMarkers(ExploreViewModel vm) {
    final rnd = Random(42);
    final set = <Marker>{};

    for (final s in vm.spaces) {
      final loc = _parseLatLng(s.geo);
      if (loc == null) {
        // Si no hay geo, crea un jitter alrededor del campus para demo
        final dx = (rnd.nextDouble() - 0.5) / 500; // ~ leve desplazamiento
        final dy = (rnd.nextDouble() - 0.5) / 500;
        final jitter = LatLng(_campusCenter.latitude + dx, _campusCenter.longitude + dy);
        set.add(_markerForSpace(s.id, s.title, s.subtitle ?? '', s.price, jitter, s));
        continue;
      }
      set.add(_markerForSpace(s.id, s.title, s.subtitle ?? '', s.price, loc, s));
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
          // Abre el detalle
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SpaceDetailScreen(space: spaceObj)),
          );
        },
      ),
      onTap: () {
        // Si quieres mover la cámara al marcador
        _animateTo(position, 17.0);
      },
    );
  }

  // Adapta a tu formato real de 'geo'
  // Soporta:
  // - String "lat,lng" (e.g., "4.6321,-74.0659")
  // - Map {'lat': 4.6, 'lng': -74.08}
  // - List [4.6, -74.08]
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
    } catch (_) {
      // Silencioso; devolvemos null y jitter cerca del campus
    }
    return null;
  }

  Future<void> _animateTo(LatLng target, double zoom) async {
    final c = _mapCtrl;
    if (c == null) return;
    await c.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _Fab({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: tooltip,
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}
