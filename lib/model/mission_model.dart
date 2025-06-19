import 'package:flutter/material.dart';

// 미션 상태를 나타내는 Enum
enum MissionStatus {
  uncompleted, // 미완료
  pending,     // 제출됨 (관리자 승인 대기)
  completed,   // 완료됨 (관리자 승인 완료)
}

// 미션 제출 방법을 나타내는 Enum
enum MissionSubmissionMethod {
  buttonClick, // 단순히 버튼 클릭으로 완료
  textInput,   // 텍스트 입력으로 완료
  photoUpload, // 사진 업로드로 완료
  autoCheck,   // (나중에 구현될) 자동 검사 (예: 지출 기록, 챗봇 대화 수)
}

// 미션 유형을 나타내는 Enum
enum MissionType {
  accountBook, // 가계부 관련 미션
  chatbot,     // 챗봇 관련 미션
  challenge,   // 챌린지 미션
  general,     // 일반 미션 (지출 분류 등)
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
  final MissionType type; // 미션 유형
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
    Mission(
      id: 'coffee_challenge',
      name: '오늘은 커피값 아껴보기 ☕',
      content: '카페 대신 집에서 커피를 마셔서 5,000원 이상 절약해보세요!',
      method: '집에서 커피를 마신 후, 절약된 금액을 메모와 함께 제출해주세요.',
      icon: Icons.coffee_maker_outlined,
      rewardPoint: 5,
      rewardBadge: '커피 절약왕',
      type: MissionType.accountBook,
      submissionMethod: MissionSubmissionMethod.textInput, // 텍스트 입력으로 제출
    ),
    Mission(
      id: 'no_spend_day',
      name: '무지출 챌린지 💸',
      content: '하루 동안 식비, 교통비 등 어떤 지출도 하지 않고 견뎌보세요!',
      method: '하루 동안 지출이 없었음을 인증하는 짧은 글과 함께 제출해주세요.',
      icon: Icons.money_off,
      rewardPoint: 10,
      rewardBadge: '0원 소비',
      type: MissionType.challenge,
      submissionMethod: MissionSubmissionMethod.textInput, // 텍스트 입력으로 제출
    ),
    Mission(
      id: 'categorize_spending',
      name: '오늘은 지출을 분류해보기 🧠',
      content: '오늘 사용한 지출을 각각 교통, 식비, 문화비 등으로 나눠 가계부에 입력해보세요.',
      method: '가계부에 3개 이상의 지출을 분류하여 입력 후, "미션 완료" 버튼을 눌러주세요.',
      icon: Icons.category,
      rewardPoint: 5,
      rewardBadge: '지출 인식력 향상',
      type: MissionType.accountBook,
      submissionMethod: MissionSubmissionMethod.buttonClick, // 단순히 버튼 클릭으로 완료
    ),
    Mission(
      id: 'planned_spending',
      name: '계획적인 소비 도전 🛍',
      content: '오늘은 미리 계획한 지출만 하기! 즉흥 구매는 NO!',
      method: '미리 구매 목록을 작성하고 계획한 소비만 했음을 짧은 글로 작성하여 제출해주세요.',
      icon: Icons.shopping_bag_outlined,
      rewardPoint: 8,
      rewardBadge: '계획형 소비자',
      type: MissionType.challenge,
      submissionMethod: MissionSubmissionMethod.textInput,
    ),
    Mission(
      id: 'receipt_record',
      name: '지출 영수증 정리 🧾',
      content: '오늘 지출한 항목의 영수증을 보고 정확히 금액을 가계부에 입력해보세요.',
      method: '정리한 영수증을 사진으로 찍어 업로드하고, 어떤 지출을 정리했는지 간단히 적어 제출해주세요.',
      icon: Icons.receipt_long,
      rewardPoint: 5,
      rewardBadge: '정밀 소비자',
      type: MissionType.general,
      submissionMethod: MissionSubmissionMethod.photoUpload, // 사진 업로드로 제출
    ),
    Mission(
      id: 'fixed_expense_review',
      name: '매달 나가는 돈 점검하기 🔄',
      content: '이번 달 고정 지출을 다시 한 번 점검하고 불필요한 항목이 없는지 체크하세요.',
      method: '고정 지출 점검 후, 절약 아이디어를 한 가지 제출해주세요.',
      icon: Icons.settings_backup_restore,
      rewardPoint: 15,
      rewardBadge: '절약 전략가',
      type: MissionType.accountBook,
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
      type: MissionType.chatbot,
      submissionMethod: MissionSubmissionMethod.buttonClick,
    ),
  ];
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