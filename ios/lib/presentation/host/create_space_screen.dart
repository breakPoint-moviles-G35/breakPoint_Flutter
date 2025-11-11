import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../host/viewmodel/host_viewmodel.dart';

class CreateSpaceScreen extends StatefulWidget {
  const CreateSpaceScreen({super.key});

  @override
  State<CreateSpaceScreen> createState() => _CreateSpaceScreenState();
}

class _CreateSpaceScreenState extends State<CreateSpaceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _geoCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  final _amenitiesCtrl = TextEditingController();
  final _accessibilityCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    _geoCtrl.dispose();
    _rulesCtrl.dispose();
    _amenitiesCtrl.dispose();
    _accessibilityCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<HostViewModel>();

    final data = {
      "title": _titleCtrl.text.trim(),
      "subtitle": _subtitleCtrl.text.trim(),
      "geo": _geoCtrl.text.trim(),
      "capacity": int.tryParse(_capacityCtrl.text) ?? 0,
      "amenities": _amenitiesCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      "accessibility": _accessibilityCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      "imageUrl": _imageUrlCtrl.text.trim(),
      "rules": _rulesCtrl.text.trim(),
      "price": double.tryParse(_priceCtrl.text) ?? 0,
    };

    final success = await vm.createSpace(data);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Espacio creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.error ?? 'Error al crear el espacio'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  InputDecoration _inputStyle(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54, width: 1),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HostViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: AppBar(
        title: const Text(
          'Crear nuevo espacio',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: _inputStyle('Título'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _subtitleCtrl,
                      decoration: _inputStyle('Subtítulo (opcional)'),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputStyle('Precio por hora', hint: 'Ej: 25000'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputStyle('Capacidad máxima', hint: 'Ej: 4'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _geoCtrl,
                      decoration: _inputStyle('Coordenadas (lat, lng)', hint: 'Ej: 4.6097, -74.0817'),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _amenitiesCtrl,
                      decoration: _inputStyle(
                        'Amenidades (separadas por coma)',
                        hint: 'WiFi, Cafetera, TV',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _accessibilityCtrl,
                      decoration: _inputStyle(
                        'Accesibilidad (separadas por coma)',
                        hint: 'Ascensor, Rampa',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _rulesCtrl,
                      decoration: _inputStyle('Reglas del lugar', hint: 'No fumar, No mascotas'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _imageUrlCtrl,
                      decoration: _inputStyle('URL de imagen'),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: vm.isLoading ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C1B6C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: vm.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : const Text(
                                'Crear espacio',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
