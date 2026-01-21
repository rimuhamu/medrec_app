import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/patient_list_screen.dart';
import '../screens/patient_detail_screen.dart';
import '../screens/notifications_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isAuth = authProvider.isAuthenticated;
        final isLogin = state.matchedLocation == '/login';
        final isRegister = state.matchedLocation == '/register';

        if (!isAuth && !isLogin && !isRegister) {
          return '/login';
        }

        if (isAuth && (isLogin || isRegister)) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/patients',
          builder: (context, state) => const PatientListScreen(),
        ),
        GoRoute(
          path: '/patients/add',
          builder: (context, state) => const RegisterScreen(isAdminMode: true),
        ),
        GoRoute(
          path: '/patients/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            final tab = state.uri.queryParameters['tab'];
            return PatientDetailScreen(
              patientId: id,
              initialTabIndex: tab != null ? int.tryParse(tab) : 0,
            );
          },
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    );
  }
}
