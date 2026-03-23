import 'dart:io';

void main() async {
  final file = File('lib/features/admin/controllers/admin_controller.dart');
  var content = await file.readAsString();
  
  // 1. Insert property
  final propertyTarget = 'int get todayAdViewerCount => _todayAdViewerCount;';
  final propertyReplacement = '''int get todayAdViewerCount => _todayAdViewerCount;

  int _todayAdImpressionCount = 0;
  int get todayAdImpressionCount => _todayAdImpressionCount;''';

  if (!content.contains('int get todayAdImpressionCount')) {
    content = content.replaceFirst(propertyTarget, propertyReplacement);
  }

  // 2. Insert query
  final queryTarget = '_todayAdViewerCount = adViewerQuery.count ?? 0;';
  final queryReplacement = '''_todayAdViewerCount = adViewerQuery.count ?? 0;

      // 오늘 광고 횟수
      final adImpressionQuery = await _firestore
          .collection('ad_logs')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
          .count()
          .get();
      _todayAdImpressionCount = adImpressionQuery.count ?? 0;''';
      
  if (!content.contains('adImpressionQuery.count')) {
    content = content.replaceFirst(queryTarget, queryReplacement);
  }
  
  await file.writeAsString(content);
  print('Patched admin_controller.dart successfully.');
}
