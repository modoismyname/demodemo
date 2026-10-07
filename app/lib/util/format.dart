const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// 2026년 10월 11일 (일)
String formatKoreanDate(DateTime d) =>
    '${d.year}년 ${d.month}월 ${d.day}일 (${_weekdays[d.weekday - 1]})';
