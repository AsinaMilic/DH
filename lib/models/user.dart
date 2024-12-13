class User {
  final int? id;
  final String username;
  final String email;
  final String passwordHash;

  User({this.id, required this.username, required this.email, required this.passwordHash});

  // Factory method to create a User from a Map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      passwordHash: json['password_hash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? null,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
    };
  }
}