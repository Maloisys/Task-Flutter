class User {
  int? id;
  String login;
  String password; // Будет храниться в хешированном виде
  String? email;
  DateTime? createdAt;
  DateTime? lastLogin;

  User({
    this.id,
    required this.login,
    required this.password,
    this.email,
    this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'login': login,
      'password': password,
      'email': email,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'lastLogin': lastLogin?.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      login: map['login'],
      password: map['password'],
      email: map['email'],
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      lastLogin: map['lastLogin'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLogin'])
          : null,
    );
  }

  // Простое хеширование пароля (в реальном проекте используйте bcrypt)
  static String hashPassword(String password) {
    return password; // В реальности: bcrypt или другую библиотеку
  }

  // Проверка пароля
  bool verifyPassword(String password) {
    return this.password == password; // В реальности: сравнение хешей
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'login': login,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }
}