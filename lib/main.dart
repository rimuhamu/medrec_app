import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'routes/app_router.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MedRecApp());
}

class MedRecApp extends StatelessWidget {
  const MedRecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(ApiService()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PatientProvider>(
          create: (_) => PatientProvider(ApiService()),
          update: (_, auth, previous) =>
              previous ?? PatientProvider(ApiService()),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'MedRec',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.interTextTheme(),
              cardTheme: CardThemeData(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              inputDecorationTheme: InputDecorationTheme(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            routerConfig: AppRouter.router(auth),
          );
        },
      ),
    );
  }
}
