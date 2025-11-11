import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;
  final String message;
  final EdgeInsetsGeometry margin;

  const OfflineBanner({
    super.key,
    this.onRetry,
    this.message = 'Desconectado',
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
  