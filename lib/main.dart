import 'package:flutter/material.dart';

import 'api_client.dart';
import 'screens.dart';

void main() {
  runApp(const FinBestApp());
}

class FinBestApp extends StatefulWidget {
  const FinBestApp({super.key});

  @override
  State<FinBestApp> createState() => _FinBestAppState();
}

class _FinBestAppState extends State<FinBestApp> {
  late final ApiClient api;
  bool signedIn = false;

  @override
  void initState() {
    super.initState();
    api = ApiClient();
  }

  @override
  void dispose() {
    api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinBest AI',
      theme: finBestTheme,
      home: signedIn
          ? HomeShell(
              api: api,
              onSignedOut: () => setState(() => signedIn = false),
            )
          : LoginScreen(
              api: api,
              onSignedIn: () => setState(() => signedIn = true),
            ),
    );
  }
}

const navy = Color(0xFF00033D);
const indigo = Color(0xFF433EAB);
const canvas = Color(0xFFF8FAFC);
const border = Color(0xFFE2E8F0);
const mutedText = Color(0xFF5B6472);
const warning = Color(0xFFB45309);
const danger = Color(0xFFB91C1C);
const success = Color(0xFF166534);

final finBestTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: indigo,
    onPrimary: Colors.white,
    secondary: navy,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: navy,
    error: danger,
    onError: Colors.white,
    outline: border,
  ),
  scaffoldBackgroundColor: canvas,
  appBarTheme: const AppBarTheme(
    backgroundColor: navy,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
  ),
  cardTheme: const CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      side: BorderSide(color: border),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: border),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    height: 72,
    backgroundColor: Colors.white,
    indicatorColor: Color(0xFFEEEDF8),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
  ),
);

class FinBestLogo extends StatelessWidget {
  const FinBestLogo({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(size * 0.18),
      ),
      child: Text(
        'Z',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.64,
          height: 1,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
