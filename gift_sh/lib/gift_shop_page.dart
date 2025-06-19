// gift_shop_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // JSON 인코딩/디코딩을 위해 필요

// 기프티콘 모델 정의
class Gifticon {
  final String id;
  final String name;
  final int price; // 포인트 가격
  final String imageUrl; // 기프티콘 이미지 경로 (assets에 추가되어야 함)

  Gifticon({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  // 예시 기프티콘 목록
  static List<Gifticon> get allGifticons => [
    Gifticon(id: 'coffee1', name: '스타벅스 아메리카노 Tall', price: 4500, imageUrl: 'asset/img/starbucks_coffee.png'),
    Gifticon(id: 'chicken1', name: 'BHC 뿌링클 + 콜라', price: 23000, imageUrl: 'asset/img/bhc_chicken.png'),
    Gifticon(id: 'conveni1', name: 'CU 모바일 금액권 5천원', price: 5000, imageUrl: 'asset/img/cu_giftcard.png'),
    Gifticon(id: 'movie1', name: 'CGV 영화 관람권 (1인)', price: 15000, imageUrl: 'asset/img/cgv_ticket.png'),
    Gifticon(id: 'icecream1', name: '베스킨라빈스 파인트', price: 9800, imageUrl: 'asset/img/br_icecream.png'),
  ];
}

// 기프티콘 신청 내역 모델
class GifticonOrder {
  final String gifticonId;
  final String gifticonName;
  final int pricePaid;
  final DateTime orderDate;
  final String userGoogleId; // 소셜 로그인 (구글) 한 사용자 ID

  GifticonOrder({
    required this.gifticonId,
    required this.gifticonName,
    required this.pricePaid,
    required this.orderDate,
    required this.userGoogleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'gifticonId': gifticonId,
      'gifticonName': gifticonName,
      'pricePaid': pricePaid,
      'orderDate': orderDate.toIso8601String(),
      'userGoogleId': userGoogleId,
    };
  }

  factory GifticonOrder.fromJson(Map<String, dynamic> json) {
    return GifticonOrder(
      gifticonId: json['gifticonId'] as String,
      gifticonName: json['gifticonName'] as String,
      pricePaid: json['pricePaid'] as int,
      orderDate: DateTime.parse(json['orderDate'] as String),
      userGoogleId: json['userGoogleId'] as String,
    );
  }
}

class GiftShopPage extends StatefulWidget {
  const GiftShopPage({super.key});

  @override
  State<GiftShopPage> createState() => _GiftShopPageState();
}

class _GiftShopPageState extends State<GiftShopPage> {
  int _currentPoints = 0;
  String _userGoogleId = 'guest@example.com'; // 초기 더미 구글 ID

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 사용자 포인트 및 구글 ID 로드
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPoints = prefs.getInt('total_points') ?? 0;
      // 실제 앱에서는 로그인 시 저장된 구글 ID (또는 이메일)을 가져와야 합니다.
      // 예: prefs.getString('google_user_email')
      _userGoogleId = prefs.getString('user_name') ?? '사용자 (ID 없음)'; // 초기 설정에서 저장된 '이름'을 임시 ID로 사용
    });
  }

  // 사용자 포인트 저장
  Future<void> _savePoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_points', _currentPoints);
  }

  // 기프티콘 신청 내역 저장
  Future<void> _saveOrderHistory(GifticonOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> orderListJson = prefs.getStringList('gifticon_orders') ?? [];
    orderListJson.add(json.encode(order.toJson()));
    await prefs.setStringList('gifticon_orders', orderListJson);
  }

  // 기프티콘 신청 로직
  void _requestGifticon(Gifticon gifticon) {
    if (_currentPoints < gifticon.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('포인트가 부족합니다!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('기프티콘 신청 확인'),
          content: Text('${gifticon.name}을(를) ${gifticon.price}포인트에 신청하시겠습니까?\n'
              '신청 시 관리자가 ${_userGoogleId} (으)로 기프티콘을 보내드립니다.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _currentPoints -= gifticon.price; // 포인트 차감
                });
                await _savePoints(); // 포인트 저장

                final order = GifticonOrder(
                  gifticonId: gifticon.id,
                  gifticonName: gifticon.name,
                  pricePaid: gifticon.price,
                  orderDate: DateTime.now(),
                  userGoogleId: _userGoogleId, // 사용자의 실제 구글 ID (여기서는 더미)
                );
                await _saveOrderHistory(order); // 신청 내역 저장

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${gifticon.name} 신청 완료! 관리자 확인 후 발송됩니다.')),
                );
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const Text('신청'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('워렌봇핏 기프트 샵'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '내 포인트: $_currentPoints 💰',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '모은 포인트로 기프티콘을 받아가세요!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 한 줄에 2개 아이템
                  crossAxisSpacing: 16.0, // 가로 간격
                  mainAxisSpacing: 16.0, // 세로 간격
                  childAspectRatio: 0.75, // 아이템의 가로 세로 비율 (이미지+텍스트 고려)
                ),
                itemCount: Gifticon.allGifticons.length,
                itemBuilder: (context, index) {
                  final gifticon = Gifticon.allGifticons[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => _requestGifticon(gifticon),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.asset(
                                gifticon.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gifticon.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${gifticon.price} 포인트',
                                  style: const TextStyle(fontSize: 15, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                  Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                  child: ElevatedButton(
                  onPressed: () => _requestGifticon(gifticon),
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('신청하기'),
                  ),
                  ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}