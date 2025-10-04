import 'package:flutter/material.dart';
import 'host_detail_screen.dart'; // ⬅️ nuevo import

/// Datos del host para la UI (mock por ahora).
/// TODO: reemplazar por tu modelo real cuando conectes al back.
class HostProfileView {
  final String name;
  final bool isSuperhost;
  final int reviewsCount;
  final double ratingAvg;
  final int monthsHosting;
  final String born;      // ej. "Born in the 70s"
  final String location;  // ej. "Bogota, Colombia"
  final String work;      // ej. "Business owner"

  HostProfileView({
    required this.name,
    required this.isSuperhost,
    required this.reviewsCount,
    required this.ratingAvg,
    required this.monthsHosting,
    required this.born,
    required this.location,
    required this.work,
  });
}

/// Lanza el bottom-sheet (ventana emergente).
/// Abre a ~50% de alto y se puede arrastrar hasta ~90% si hace falta.
Future<void> showContactHostSheet(
  BuildContext context, {
  required HostProfileView host,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ContactHostSheet(host: host),
  );
}

class _ContactHostSheet extends StatelessWidget {
  final HostProfileView host;
  const _ContactHostSheet({required this.host});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            // Header simple + cerrar
            Row(
              children: [
                const Spacer(),
                const Text(
                  'Contact host',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ⬇️ Card principal (tappable)
            _HostCard(host: host),

            const SizedBox(height: 16),

            // Contenido desplazable (bullets)
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _BulletRow(icon: Icons.cake_outlined, text: host.born),
                  const SizedBox(height: 10),
                  _BulletRow(
                    icon: Icons.location_on_outlined,
                    text: 'Lives in ${host.location}',
                  ),
                  const SizedBox(height: 10),
                  _BulletRow(
                    icon: Icons.work_outline,
                    text: 'My work: ${host.work}',
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Respetar safe area inferior sin ningún botón
            SizedBox(height: media.padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  final HostProfileView host;
  const _HostCard({required this.host});

  @override
  Widget build(BuildContext context) {
    // InkWell para que sea "tappable"
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // Cierra el sheet y abre la pantalla de detalle del host
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HostDetailScreen(host: host),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            const CircleAvatar(
              radius: 36,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 36, color: Colors.white),
            ),
            const SizedBox(width: 14),

            // Nombre + superhost + KPIs
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(host.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(
                    host.isSuperhost ? 'Superhost' : 'Host',
                    style: TextStyle(
                      fontSize: 13,
                      color: host.isSuperhost
                          ? Colors.deepPurple
                          : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Kpi(value: '${host.reviewsCount}', label: 'Reviews'),
                      _DividerVert(),
                      _Kpi(
                        value: host.ratingAvg.toStringAsFixed(2),
                        label: 'Rating',
                        icon: Icons.star,
                      ),
                      _DividerVert(),
                      _Kpi(
                        value: '${host.monthsHosting}',
                        label: 'Months hosting',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _DividerVert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: Colors.grey[300]);
  }
}

class _Kpi extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  const _Kpi({required this.value, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BulletRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black87),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14.5),
          ),
        ),
      ],
    );
  }
}
