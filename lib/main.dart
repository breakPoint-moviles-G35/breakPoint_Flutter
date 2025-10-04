import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:breakpoint/routes/app_router.dart';

// Core/Network
import 'core/network/dio_client.dart';

// Data layer
import 'data/services/space_api.dart';
import 'data/repositories/space_repository_impl.dart';
import 'data/services/auth_api.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/services/host_api.dart';
import 'data/repositories/host_repository_impl.dart';
import 'data/services/review_api.dart';
import 'data/repositories/review_repository_impl.dart';

// Domain
import 'package:breakpoint/domain/entities/space.dart';
import 'package:breakpoint/domain/repositories/auth_repository.dart';
import 'package:breakpoint/domain/repositories/space_repository.dart';
import 'package:breakpoint/domain/repositories/host_repository.dart';
import 'package:breakpoint/domain/repositories/review_repository.dart';

// Presentation
import 'package:breakpoint/presentation/explore/explore_screen';
import 'package:breakpoint/presentation/explore/viewmodel/explore_viewmodel.dart';
import 'package:breakpoint/presentation/login/login_screen';
import 'package:breakpoint/presentation/login/viewmodel/auth_viewmodel.dart';
import 'package:breakpoint/presentation/reservations/reservations_screen';
import 'package:breakpoint/presentation/filters/date_filter_screen.dart';
import 'package:breakpoint/presentation/details/space_detail_screen.dart';
import 'package:breakpoint/presentation/reviews/reviews_screen.dart';

void main() {
  AuthRepository? authRepoRef; // para exponer el token al interceptor

  // Dio con interceptor que pide token al repo de auth
  final dioClient = DioClient(
    'http://10.0.2.2:3000',
    tokenProvider: () => authRepoRef?.token,
  );

  final spaceApi = SpaceApi(dioClient.dio);
  final spaceRepo = SpaceRepositoryImpl(spaceApi);

  final authApi = AuthApi(dioClient.dio);
  final authRepo = AuthRepositoryImpl(authApi);
  authRepoRef = authRepo;

  final hostApi = HostApi(dioClient.dio);
  final hostRepo = HostRepositoryImpl(hostApi);

  final reviewApi = ReviewApi(dioClient.dio);
  final reviewRepo = ReviewRepositoryImpl(reviewApi);

  runApp(
    MultiProvider(
      providers: [
        // Exponer los repositorios directamente para que estén disponibles en toda la app
        Provider<SpaceRepository>(create: (_) => spaceRepo),
        Provider<HostRepository>(create: (_) => hostRepo),
        Provider<ReviewRepository>(create: (_) => reviewRepo),
        ChangeNotifierProvider(create: (_) => ExploreViewModel(spaceRepo)..load()),
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo)),
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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      initialRoute: AppRouter.login,
      routes: {
        AppRouter.login: (context) => const LoginScreen(),
        AppRouter.explore: (context) => const ExploreScreen(),
        AppRouter.filters: (context) => const DateFilterScreen(),
        AppRouter.reservations: (context) => const ReservationsScreen(),
      },
      // Rutas que dependen de argumentos:
      onGenerateRoute: (settings) {
        if (settings.name == AppRouter.spaceDetail) {
          final space = settings.arguments as Space; // <-- requerido
          return MaterialPageRoute(builder: (_) => SpaceDetailScreen(space: space));
        }
        if (settings.name == AppRouter.reviews) {
          final args = settings.arguments as ReviewsArgs? ??
              ReviewsArgs(spaceId: 'SPACE_ID_DEMO');
          return MaterialPageRoute(builder: (_) => ReviewsScreen(args: args));
        }
        return null;
      },
    );
  }
}
