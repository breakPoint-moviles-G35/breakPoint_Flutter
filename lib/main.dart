import 'package:flutter/material.dart';
import 'routes/app_router';
import 'presentation/login/login_screen';
import 'presentation/explore/explore_screen';
import 'presentation/details/space_detail_screen.dart';
import 'presentation/filters/date_filter_screen.dart'; 
import 'presentation/reservations/reservations_screen';
void main() {
  runApp(const MyApp());
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
        AppRouter.reservations:  (context) => const ReservationsScreen(),
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
