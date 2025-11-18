class User {
  int id;
  String username;
  String email;
  String? password;
  String role;
  String? address;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.password,
    required this.role,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      password: json['password'],
      role: json['role'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'password': password,
        'role': role,
        'address': address,
      };
}