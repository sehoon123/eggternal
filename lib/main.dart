import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/screens/ar_test.dart';
import 'package:eggciting/screens/payment_screen.dart';
import 'package:eggciting/screens/post_success_screen.dart';
import 'package:eggciting/services/location_provider.dart';
import 'package:eggciting/services/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:eggciting/screens/add_screen.dart';
import 'package:eggciting/screens/agreement_screen.dart';
import 'package:eggciting/screens/home_screen.dart';
import 'package:eggciting/screens/list_screen.dart';
import 'package:eggciting/screens/login_screen.dart';
import 'package:eggciting/screens/map_selection_screen.dart';
import 'package:eggciting/screens/nickname_screen.dart';
import 'package:eggciting/screens/splash_screen.dart';
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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => PostsProvider(), // Create instance of PostsProvider
        ),
        ChangeNotifierProvider(
          create: (context) => LocationProvider(), // Create instance of LocationProvider
        ),
      ],
      child: MyApp(firestore: firestore),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.firestore});
  final FirebaseFirestore firestore;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Provider.of<LocationProvider>(context, listen: false)
        .startTrackingLocation();
  }

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
      initialRoute: '/login',
      routes: {
        // '/': (context) => const SplashScreen(),
        '/login': (context) => LoginPage(firestore: widget.firestore),
        '/home': (context) => HomeScreen(firestore: widget.firestore),
        '/agreement': (context) => AgreementScreen(firestore: widget.firestore),
        '/nickname': (context) => NicknameScreen(firestore: widget.firestore),
        '/add': (context) => AddScreen(firestore: widget.firestore),
        '/mapSelection': (context) => const MapSelectionScreen(),
        '/list': (context) => const ListScreen(),
        '/postSuccess': (context) => const PostSuccessScreen(
              imageAssetPaths: ['assets/images/logo.png'],
            ),
        '/payment': (context) => PaymentScreen(),
      },
    );
  }
}
