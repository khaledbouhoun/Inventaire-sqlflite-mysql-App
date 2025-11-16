class AppLink {
  // ===============================
  // Base server URL
  // ===============================
  static const String server = "http://192.168.1.83:8000/api";
  // static const String server = "https://merceriefz.com/mercerie_api/api";

  // ===============================
  // Auth Endpoints
  // ===============================
  static const String register = "$server/auth/register";
  static const String login = "$server/auth/login";
  static const String autoLogin = "$server/auth/auto-login";
  static const String logout = "$server/auth/logout";
  static const String updatePointage = "$server/auth/update-pointage";
  static const String updateDepot = "$server/auth/update-depot";

  // ===============================
  // Product Endpoints
  // ===============================
  static const String products = "$server/products"; // GET list or POST create
  static const String import = "$server/products/import";

  // ===============================
  // Test Endpoint
  // ===============================
  static const String test = "$server/test";
}
