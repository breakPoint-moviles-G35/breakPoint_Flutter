import 'package:breakpoint/data/repositories/auth_repository_impl.dart';
import 'package:breakpoint/data/services/auth_api.dart';
import 'package:breakpoint/domain/entities/space.dart';
import 'package:breakpoint/domain/repositories/auth_repository.dart';
import 'package:breakpoint/domain/repositories/reservation_repository.dart';
import 'package:breakpoint/domain/repositories/host_repository.dart';
import 'package:breakpoint/presentation/explore/explore_screen';
import 'package:breakpoint/presentation/login/login_screen';

import 'package:breakpoint/presentation/login/viewmodel/auth_viewmodel.dart';
import 'package:breakpoint/presentation/map/map_screen.dart';
import 'package:breakpoint/presentation/reservations/reservations_screen';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/routes/app_router.dart';


// Core/Network
import 'core/network/dio_client.dart';

// Data layer
import 'data/services/space_api.dart';
import 'data/repositories/space_repository_impl.dart';
import 'data/services/reservation_api.dart';
import 'data/repositories/reservation_repository_impl.dart';
import 'data/services/host_api.dart';
import 'data/repositories/host_repository_impl.dart';



// Presentation layer

import 'presentation/explore/viewmodel/explore_viewmodel.dart';
import 'presentation/host/viewmodel/host_viewmodel.dart';
import 'presentation/details/space_detail_screen.dart';
import 'presentation/filters/date_filter_screen.dart';
import 'presentation/reservations/reservation_screen.dart';
import 'presentation/profile/profile_screen.dart';
import 'presentation/rate/rate_screen.dart';
import 'presentation/reservations/viewmodel/reservations_store.dart';


void main() {
  
  AuthRepository? authRepoRef; // para exponer el token al interceptor
  

  // Configuración de red y repos
  final dioClient = DioClient(
    'http://10.0.2.2:3000',
    tokenProvider: () => authRepoRef?.token,
  );
  final api = SpaceApi(dioClient.dio);
  final repo = SpaceRepositoryImpl(api);

  final authApi = AuthApi(dioClient.dio);
  final authRepo = AuthRepositoryImpl(authApi);
  authRepoRef = authRepo; // conecta el provider de token del interceptor

  final reservationApi = ReservationApi(dioClient.dio);
  final reservationRepo = ReservationRepositoryImpl(reservationApi);

  final hostApi = HostApi(dioClient.dio);
  final hostRepo = HostRepositoryImpl(hostApi);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExploreViewModel(repo)..load()..loadRecommendations(), // ViewModel listo
        ),
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => HostViewModel(hostRepo)),
        ChangeNotifierProvider(create: (_) => ReservationsStore()),
        Provider<ReservationRepository>(create: (_) => reservationRepo),
        Provider<HostRepository>(create: (_) => hostRepo),
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
        AppRouter.login: (context) =>  const LoginScreen(),
        AppRouter.explore: (context) => const ExploreScreen(),
        AppRouter.filters: (context) => const DateFilterScreen(),
        AppRouter.reservations: (context) => const ReservationsScreen(),
        AppRouter.rate: (context) => const RateScreen(),
        AppRouter.profile: (context) => const ProfileScreen(),
        AppRouter.map: (_) => const MapScreen(),
        AppRouter.spaceDetail: (context) => SpaceDetailScreen(
          space: Space(
            id: "demo-id",
            title: "Sample Space",
            subtitle: "A nice place to stay",
            price: 12000.0,
            rating: 4.5,
            capacity: 2,
            rules: "No fumar",
            amenities: ["WiFi", "TV"],
            imageUrl: "", 
  ),
        ),
        AppRouter.reservation: (context) => ReservationScreen(
          spaceTitle: 'Sample Space',
          spaceAddress: '123 Business District, Suite 456, City Center',
          spaceRating: 4.8,
          reviewCount: 127,
          pricePerHour: 25.0,
          spaceId: 'demo-space-id',
        ),
      },
    );
  }
}
