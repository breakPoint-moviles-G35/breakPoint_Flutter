import 'package:breakpoint/presentation/explore/explore_screen';
import 'package:breakpoint/presentation/login/login_screen';
import 'package:breakpoint/presentation/reservations/reservations_screen';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/routes/app_router.dart';


// Core/Network
import 'core/network/dio_client.dart';

// Data layer
import 'data/services/space_api.dart';
import 'data/repositories/space_repository_impl.dart';



// Presentation layer

import 'presentation/explore/viewmodel/explore_viewmodel.dart';
import 'presentation/details/space_detail_screen.dart';
import 'presentation/filters/date_filter_screen.dart';


void main() {
  // Configuración de red y repos
  final dioClient = DioClient("http://10.0.2.2:3000"); // Ip del emulador de android
  final api = SpaceApi(dioClient.dio);
  final repo = SpaceRepositoryImpl(api);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExploreViewModel(repo)..load(), // ViewModel listo
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BreakPoint App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      initialRoute: AppRouter.login,
      routes: {
        AppRouter.login: (context) => const LoginScreen(),
        AppRouter.explore: (context) => const ExploreScreen(),
        AppRouter.filters: (context) => const DateFilterScreen(),
        AppRouter.reservations: (context) => const ReservationsScreen(),
        AppRouter.spaceDetail: (context) => SpaceDetailScreen(
          title: 'Sample Space',
          subtitle: 'A nice place to stay',
          rating: 4.5,
          price: 12000.0,
        ),
      },
    );
  }
}
