import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggternal/services/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:eggternal/screens/add_screen.dart';
import 'package:eggternal/screens/agreement_screen.dart';
import 'package:eggternal/screens/home_screen.dart';
import 'package:eggternal/screens/list_screen.dart';
import 'package:eggternal/screens/login_screen.dart';
import 'package:eggternal/screens/map_selection_screen.dart';
import 'package:eggternal/screens/nickname_screen.dart';
import 'package:eggternal/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  await LineSDK.instance.setup(dotenv.env['lineChannelId']!).then((_) {
    debugPrint('LineSDK Prepared');
  });

  String apiKey = dotenv.env['kakaoNativeAppKey']!;
  debugPrint('API Key: $apiKey');

  KakaoSdk.init(
    nativeAppKey: dotenv.env['kakaoNativeAppKey']!,
    javaScriptAppKey: dotenv.env['kakaoJavaScriptAppKey']!,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => PostsProvider(), // Create instance of PostsProvider
      child: MyApp(firestore: firestore),
    ),
  ); // Pass firestore instance to app
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.firestore});
  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF67280),
        ).copyWith(
          primary: const Color(0xFFF67280),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => LoginPage(firestore: firestore),
        '/home': (context) => HomeScreen(firestore: firestore),
        '/agreement': (context) => AgreementScreen(firestore: firestore),
        '/nickname': (context) => NicknameScreen(firestore: firestore),
        '/add': (context) => AddScreen(firestore: firestore),
        '/mapSelection': (context) => const MapSelectionScreen(),
        '/list': (context) => const ListScreen(),
      },
    );
  }
}
