import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../routes/app_router.dart';
import '../../data/services/reservation_api.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../domain/repositories/reservation_repository.dart';
import 'viewmodel/reservation_viewmodel.dart';

class ReservationScreen extends StatelessWidget {
  final String spaceTitle;
  final String spaceAddress;
  final double spaceRating;
  final int reviewCount;
  final double pricePerHour;
  final String spaceId;

  const ReservationScreen({
    super.key,
    required this.spaceTitle,
    required this.spaceAddress,
    required this.spaceRating,
    required this.reviewCount,
    required this.pricePerHour,
    required this.spaceId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'));
        final api = ReservationApi(dio);
        final repo = ReservationRepositoryImpl(api);
        return ReservationViewModel(repo, pricePerHour, spaceId);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Reserve Room',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: const _ReservationContent(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 2,
          onDestinationSelected: (i) {
            if (i == 0) {
              Navigator.pushReplacementNamed(context, AppRouter.explore);
            }
            if (i == 2) {
              Navigator.pushReplacementNamed(context, AppRouter.reservations);
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Rate'),
            NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Reservations'),
          ],
        ),
      ),
    );
  }
}

// ===================== CONTENIDO PRINCIPAL =====================
class _ReservationContent extends StatelessWidget {
  const _ReservationContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SpaceInfoCard(
            address: vm.spaceAddress,
            rating: vm.spaceRating,
            reviewCount: vm.reviewCount,
          ),
          const SizedBox(height: 24),
          _TimeSelectionSection(),
          const SizedBox(height: 24),
          _DurationSection(),
          const SizedBox(height: 24),
          _GuestsSection(),
          const SizedBox(height: 24),
          _PriceSummaryCard(),
          const SizedBox(height: 24),
          if (vm.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                vm.errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          _ReserveButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ===================== INFO DEL ESPACIO =====================
class _SpaceInfoCard extends StatelessWidget {
  final String address;
  final double rating;
  final int reviewCount;

  const _SpaceInfoCard({
    required this.address,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            address,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Text(
                '($reviewCount)',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== SECCIÓN DE HORARIOS =====================
class _TimeSelectionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: vm.availableTimes.length,
            itemBuilder: (context, index) {
              final time = vm.availableTimes[index];
              final isSelected = vm.selectedTime == time;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => vm.selectTime(time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===================== SECCIÓN DE DURACIÓN =====================
class _DurationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _CounterButton(icon: Icons.remove, onPressed: vm.canDecreaseDuration ? vm.decreaseDuration : null),
            const SizedBox(width: 16),
            Text(vm.durationText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(width: 16),
            _CounterButton(icon: Icons.add, onPressed: vm.canIncreaseDuration ? vm.increaseDuration : null),
          ],
        ),
      ],
    );
  }
}

// ===================== SECCIÓN DE INVITADOS =====================
class _GuestsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of Guests',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _CounterButton(icon: Icons.remove, onPressed: vm.canDecreaseGuests ? vm.decreaseGuests : null),
            const SizedBox(width: 16),
            Text(vm.guestsText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(width: 16),
            _CounterButton(icon: Icons.add, onPressed: vm.canIncreaseGuests ? vm.increaseGuests : null),
          ],
        ),
      ],
    );
  }
}

// ===================== BOTONES DE CONTADOR =====================
class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CounterButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: onPressed != null ? Colors.deepPurple : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null ? Colors.white : Colors.grey.shade600,
          size: 20,
        ),
      ),
    );
  }
}

// ===================== RESUMEN DE PRECIOS =====================
class _PriceSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price per hour'),
              Text('\$${vm.pricePerHour.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duration'),
              Text(vm.durationText),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                '\$${vm.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== BOTÓN DE CONFIRMACIÓN =====================
class _ReserveButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: vm.canReserve ? () => _handleReservation(context, vm) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: vm.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Reserve for \$${vm.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _handleReservation(BuildContext context, ReservationViewModel vm) async {
    final reservation = await vm.processReservation();

    if (reservation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reserva realizada exitosamente por \$${vm.totalPrice.toStringAsFixed(0)}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Error al procesar la reserva'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
