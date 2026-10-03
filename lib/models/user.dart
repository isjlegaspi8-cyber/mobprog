class User {
  final int id;
  final String uid;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final int age;
  final String contactNo;

  User({
    required this.id,
    required this.uid,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.contactNo,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isValid => id != 0 || uid.isNotEmpty || email.isNotEmpty;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _intValue(json['id']),
      uid: json['uid']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      age: _intValue(json['age']),
      contactNo: json['contactNo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'contactNo': contactNo,
    };
  }

  static int _intValue(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
}
