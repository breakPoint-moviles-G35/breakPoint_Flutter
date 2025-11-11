import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:breakpoint/presentation/login/viewmodel/auth_viewmodel.dart';
import 'package:breakpoint/routes/app_router.dart';
import 'package:breakpoint/domain/entities/user.dart';

class ProfileHostScreen extends StatelessWidget {
  const ProfileHostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final User? user = auth.repo.currentUser;
    final String email = user?.email ?? 'user@uniandes.edu.co';
    final String role = user?.role ?? 'Host';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        title: const Text('Perfil (Host)'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mi perfil (Host)',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(email, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 6),
              Text(role, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDE7F6),
                    foregroundColor: Colors.black87,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await auth.repo.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.login,
                        (_) => false,
                      );
                    }
                  },
                  child: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


