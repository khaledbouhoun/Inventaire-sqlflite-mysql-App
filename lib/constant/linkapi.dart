class AppLink {
  // ===============================
  // Base server URL
  // ===============================
  // static const String server = "http://192.168.1.65:8000/api";
  static const String server = "https://inventaire.zakawatt.dz/api";
  //
  // ===============================
  // Test Endpoint
  // ===============================
  static const String test = "$server/test";

  // ===============================
  // User Endpoints
  // ===============================
  static const String users = "$server/user"; // GET all users, POST register
  static const String login = "$server/user/login";
  static const String autoLogin = "$server/user/auto-login";
  static const String logout = "$server/user/logout";
  static const String updatePointage = "$server/user/update-pointage";
  static const String updateDepot = "$server/user/update-depot";

  // ===============================
  // Product Endpoints
  // ===============================
  static const String products = "$server/products"; // GET list or POST create
  static const String importProducts =
      "$server/products/import"; // POST import Excel

  // ===============================
  // Lemplacement Endpoints
  // ===============================
  static const String lemplacements =
      "$server/lemplacements"; // GET all, POST create

  // ===============================
  // Gestqr Endpoints
  // ===============================
  static const String gestqr = "$server/gestqr"; // GET all, POST create

  // ===============================
  // Invontaie Endpoints
  // ===============================
  static const String invontaies = "$server/invontaies"; // GET all, POST create
}
