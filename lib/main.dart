import 'package:breakpoint/data/repositories/auth_repository_impl.dart';
import 'package:breakpoint/data/services/auth_api.dart';
import 'package:breakpoint/domain/entities/space.dart';
import 'package:breakpoint/domain/repositories/auth_repository.dart';
import 'package:breakpoint/domain/repositories/reservation_repository.dart';
import 'package:breakpoint/domain/repositories/host_repository.dart';
import 'package:breakpoint/domain/repositories/review_repository.dart';
import 'package:breakpoint/domain/repositories/space_repository.dart';
import 'package:breakpoint/presentation/explore/explore_screen';
import 'package:breakpoint/presentation/login/login_screen';
import 'package:breakpoint/presentation/login/viewmodel/auth_viewmodel.dart';
import 'package:breakpoint/presentation/map/map_screen.dart';
import 'package:breakpoint/presentation/reservations/reservations_screen';
import 'package:breakpoint/presentation/reservations/viewmodel/reservations_viewmodel.dart';
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

// Presentation layer
import 'presentation/explore/viewmodel/explore_viewmodel.dart';
import 'presentation/host/viewmodel/host_viewmodel.dart';
import 'presentation/details/space_detail_screen.dart';
import 'presentation/filters/date_filter_screen.dart';
import 'presentation/reservations/reservation_screen.dart';
import 'presentation/profile/profile_screen.dart';
import 'presentation/rate/rate_screen.dart';

// 🔹 NUEVAS PANTALLAS DE HOST
import 'presentation/host/host_spaces_screen.dart';
import 'presentation/host/create_space_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthRepository? authRepoRef; // para exponer el token al interceptor

  // Configuración de red y repositorios
  final dioClient = DioClient(
    'http://10.0.2.2:3000', 
    tokenProvider: () => authRepoRef?.token,
  );

  // Inicialización de APIs y repositorios
  final spaceApi = SpaceApi(dioClient.dio);
  final spaceRepo = SpaceRepositoryImpl(spaceApi);

  final authApi = AuthApi(dioClient.dio);
  final authRepo = AuthRepositoryImpl(authApi);
  await authRepo.hydrate();
  authRepoRef = authRepo;

  final reservationApi = ReservationApi(dioClient.dio);
  final reservationRepo = ReservationRepositoryImpl(reservationApi);

  final hostApi = HostApi(dioClient.dio);
  final hostRepo = HostRepositoryImpl(hostApi);

  final reviewApi = ReviewApi(dioClient.dio);
  final reviewRepo = ReviewRepositoryImpl(reviewApi);

  runApp(
    MultiProvider(
      providers: [
        // ExploreViewModel
        ChangeNotifierProvider(
          create: (_) => ExploreViewModel(spaceRepo)
            ..load()
            ..loadRecommendations(),
        ),

        // Auth y Host
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo)),

        // 🔹 HostViewModel ahora recibe dos repos: host y space
        ChangeNotifierProvider(
          create: (_) => HostViewModel(hostRepo, spaceRepo),
        ),

        // Repositorios base
        Provider<ReservationRepository>(create: (_) => reservationRepo),
        Provider<HostRepository>(create: (_) => hostRepo),
        Provider<ReviewRepository>(create: (_) => reviewRepo),
        Provider<SpaceRepository>(create: (_) => spaceRepo),

        // ReservationsViewModel
        ChangeNotifierProvider(
          create: (context) => ReservationsViewModel(
            context.read<ReservationRepository>(),
          ),
        ),
      ],
      child: MyApp(authRepo: authRepo),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepo;

  const MyApp({required this.authRepo, super.key});


  Widget _buildInitialScreen() {
    return FutureBuilder<bool>(
      future: authRepo.canAutoLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const ExploreScreen();
        }

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
        // General
        AppRouter.login: (context) => const LoginScreen(),
        AppRouter.explore: (context) => const ExploreScreen(),
        AppRouter.filters: (context) => const DateFilterScreen(),
        AppRouter.reservations: (context) => const ReservationsScreen(),
        AppRouter.rate: (context) => const RateScreen(),
        AppRouter.profile: (context) => const ProfileScreen(),
        AppRouter.map: (_) => const MapScreen(),

        // Espacios
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

        // Host / Arrendador
        AppRouter.hostSpaces: (context) => const HostSpacesScreen(),
        AppRouter.createSpace: (context) => const CreateSpaceScreen(),
      },
    );
  }
}
