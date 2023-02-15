import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lets_gamez/providers/user_provider.dart';
import 'package:lets_gamez/responsive/mobile_screen_layout.dart';
import 'package:lets_gamez/responsive/responsive_layout_screen.dart';
import 'package:lets_gamez/responsive/web_screen_layout.dart';
import 'package:lets_gamez/screens/login_screen.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:provider/provider.dart';

// default mode = normal mode (without auto-reload)
bool autoReload = false;
String mode = 'NORMAL';

bool getAutoReload() {
  return autoReload;
}

void setAutoReload(bool value) {
  autoReload = value;
}

String getMode() {
  return mode;
}

void setMode(String setmode) {
  mode = setmode;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyASTwRSbuFU8gWlL5NGPgIGqn0NS5ccL9c',
        appId: '1:389387051066:web:e4311d11558ea9303ad503',
        messagingSenderId: '389387051066',
        projectId: 'let-s-gamez-343f0',
        storageBucket: 'let-s-gamez-343f0.appspot.com',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Let\'s GameZ',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: mobileBackgroundColor,
        ),
        home: StreamBuilder(
          // to update email or password
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // user is authenticated
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                return ResponsiveLayout(
                  mobileScreenLayout: MobileScreenLayout(
                    autoReload: autoReload,
                  ),
                  webScreenLayout: WebScreenLayout(
                    autoReload: autoReload,
                  ),
                );
              }
            } else if (snapshot.hasError) {
              return Center(
                child: Text('${snapshot.error}'),
              );
            }
            // waiting for connection to user
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
