import 'package:breakpoint/data/repositories/auth_repository_impl.dart';
import 'package:breakpoint/data/repositories/host_repository_impl.dart';
import 'package:breakpoint/data/repositories/reservation_repository_impl.dart';
import 'package:breakpoint/data/repositories/review_repository_impl.dart';
import 'package:breakpoint/data/repositories/space_repository_impl.dart';
import 'package:breakpoint/data/services/auth_api.dart';
import 'package:breakpoint/data/services/host_api.dart';
import 'package:breakpoint/data/services/nfc_service.dart';
import 'package:breakpoint/data/services/reservation_api.dart';
import 'package:breakpoint/data/services/review_api.dart';
import 'package:breakpoint/data/services/space_api.dart';
import 'package:breakpoint/domain/entities/space.dart';
import 'package:breakpoint/domain/repositories/auth_repository.dart';
import 'package:breakpoint/domain/repositories/host_repository.dart';
import 'package:breakpoint/domain/repositories/reservation_repository.dart';
import 'package:breakpoint/domain/repositories/review_repository.dart';
import 'package:breakpoint/domain/repositories/space_repository.dart';
import 'package:breakpoint/presentation/details/space_detail_screen.dart';
import 'package:breakpoint/presentation/explore/explore_screen.dart';
import 'package:breakpoint/presentation/explore/viewmodel/explore_viewmodel.dart';
import 'package:breakpoint/presentation/faq/faq_list_screen.dart';
import 'package:breakpoint/presentation/faq/faq_thread_screen.dart';
import 'package:breakpoint/presentation/filters/date_filter_screen.dart';
import 'package:breakpoint/presentation/host/create_space_screen.dart';
import 'package:breakpoint/presentation/host/host_spaces_screen.dart';
import 'package:breakpoint/presentation/host/viewmodel/host_viewmodel.dart';
import 'package:breakpoint/presentation/login/login_screen.dart';
import 'package:breakpoint/presentation/login/viewmodel/auth_viewmodel.dart';
import 'package:breakpoint/presentation/map/map_screen.dart';
import 'package:breakpoint/presentation/profile/profile_screen.dart';
import 'package:breakpoint/presentation/profile/change_password_screen.dart';
import 'package:breakpoint/presentation/rate/rate_screen.dart';
import 'package:breakpoint/presentation/rate/viewmodel/rate_viewmodel.dart';
import 'package:breakpoint/presentation/history/history_screen.dart';
import 'package:breakpoint/presentation/history/viewmodel/history_viewmodel.dart';
import 'package:breakpoint/presentation/reservations/reservation_screen.dart';
import 'package:breakpoint/presentation/reservations/reservations_screen.dart';
import 'package:breakpoint/presentation/reservations/viewmodel/reservations_viewmodel.dart';
import 'package:breakpoint/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:breakpoint/presentation/faq/viewmodel/faq_viewmodel.dart';
import 'package:breakpoint/data/services/faq_api.dart';
import 'package:breakpoint/data/repositories/faq_repository_impl.dart';
import 'package:breakpoint/domain/repositories/faq_repository.dart';


import 'core/constants/api_constants.dart';
import 'core/network/dio_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthRepository? authRepoRef;

  final dioClient = DioClient(
    ApiConstants.baseUrl,
    tokenProvider: () => authRepoRef?.token,
  );

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

  final faqApi = FaqApi(dioClient.dio);
  final faqRepo = FaqRepositoryImpl(faqApi);

  final nfcService = NfcService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExploreViewModel(spaceRepo)
            ..load()
            ..loadRecommendations(),
        ),
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo)),
        ChangeNotifierProvider(
          create: (_) => HostViewModel(hostRepo, spaceRepo),
        ),
        Provider<ReservationRepository>(create: (_) => reservationRepo),
        Provider<HostRepository>(create: (_) => hostRepo),
        Provider<ReviewRepository>(create: (_) => reviewRepo),
        Provider<SpaceRepository>(create: (_) => spaceRepo),
        Provider<AuthRepository>(create: (_) => authRepo),
        Provider<NfcService>(create: (_) => nfcService),
        Provider<FaqRepository>(create: (_) => faqRepo),
        ChangeNotifierProvider(
          create: (context) => ReservationsViewModel(
            context.read<ReservationRepository>(),
            context.read<NfcService>(),
          ),
        ),
        // 🔹 ViewModels con gestión de almacenamiento local
        ChangeNotifierProvider(
          create: (context) => RateViewModel(
            reservationRepo: context.read<ReservationRepository>(),
            reviewRepo: context.read<ReviewRepository>(),
            authRepo: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HistoryViewModel(
            reservationRepo: context.read<ReservationRepository>(),
            reviewRepo: context.read<ReviewRepository>(),
            authRepo: context.read<AuthRepository>(),
          ),
        ),

        ChangeNotifierProvider(
  create: (context) => FaqViewModel(
    faqRepository: context.read<FaqRepository>(),
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
        AppRouter.login: (context) => const LoginScreen(),
        AppRouter.explore: (context) => const ExploreScreen(),
        AppRouter.filters: (context) => const DateFilterScreen(),
        AppRouter.reservations: (context) => const ReservationsScreen(),
        AppRouter.rate: (context) => const RateScreen(),
        AppRouter.profile: (context) => const ProfileScreen(),
        AppRouter.history: (context) => const HistoryScreen(),
        AppRouter.map: (_) => const MapScreen(),
        AppRouter.faq: (_) => const FaqListScreen(),
        AppRouter.faqThread: (context) {
  final id = ModalRoute.of(context)!.settings.arguments as String;
  return FaqThreadScreen(id: id);
},
        AppRouter.changePassword: (context) => const ChangePasswordScreen(),
        AppRouter.spaceDetail: (context) => SpaceDetailScreen(
              space: Space(
                id: 'demo-id',
                title: 'Sample Space',
                subtitle: 'A nice place to stay',
                price: 12000.0,
                rating: 4.5,
                capacity: 2,
                rules: 'No fumar',
                amenities: ['WiFi', 'TV'],
                imageUrl: '',
              ),
            ),
        AppRouter.reservation: (context) => ReservationScreen(
              spaceTitle: 'Sample Space',
              spaceAddress:
                  '123 Business District, Suite 456, City Center',
              spaceRating: 4.8,
              reviewCount: 127,
              pricePerHour: 25.0,
              spaceId: 'demo-space-id',
            ),
        AppRouter.hostSpaces: (context) => const HostSpacesScreen(),
        AppRouter.createSpace: (context) => const CreateSpaceScreen(),
      },
    );
  }
}
