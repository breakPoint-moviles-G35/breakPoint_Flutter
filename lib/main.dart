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
import 'data/services/review_api.dart';
import 'data/repositories/review_repository_impl.dart';
import 'domain/repositories/review_repository.dart';



// Presentation layer

import 'presentation/explore/viewmodel/explore_viewmodel.dart';
import 'presentation/host/viewmodel/host_viewmodel.dart';
import 'presentation/details/space_detail_screen.dart';
import 'presentation/filters/date_filter_screen.dart';
import 'presentation/reservations/reservation_screen.dart';
import 'presentation/profile/profile_screen.dart';
import 'presentation/rate/rate_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AuthRepository? authRepoRef; // para exponer el token al interceptor
  
  //  SIMULADOR : 'http://10.0.2.2:3000' 
  // Configuración de red y repos
  final dioClient = DioClient(
    'http://157.253.225.104:3000',
    tokenProvider: () => authRepoRef?.token,
  );
  final api = SpaceApi(dioClient.dio);
  final repo = SpaceRepositoryImpl(api);

  final authApi = AuthApi(dioClient.dio);
  final authRepo = AuthRepositoryImpl(authApi);
  await authRepo.hydrate();
  authRepoRef = authRepo; // conecta el provider de token del interceptor

  final reservationApi = ReservationApi(dioClient.dio);
  final reservationRepo = ReservationRepositoryImpl(reservationApi);

  final hostApi = HostApi(dioClient.dio);
  final hostRepo = HostRepositoryImpl(hostApi);

  final reviewApi = ReviewApi(dioClient.dio);
  final reviewRepo = ReviewRepositoryImpl(reviewApi);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExploreViewModel(repo)..load()..loadRecommendations(), // ViewModel listo
        ),
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => HostViewModel(hostRepo)),
        Provider<ReservationRepository>(create: (_) => reservationRepo),
        Provider<HostRepository>(create: (_) => hostRepo),
        Provider<ReviewRepository>(create: (_) => reviewRepo),
      ],
      child: MyApp(authRepo: authRepo),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepo;
  
  const MyApp({required this.authRepo, super.key});

  /// Construye la pantalla inicial basada en la estrategia de conectividad eventual
  Widget _buildInitialScreen() {
    return FutureBuilder<bool>(
      future: authRepo.canAutoLogin(),
      builder: (context, snapshot) {
        // Mientras se verifica, muestra un loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Solo permite auto-login si hay usuario Y NO hay internet (conectividad eventual)
        if (snapshot.hasData && snapshot.data == true) {
          return const ExploreScreen();
        }
        
        // En cualquier otro caso, va a login para pedir credenciales
        return const LoginScreen();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BreakPoint App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: _buildInitialScreen(),
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
