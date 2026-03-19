
class CountryUtils {
  /// 국가 코드를 국기 이모지로 변환
  static String getFlagEmoji(String? countryCode) {
    if (countryCode == null || countryCode.length != 2) return '❓';
    
    // 국가 코드는 2자리 알파벳이어야 함 (ISO 3166-1 alpha-2)
    final int firstLetter = countryCode.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = countryCode.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
    
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  /// 국가 코드를 한국어 국가명으로 변환
  static String getCountryNameKo(String? countryCode) {
    if (countryCode == null) return '알 수 없음';
    
    final code = countryCode.toUpperCase();
    final Map<String, String> countryNames = {
      'KR': '대한민국',
      'US': '미국',
      'JP': '일본',
      'CN': '중국',
      'TW': '대만',
      'VN': '베트남',
      'TH': '태국',
      'PH': '필리핀',
      'CA': '캐나다',
      'GB': '영국',
      'DE': '독일',
      'FR': '프랑스',
      'IT': '이탈리아',
      'ES': '스페인',
      'RU': '러시아',
      'AU': '호주',
      'BR': '브라질',
      'MX': '멕시코',
      'ID': '인도네시아',
      'MY': '말레이시아',
      'SG': '싱가포르',
      'HK': '홍콩',
      'IN': '인도',
      'AE': '아랍에미리트',
      'SA': '사우디아라비아',
      'TR': '터키',
      'NL': '네덜란드',
      'CH': '스위스',
      'SE': '스웨덴',
      'PL': '폴란드',
      'UA': '우크라이나',
      'NZ': '뉴질랜드',
    };

    return countryNames[code] ?? code;
  }
}
