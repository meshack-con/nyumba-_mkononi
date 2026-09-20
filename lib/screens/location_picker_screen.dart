import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

class PickedLocation {
  const PickedLocation({required this.point, required this.label});
  final LatLng point;
  final String label;
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});
  final PickedLocation? initial;
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _point;
  final _label = TextEditingController();

  @override
  void initState() {
    super.initState();
    _point = widget.initial?.point ?? const LatLng(-6.7924, 39.2083);
    _label.text = widget.initial?.label ?? 'Dar es Salaam';
  }

  @override
  void dispose() { _label.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Weka eneo', style: TextStyle(fontWeight: FontWeight.w800)), actions: [TextButton(onPressed: () { if (_label.text.trim().isNotEmpty) Navigator.pop(context, PickedLocation(point: _point, label: _label.text.trim())); }, child: const Text('Hifadhi'))]),
        body: Stack(children: [
          FlutterMap(
            options: MapOptions(initialCenter: _point, initialZoom: 12, onTap: (_, point) => setState(() => _point = point)),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'tz.nyumbamkononi.app'),
              MarkerLayer(markers: [Marker(point: _point, width: 54, height: 54, child: Icon(Icons.location_on, color: AppTheme.coral, size: 48))]),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _label,
                      decoration: const InputDecoration(
                        labelText: 'Jina la eneo',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gusa ramani kuchagua eneo la nyumba.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      );
}
