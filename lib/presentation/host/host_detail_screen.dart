import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/host.dart';
import '../host/viewmodel/host_viewmodel.dart';

class HostDetailScreen extends StatelessWidget {
  final String? hostId;
  final String? spaceId;

  const HostDetailScreen({
    Key? key,
    this.hostId,
    this.spaceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Host detail',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<HostViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            );
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.error!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.clearError();
                      if (hostId != null) {
                        viewModel.loadHostById(hostId!);
                      } else if (spaceId != null) {
                        viewModel.loadHostBySpaceId(spaceId!);
                      }
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.currentHost == null) {
            return const Center(
              child: Text(
                'No se encontró información del host',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return _buildHostContent(context, viewModel.currentHost!);
        },
      ),
    );
  }

  Widget _buildHostContent(BuildContext context, Host host) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Host Profile Card
            _buildHostProfileCard(host),
            const SizedBox(height: 24),

            // Host Details Section
            _buildHostDetailsSection(host),
            const SizedBox(height: 24),

            // Reviews Section
            _buildReviewsSection(host),
            const SizedBox(height: 24),

            // Confirmed Information Section
            _buildConfirmedInfoSection(host),
          ],
        ),
      ),
    );
  }

  Widget _buildHostProfileCard(Host host) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[300],
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 20),
          
          // Host Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  host.firstName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (host.lastName.isNotEmpty)
                  Text(
                    host.lastName,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Stats
                Row(
                  children: [
                    _buildStatItem('${host.totalReviews}', 'Reviews'),
                    const SizedBox(width: 20),
                    _buildStatItem('${host.averageRating.toStringAsFixed(2)}', '★ Rating'),
                    const SizedBox(width: 20),
                    _buildStatItem('${host.monthsHosting}', 'Months hosting'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildHostDetailsSection(Host host) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(Icons.lightbulb_outline, host.birthInfo),
        const SizedBox(height: 12),
        _buildDetailItem(Icons.location_on_outlined, host.location),
        const SizedBox(height: 12),
        _buildDetailItem(Icons.work_outline, host.workInfo),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(Host host) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${host.firstName}'s reviews",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'No hay reseñas disponibles en este momento.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedInfoSection(Host host) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${host.firstName}'s confirmed information",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...host.confirmedInfo.map((info) => _buildConfirmedItem(info)),
        if (host.confirmedInfo.isEmpty)
          const Text(
            'No hay información confirmada disponible.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildConfirmedItem(String info) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          Text(
            info,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
