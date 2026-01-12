class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final double balance;  // ⭐ CASHFLOW
  final double totalEarnings;  // ⭐ CASHFLOW
  final double totalWithdrawn;  // ⭐ CASHFLOW
  final double rating;
  final int completedProjects;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.balance = 0,
    this.totalEarnings = 0,
    this.totalWithdrawn = 0,
    this.rating = 0,
    this.completedProjects = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'freelancer',
      balance: (map['balance'] ?? 0).toDouble(),
      totalEarnings: (map['totalEarnings'] ?? 0).toDouble(),
      totalWithdrawn: (map['totalWithdrawn'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      completedProjects: map['completedProjects'] ?? 0,
    );
  }

  // ⭐ CASHFLOW: Hitung pending balance
  double get pendingBalance => totalEarnings - balance - totalWithdrawn;
}