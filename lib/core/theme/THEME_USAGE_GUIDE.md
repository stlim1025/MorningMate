// 테마 색상 사용 가이드
// 
// 각 화면에서 색상을 사용할 때는 다음과 같이 AppColorScheme을 통해 가져와야 합니다:
//
// final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
//
// 그리고 다음과 같이 사용:
// - 버튼 색상: colorScheme.primaryButton, colorScheme.secondaryButton
// - 아이콘 색상: colorScheme.iconPrimary, colorScheme.iconSecondary  
// - 게이지 색상: colorScheme.gaugeActive, colorScheme.gaugeInactive
// - 달력 색상: colorScheme.calendarSelected, colorScheme.calendarToday, colorScheme.calendarDefault
// - 탭 색상: colorScheme.tabSelected, colorScheme.tabUnselected
// - 카드 강조 색상: colorScheme.cardAccent
// - 프로그레스 바: colorScheme.progressBar
// - 연속 기록 골드: colorScheme.streakGold
// - 성공/에러/경고: colorScheme.success, colorScheme.error, colorScheme.warning
//
// 이렇게 하면 테마가 변경될 때 자동으로 모든 색상이 업데이트됩니다.
