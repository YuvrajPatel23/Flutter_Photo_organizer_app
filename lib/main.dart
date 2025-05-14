import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'theme.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Photo Organizer',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          home: const GalleryHomePage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
