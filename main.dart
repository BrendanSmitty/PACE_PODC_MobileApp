import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/themeNotifier.dart'; 
import 'providers/guestNotifier.dart'; 
import 'providers/profileNotifier.dart'; 
import 'pages/loginScreen.dart';
import 'pages/homePage.dart';
import 'pages/articles/articleList.dart';
import 'pages/articles/articleDetails.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'pages/profilePage.dart';
import 'providers/flaggedContentNotifier.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, 
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()), // ThemeNotifier
        ChangeNotifierProvider(create: (_) => GuestNotifier()), // GuestNotifier
        ChangeNotifierProvider(create: (_) => ProfileNotifier()),
        ChangeNotifierProvider(create: (_) => FlaggedContentNotifier()), // Add flagged content provider
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Flutter Firebase Auth',
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blueGrey,
            appBarTheme: AppBarTheme(color: Colors.black),
          ),
          initialRoute: '/login',
          routes: {
            '/login': (context) => LoginScreen(),
            '/home': (context) => HomeScreen(), // No need to pass isGuest manually
            '/articles': (context) => ArticleListScreen(),
            '/profile': (context) => ProfileScreen(),
          },
          onGenerateRoute: (settings) {
          if (settings.name == '/articleDetails') {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (context) {
                return ArticleDetailsScreen(
                  articleId: args['articleId']!,
                  title: args['title']!,
                  description: args['description']!,
                  videoUrl: args['videoUrl']!,
                );
              },
            );
          }
          return null;
        },
        );
      },
    );
  }
}
