class VersionUtils {
  /// Returns negative if v1 < v2, zero if v1 == v2, positive if v1 > v2
  static int compareVersions(String v1, String v2) {
    // Remove build number (+22) or suffix (-beta) if present
    String cleanV1 = v1.split('+')[0].split('-')[0];
    String cleanV2 = v2.split('+')[0].split('-')[0];

    List<int> v1Components = cleanV1.split('.').map(int.parse).toList();
    List<int> v2Components = cleanV2.split('.').map(int.parse).toList();

    int len = v1Components.length > v2Components.length
        ? v1Components.length
        : v2Components.length;

    for (int i = 0; i < len; i++) {
      int c1 = i < v1Components.length ? v1Components[i] : 0;
      int c2 = i < v2Components.length ? v2Components[i] : 0;

      if (c1 < c2) return -1;
      if (c1 > c2) return 1;
    }

    return 0;
  }

  static bool isUpdateRequired(String current, String minimum) {
    return compareVersions(current, minimum) < 0;
  }

  static bool isUpdateRecommended(String current, String latest) {
    return compareVersions(current, latest) < 0;
  }
}
