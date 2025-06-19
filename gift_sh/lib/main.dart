// main.dart (GiftShopPage 테스트를 위한 임시 메인 파일)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences를 main에서 미리 초기화할 수도 있음
import 'package:gift_shop/gift_shop_page.dart'; // gift_shop_page.dart 파일 경로에 맞게 수정하세요.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 앱 시작 시 SharedPreferences를 통해 더미 포인트 설정 (테스트용)
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getInt('total_points') == null) {
    await prefs.setInt('total_points', 100000); // 초기 100,000 포인트 설정
  }
  // 초기 설정 페이지에서 저장했던 사용자 이름 가져오기 (Google ID 대체용)
  if (prefs.getString('user_name') == null) {
    await prefs.setString('user_name', 'TestUser'); // 더미 사용자 이름 설정
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '워렌봇핏 기프트 샵',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const GiftShopPage(), // GiftShopPage를 홈 화면으로 설정
    );
  }
}