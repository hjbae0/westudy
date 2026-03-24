// 솔라피 알림톡 템플릿 정의

export interface AlimtalkTemplate {
  templateId: string;
  templateContent: string;
  buttons?: Array<{
    buttonType: string;
    buttonName: string;
    linkMo?: string;
    linkPc?: string;
  }>;
}

// 예약 확인 알림
export const BOOKING_CONFIRMED: AlimtalkTemplate = {
  templateId: 'westudy_booking_confirmed',
  templateContent: [
    '[WeStudy] 수업 예약 확인',
    '',
    '#{학생명}님의 수업이 예약되었습니다.',
    '',
    '- 과목: #{과목명}',
    '- 날짜: #{수업일자}',
    '- 시간: #{수업시간}',
    '- 강사: #{강사명}',
    '',
    '수업 10분 전까지 입실해 주세요.',
  ].join('\n'),
  buttons: [
    {
      buttonType: 'WL',
      buttonName: '예약 확인하기',
      linkMo: 'https://westudy.app/student/booking',
      linkPc: 'https://westudy.app/student/booking',
    },
  ],
};

// 수업 리마인더 (1시간 전)
export const CLASS_REMINDER: AlimtalkTemplate = {
  templateId: 'westudy_class_reminder',
  templateContent: [
    '[WeStudy] 수업 알림',
    '',
    '#{학생명}님, 1시간 후 수업이 있습니다.',
    '',
    '- 과목: #{과목명}',
    '- 시간: #{수업시간}',
    '- 강사: #{강사명}',
  ].join('\n'),
};

// 예약 취소 알림
export const BOOKING_CANCELLED: AlimtalkTemplate = {
  templateId: 'westudy_booking_cancelled',
  templateContent: [
    '[WeStudy] 예약 취소 안내',
    '',
    '#{학생명}님의 수업 예약이 취소되었습니다.',
    '',
    '- 과목: #{과목명}',
    '- 날짜: #{수업일자}',
    '- 시간: #{수업시간}',
    '',
    '재예약을 원하시면 앱에서 진행해 주세요.',
  ].join('\n'),
  buttons: [
    {
      buttonType: 'WL',
      buttonName: '다시 예약하기',
      linkMo: 'https://westudy.app/student/booking',
      linkPc: 'https://westudy.app/student/booking',
    },
  ],
};

// 학부모 리포트 알림 (주간)
export const PARENT_WEEKLY_REPORT: AlimtalkTemplate = {
  templateId: 'westudy_parent_weekly_report',
  templateContent: [
    '[WeStudy] 주간 학습 리포트',
    '',
    '#{학부모명}님, #{학생명} 학생의 주간 리포트입니다.',
    '',
    '- 출석률: #{출석률}',
    '- 학습시간: #{학습시간}',
    '- 수업 횟수: #{수업횟수}회',
    '',
    '자세한 내용은 앱에서 확인하세요.',
  ].join('\n'),
  buttons: [
    {
      buttonType: 'WL',
      buttonName: '리포트 보기',
      linkMo: 'https://westudy.app/parent',
      linkPc: 'https://westudy.app/parent',
    },
  ],
};
