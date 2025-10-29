import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/domain/repositories/space_repository.dart';
import 'package:breakpoint/domain/repositories/host_repository.dart';
import 'package:breakpoint/routes/app_router.dart';
import 'package:breakpoint/presentation/explore/viewmodel/explore_viewmodel.dart';
import 'viewmodel/create_space_viewmodel.dart';

class CreateSpaceScreen extends StatefulWidget {
  const CreateSpaceScreen({super.key});

  @override
  State<CreateSpaceScreen> createState() => _CreateSpaceScreenState();
}

class _CreateSpaceScreenState extends State<CreateSpaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController(); // geo
  final _priceCtrl = TextEditingController();
  final _amenitiesCtrl = TextEditingController(); // coma-separado
  final _rulesCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '1');

  bool _isSubmitting = false;
  String? _error;
  String? _hostProfileId;

  @override
  void initState() {
    super.initState();
    _loadHostProfileId();
  }

  Future<void> _loadHostProfileId() async {
    try {
      final hostRepo = context.read<HostRepository>();
      final me = await hostRepo.getMyHostProfile();
      setState(() => _hostProfileId = me.id);
    } catch (_) {
      // Si falla, requeriremos input manual o bloquear envío
      setState(() => _hostProfileId = null);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _amenitiesCtrl.dispose();
    _rulesCtrl.dispose();
    _imageUrlCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateSpaceViewModel(
        context.read<SpaceRepository>(),
        context.read<HostRepository>(),
      ),
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create a room'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload placeholder
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3E5F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.upload, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      const Text('Upload images of the room'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _field('Title of the publication', _titleCtrl, 'Title',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null),
                _field('Address', _addressCtrl, 'address'),
                _field('Cost per hour', _priceCtrl, 'Cost per hour',
                    keyboard: TextInputType.number),
                _field('Subtitle', _subtitleCtrl, 'Subtitle (optional)'),
                _field('Image URL', _imageUrlCtrl, 'http(s)://...',
                    keyboard: TextInputType.url),
                _field('Amenities (comma separated)', _amenitiesCtrl,
                    'WiFi, TV, ...'),
                _field('Rules', _rulesCtrl, 'Rules',
                    maxLines: 3, validator: (v) => (v == null || v.isEmpty)
                        ? 'Required'
                        : null),
                _field('Capacity', _capacityCtrl, '1',
                    keyboard: TextInputType.number),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create room'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _field(String label, TextEditingController c, String hint,
      {int maxLines = 1, TextInputType? keyboard, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: c,
            maxLines: maxLines,
            keyboardType: keyboard,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black54, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hostProfileId == null || _hostProfileId!.isEmpty) {
      setState(() => _error = 'No se pudo obtener tu HostProfile. Asegúrate de estar autenticado como Host.');
      return;
    }
    try {
      setState(() {
        _isSubmitting = true;
        _error = null;
      });
      final vm = context.read<CreateSpaceViewModel>();
      final amenities = _amenitiesCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
      final capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 1;

      final ok = await vm.submit(
        title: _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim().isEmpty ? null : _subtitleCtrl.text.trim(),
        geo: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        capacity: capacity,
        amenities: amenities.isEmpty ? ['WiFi'] : amenities,
        accessibility: null,
        imageUrl: _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
        rules: _rulesCtrl.text.trim(),
        price: price,
      );
      if (!ok) {
        throw Exception(vm.error ?? 'Error al crear el espacio');
      }

      // Refrescar Explore para que aparezca el nuevo espacio
      if (mounted) {
        context.read<ExploreViewModel>().load();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Space created successfully')),
      );
      Navigator.popUntil(context, ModalRoute.withName(AppRouter.explore));
    } catch (e) {
      setState(() => _error = 'Error al crear el espacio: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}


