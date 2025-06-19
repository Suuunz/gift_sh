import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// --- Mission Model 정의 (기존 미션 코드에서 가져옴) ---
enum MissionStatus {
  uncompleted, // 미완료
  pending,     // 제출됨 (관리자 승인 대기)
  completed,   // 완료됨 (관리자 승인 완료)
}

enum MissionSubmissionMethod {
  buttonClick, // 단순히 버튼 클릭으로 완료
  textInput,   // 텍스트 입력으로 완료
  photoUpload, // 사진 업로드로 완료
  autoCheck,   // (나중에 구현될) 자동 검사 (예: 지출 기록, 챗봇 대화 수)
}

// MissionType 정의: 일반 미션과 챌린지 미션을 구분
enum MissionType {
  general,     // 일반 미션 (가계부, 챗봇 이용 등 앱 기능 활용)
  challenge,   // 챌린지 미션 (무지출 챌린지, 계획 소비 등)
}

// 미션 모델 정의
class Mission {
  final String id; // 미션 고유 ID
  final String name; // 미션명
  final String content; // 내용 (미션 목표)
  final String method; // 미션 방법 (수행 안내)
  final IconData icon; // 미션 아이콘
  final int rewardPoint; // 보상 포인트
  final String? rewardBadge; // 보상 배지명 (선택 사항)
  final MissionType type; // 미션 유형 (General 또는 Challenge)
  final MissionSubmissionMethod submissionMethod; // 미션 제출 방법

  Mission({
    required this.id,
    required this.name,
    required this.content,
    required this.method,
    required this.icon,
    required this.rewardPoint,
    this.rewardBadge,
    required this.type,
    required this.submissionMethod,
  });

  // 미션 목록 정의 (예시 데이터)
  static List<Mission> get allMissions => [
    // --- 일반 미션 ---
    Mission(
      id: 'categorize_spending',
      name: '오늘은 지출을 분류해보기 🧠',
      content: '오늘 사용한 지출을 각각 교통, 식비, 문화비 등으로 나눠 가계부에 입력해보세요.',
      method: '가계부에 3개 이상의 지출을 분류하여 입력 후, "미션 완료" 버튼을 눌러주세요.',
      icon: Icons.category,
      rewardPoint: 5,
      rewardBadge: '지출 인식력 향상',
      type: MissionType.general, // 일반 미션
      submissionMethod: MissionSubmissionMethod.buttonClick,
    ),
    Mission(
      id: 'receipt_record',
      name: '지출 영수증 정리 🧾',
      content: '오늘 지출한 항목의 영수증을 보고 정확히 금액을 가계부에 입력해보세요.',
      method: '정리한 영수증을 사진으로 찍어 업로드하고, 어떤 지출을 정리했는지 간단히 적어 제출해주세요.',
      icon: Icons.receipt_long,
      rewardPoint: 5,
      rewardBadge: '정밀 소비자',
      type: MissionType.general, // 일반 미션
      submissionMethod: MissionSubmissionMethod.photoUpload,
    ),
    Mission(
      id: 'fixed_expense_review',
      name: '매달 나가는 돈 점검하기 🔄',
      content: '이번 달 고정 지출을 다시 한 번 점검하고 불필요한 항목이 없는지 체크하세요.',
      method: '고정 지출 점검 후, 절약 아이디어를 한 가지 제출해주세요.',
      icon: Icons.settings_backup_restore,
      rewardPoint: 15,
      rewardBadge: '절약 전략가',
      type: MissionType.general, // 일반 미션
      submissionMethod: MissionSubmissionMethod.textInput,
    ),
    Mission(
      id: 'chatbot_daily_chat',
      name: '챗봇과 대화하기 💬',
      content: '소울챗과 5회 이상 대화하며 가계부 팁을 얻어보세요!',
      method: '소울챗과 5회 이상 대화 후, "미션 완료" 버튼을 눌러주세요.',
      icon: Icons.chat_bubble_outline,
      rewardPoint: 7,
      rewardBadge: '친밀한 대화가',
      type: MissionType.general, // 일반 미션
      submissionMethod: MissionSubmissionMethod.buttonClick,
    ),

    // --- 챌린지 미션 ---
    Mission(
      id: 'coffee_challenge',
      name: '오늘은 커피값 아껴보기 ☕',
      content: '카페 대신 집에서 커피를 마셔서 5,000원 이상 절약해보세요!',
      method: '집에서 커피를 마신 후, 절약된 금액을 메모와 함께 제출해주세요.',
      icon: Icons.coffee_maker_outlined,
      rewardPoint: 5,
      rewardBadge: '커피 절약왕',
      type: MissionType.challenge, // 챌린지 미션
      submissionMethod: MissionSubmissionMethod.textInput,
    ),
    Mission(
      id: 'no_spend_day',
      name: '무지출 챌린지 💸',
      content: '하루 동안 식비, 교통비 등 어떤 지출도 하지 않고 견뎌보세요!',
      method: '하루 동안 지출이 없었음을 인증하는 짧은 글과 함께 제출해주세요.',
      icon: Icons.money_off,
      rewardPoint: 10,
      rewardBadge: '0원 소비',
      type: MissionType.challenge, // 챌린지 미션
      submissionMethod: MissionSubmissionMethod.textInput,
    ),
    Mission(
      id: 'planned_spending',
      name: '계획적인 소비 도전 🛍',
      content: '오늘은 미리 계획한 지출만 하기! 즉흥 구매는 NO!',
      method: '미리 구매 목록을 작성하고 계획한 소비만 했음을 짧은 글로 작성하여 제출해주세요.',
      icon: Icons.shopping_bag_outlined,
      rewardPoint: 8,
      rewardBadge: '계획형 소비자',
      type: MissionType.challenge, // 챌린지 미션
      submissionMethod: MissionSubmissionMethod.textInput,
    ),
  ];

  // 일반 미션만 필터링
  static List<Mission> get generalMissions =>
      allMissions.where((mission) => mission.type == MissionType.general).toList();

  // 챌린지 미션만 필터링
  static List<Mission> get challengeMissions =>
      allMissions.where((mission) => mission.type == MissionType.challenge).toList();
}

// 제출된 미션 데이터 모델
class SubmittedMission {
  final String missionId;
  final String submittedText;
  final String? imageUrl; // 사진 업로드 시 이미지 URL
  final DateTime submissionDate;
  MissionStatus status; // 미션의 현재 상태 (pending, completed)

  SubmittedMission({
    required this.missionId,
    required this.submittedText,
    this.imageUrl,
    required this.submissionDate,
    this.status = MissionStatus.pending, // 기본 상태는 승인 대기
  });

  // JSON 직렬화를 위한 toMap
  Map<String, dynamic> toJson() {
    return {
      'missionId': missionId,
      'submittedText': submittedText,
      'imageUrl': imageUrl,
      'submissionDate': submissionDate.toIso8601String(),
      'status': status.index, // Enum을 int로 저장
    };
  }

  // JSON 역직렬화를 위한 factory constructor
  factory SubmittedMission.fromJson(Map<String, dynamic> json) {
    return SubmittedMission(
      missionId: json['missionId'] as String,
      submittedText: json['submittedText'] as String,
      imageUrl: json['imageUrl'] as String?,
      submissionDate: DateTime.parse(json['submissionDate'] as String),
      status: MissionStatus.values[json['status'] as int], // int를 Enum으로 변환
    );
  }
}
// --- Mission Model 정의 끝 ---


// --- Main App Entry Point ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '워렌봇핏', // 앱 이름 설정
      theme: ThemeData(
        primarySwatch: Colors.blueGrey, // 앱 전체 테마 색상 설정
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
      home: const LoginPage(), // 앱의 시작 화면을 LoginPage로 설정
    );
  }
}

// --- 로그인 페이지 ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // 실제 로그인 로직 (API 호출 등)은 여기에 구현될 수 있습니다.
      // 현재는 유효성 검사만 통과하면 초기 설정 페이지로 이동합니다.
      Navigator.pushReplacement( // 로그인 후 뒤로가기 방지를 위해 pushReplacement 사용
        context,
        MaterialPageRoute(builder: (context) => const InitialSetupPage()),
      );
    }
  }

  void _googleLogin() {
    // 실제 구글 로그인 로직은 여기에 구현 (예: Firebase Auth)
    // 현재는 기능 없이 메시지만 출력
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google 로그인 기능은 아직 구현되지 않았습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('워렌봇핏'), // 앱 이름 앱바에 표시
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 로고 또는 아이콘 (선택 사항)
                Icon(
                  Icons.account_balance_wallet,
                  size: 100,
                  color: Colors.blueGrey.shade700,
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: '아이디',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '아이디를 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true, // 비밀번호 숨김
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _login, // 로그인 버튼
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('로그인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _googleLogin, // 구글 로그인 버튼
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      side: const BorderSide(color: Colors.blueGrey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Image.asset(
                      'asset/img/google_logo.png', // 구글 로고 이미지 경로 (추가 필요)
                      height: 24.0,
                    ),
                    label: const Text('Google로 로그인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 초기 설정 페이지 ---
class InitialSetupPage extends StatefulWidget {
  const InitialSetupPage({super.key});

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _monthlyIncomeController = TextEditingController();
  final TextEditingController _residenceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _jobController.dispose();
    _monthlyIncomeController.dispose();
    _residenceController.dispose();
    super.dispose();
  }

  Future<void> _saveInitialSetup() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text);
      await prefs.setInt('user_age', int.parse(_ageController.text));
      await prefs.setString('user_job', _jobController.text);
      await prefs.setInt('user_monthly_income', int.parse(_monthlyIncomeController.text));
      await prefs.setString('user_residence', _residenceController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('초기 설정이 저장되었습니다!')),
      );

      // 설정 완료 후 미션 목록 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MissionListPage()), // 미션 페이지로 이동
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('초기 설정'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '워렌봇핏을 시작하기 위해 필요한 정보를 입력해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '이름',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '나이',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.cake_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '나이를 입력해주세요.';
                    }
                    if (int.tryParse(value) == null) {
                      return '유효한 나이를 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _jobController,
                  decoration: InputDecoration(
                    labelText: '직업',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.work_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '직업을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _monthlyIncomeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '월 수입 (원)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '월 수입을 입력해주세요.';
                    }
                    if (int.tryParse(value) == null) {
                      return '유효한 월 수입을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _residenceController,
                  decoration: InputDecoration(
                    labelText: '거주지 (시/도 단위)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '거주지를 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveInitialSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('시작하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Mission List Page (기존 미션 코드에서 가져옴) ---
class MissionListPage extends StatefulWidget {
  const MissionListPage({super.key});

  @override
  State<MissionListPage> createState() => _MissionListPageState();
}

class _MissionListPageState extends State<MissionListPage> {
  // 미션 ID를 키로, 상태를 값으로 갖는 맵
  Map<String, MissionStatus> _missionStatus = {};
  int _totalPoints = 0; // 총 포인트

  // 제출된 미션 목록 (관리자 승인 대기 중이거나 승인 완료된 미션)
  List<SubmittedMission> _completedMissionSubmissions = [];

  @override
  void initState() {
    super.initState();
    _loadAllData(); // 앱 시작 시 모든 데이터 로드
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 미션 상태 로드
    final String? missionStatusJson = prefs.getString('mission_status');
    if (missionStatusJson != null) {
      _missionStatus = Map<String, MissionStatus>.from(
        (json.decode(missionStatusJson) as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, MissionStatus.values[value as int]),
        ),
      );
    } else {
      // 초기 미션 상태 (모두 미완료)
      for (var mission in Mission.allMissions) {
        _missionStatus[mission.id] = MissionStatus.uncompleted;
      }
    }

    // 2. 총 포인트 로드
    _totalPoints = prefs.getInt('total_points') ?? 0;

    // 3. 제출된 미션 목록 로드
    final String? submittedMissionsJson = prefs.getString('submitted_missions');
    if (submittedMissionsJson != null) {
      Iterable decoded = json.decode(submittedMissionsJson);
      _completedMissionSubmissions = List<SubmittedMission>.from(
          decoded.map((model) => SubmittedMission.fromJson(model)));
    }

    setState(() {}); // UI 업데이트
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 미션 상태 저장
    final Map<String, int> statusToSave =
    _missionStatus.map((key, value) => MapEntry(key, value.index));
    await prefs.setString('mission_status', json.encode(statusToSave));

    // 2. 총 포인트 저장
    await prefs.setInt('total_points', _totalPoints);

    // 3. 제출된 미션 목록 저장
    final List<Map<String, dynamic>> submissionsToSave =
    _completedMissionSubmissions.map((e) => e.toJson()).toList();
    await prefs.setString('submitted_missions', json.encode(submissionsToSave));
  }

  // 미션 완료 처리 (버튼 클릭으로 즉시 완료되는 미션)
  void _completeButtonClickMission(Mission mission) {
    if (_missionStatus[mission.id] != MissionStatus.uncompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${mission.name}은(는) 이미 처리되었어요!')),
      );
      return;
    }

    setState(() {
      _missionStatus[mission.id] = MissionStatus.completed; // 바로 완료
      _totalPoints += mission.rewardPoint; // 포인트 즉시 지급
    });
    _saveAllData(); // 상태 저장

    _showRewardDialog(mission);
  }

  // 미션 제출 페이지로 이동
  void _navigateToSubmitPage(Mission mission) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MissionSubmitPage(mission: mission),
      ),
    );

    if (result != null && result is SubmittedMission) {
      setState(() {
        _missionStatus[mission.id] = MissionStatus.pending; // 제출됨 상태로 변경
        _completedMissionSubmissions.add(result); // 제출된 미션 목록에 추가
      });
      _saveAllData(); // 상태 저장
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${mission.name} 미션이 제출되었습니다. 관리자 승인 대기 중!')),
      );
    }
  }

  // 보상 다이얼로그 표시
  void _showRewardDialog(Mission mission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎉 미션 완료! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${mission.name} 미션을 완료했습니다!', textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                '✨ ${mission.rewardPoint} 포인트 획득!',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18),
              ),
              if (mission.rewardBadge != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    '" ${mission.rewardBadge} " 배지 획득!',
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 더미 관리자 승인 로직 (실제 앱에서는 백엔드에서 처리)
  void _adminApproveMission(SubmittedMission submittedMission) {
    final mission = Mission.allMissions.firstWhere((m) => m.id == submittedMission.missionId);

    setState(() {
      submittedMission.status = MissionStatus.completed; // 제출된 미션의 상태를 완료로 변경
      _missionStatus[mission.id] = MissionStatus.completed; // 원본 미션의 상태도 완료로 변경
      _totalPoints += mission.rewardPoint; // 포인트 지급
    });
    _saveAllData(); // 상태 저장

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${mission.name} 미션이 관리자에 의해 승인되었습니다! ${mission.rewardPoint} 포인트 지급!')),
    );
  }

  // 미션 목록을 빌드하는 헬퍼 위젯
  Widget _buildMissionListSection(List<Mission> missions, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        Column(
          children: missions.map((mission) {
            final currentStatus = _missionStatus[mission.id] ?? MissionStatus.uncompleted;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: currentStatus == MissionStatus.completed
                  ? Colors.lightGreen.shade100
                  : currentStatus == MissionStatus.pending
                  ? Colors.amber.shade50
                  : Colors.white,
              child: InkWell(
                onTap: () {
                  if (currentStatus == MissionStatus.pending) {
                    final submittedMission = _completedMissionSubmissions.firstWhere(
                            (sub) => sub.missionId == mission.id && sub.status == MissionStatus.pending);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('${mission.name} 제출 내역'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('제출 내용: ${submittedMission.submittedText}'),
                            if (submittedMission.imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Image.file(File(submittedMission.imageUrl!)),
                              ),
                            const SizedBox(height: 10),
                            const Text('관리자 승인 대기 중입니다.'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              _adminApproveMission(submittedMission);
                              Navigator.of(context).pop();
                            },
                            child: const Text('관리자 승인 (더미)'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('닫기'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            mission.icon,
                            color: currentStatus == MissionStatus.completed
                                ? Colors.lightGreen
                                : currentStatus == MissionStatus.pending
                                ? Colors.orange
                                : Colors.blueGrey,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              mission.name,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                decoration: currentStatus == MissionStatus.completed
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: currentStatus == MissionStatus.completed
                                    ? Colors.lightGreen.shade700
                                    : currentStatus == MissionStatus.pending
                                    ? Colors.orange.shade700
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (currentStatus == MissionStatus.completed)
                            const Icon(Icons.check_circle, color: Colors.lightGreen, size: 28)
                          else if (currentStatus == MissionStatus.pending)
                            const Icon(Icons.access_time, color: Colors.orange, size: 28),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        mission.content,
                        style: TextStyle(
                          fontSize: 15,
                          color: currentStatus == MissionStatus.completed
                              ? Colors.grey.shade600
                              : currentStatus == MissionStatus.pending
                              ? Colors.orange.shade400
                              : Colors.black54,
                          fontStyle: currentStatus != MissionStatus.uncompleted ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _buildMissionActionButton(mission, currentStatus),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 미션 목록'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '총 포인트: $_totalPoints 💰',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView( // 전체 화면을 스크롤 가능하게
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '지출을 재미있게 관리해보세요!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 20),

            // 일반 미션 섹션
            _buildMissionListSection(Mission.generalMissions, '일반 미션 (앱 기능 활용)'),
            const SizedBox(height: 30), // 섹션 간 간격

            // 챌린지 미션 섹션
            _buildMissionListSection(Mission.challengeMissions, '챌린지 미션'),
          ],
        ),
      ),
    );
  }

  // 미션 상태에 따른 액션 버튼 빌더 (이전과 동일)
  Widget _buildMissionActionButton(Mission mission, MissionStatus currentStatus) {
    switch (currentStatus) {
      case MissionStatus.uncompleted:
        if (mission.submissionMethod == MissionSubmissionMethod.buttonClick) {
          return ElevatedButton.icon(
            onPressed: () => _completeButtonClickMission(mission),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('미션 완료하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          );
        } else {
          // MissionSubmissionMethod.textInput 또는 MissionSubmissionMethod.photoUpload인 경우
          return ElevatedButton.icon(
            onPressed: () => _navigateToSubmitPage(mission),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            icon: const Icon(Icons.send),
            label: const Text('미션 제출하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          );
        }
      case MissionStatus.pending:
        return ElevatedButton.icon(
          onPressed: null, // 승인 대기 중일 때는 비활성화
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade400,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          icon: const Icon(Icons.hourglass_empty),
          label: const Text('승인 대기 중', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        );
      case MissionStatus.completed:
        return ElevatedButton.icon(
          onPressed: null, // 완료된 미션은 비활성화
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade400,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          icon: const Icon(Icons.done_all),
          label: const Text('미션 완료됨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        );
    }
  }
}


// --- Mission Submit Page (기존 미션 코드에서 가져옴) ---
class MissionSubmitPage extends StatefulWidget {
  final Mission mission;

  const MissionSubmitPage({super.key, required this.mission});

  @override
  State<MissionSubmitPage> createState() => _MissionSubmitPageState();
}

class _MissionSubmitPageState extends State<MissionSubmitPage> {
  final TextEditingController _textController = TextEditingController();
  File? _pickedImage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  void _submitMission() {
    // MissionSubmissionMethod.textInput일 경우 텍스트 입력이 필수인지는 원래 로직에 따라 결정됨
    // 현재는 텍스트 입력이 필수가 아닐 때도 제출 가능하게 수정됨 (스낵바만 띄우고 return 안 함)
    if (_textController.text.isEmpty && widget.mission.submissionMethod == MissionSubmissionMethod.textInput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제출 내용을 입력해주세요.')),
      );
      // return; // 텍스트만 필수인 미션에서 텍스트가 없으면 제출 안 되도록 하려면 이 주석을 풀고 사용
    }

    // MissionSubmissionMethod.photoUpload일 경우 사진이 필수
    if (_pickedImage == null && widget.mission.submissionMethod == MissionSubmissionMethod.photoUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 업로드해주세요.')),
      );
      return; // 사진이 필수인데 없으면 제출 안 되도록
    }


    final submittedMission = SubmittedMission(
      missionId: widget.mission.id,
      submittedText: _textController.text.trim(),
      imageUrl: _pickedImage?.path,
      submissionDate: DateTime.now(),
      status: MissionStatus.pending,
    );

    Navigator.pop(context, submittedMission);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mission.name} 제출하기'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '미션 목표: ${widget.mission.content}', // 텍스트로 된 미션 설명
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              '미션 방법: ${widget.mission.method}', // 텍스트로 된 미션 방법 및 조건
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            // 모든 미션 제출 페이지에 텍스트 입력 필드 표시 (선택적으로 사용)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '제출 내용 작성 (선택)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: '미션 수행 내용을 자세히 작성해주세요. (선택 사항)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            // 모든 미션 제출 페이지에 사진 업로드 기능 표시 (선택적으로 사용)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '인증 사진 업로드 (선택)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Center(
                  child: _pickedImage == null
                      ? Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                      onPressed: _pickImage,
                    ),
                  )
                      : Stack(
                    children: [
                      Image.file(_pickedImage!, height: 200, fit: BoxFit.cover),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 15,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 18),
                            onPressed: () {
                              setState(() {
                                _pickedImage = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            Center(
              child: ElevatedButton.icon(
                onPressed: _submitMission, // 제출하기 버튼
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                icon: const Icon(Icons.upload_file),
                label: const Text('미션 제출하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}