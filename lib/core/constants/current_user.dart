class CurrentUser {
  static String? accessToken;
  static String? name;
  static int? userId;
  static String? subdomain;
  static String? pictureUrl;

  // Helper methods
  static bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;
  static bool get hasDomain => subdomain != null && subdomain!.isNotEmpty;
  
  static void clear() {
    accessToken = null;
    name = null;
    userId = null;
    subdomain = null;
    pictureUrl = null;
  }
  
  static void clearOnlyAuth() {
    accessToken = null;
    name = null;
    userId = null;
    pictureUrl = null;
    // subdomain'i sakla
  }
}