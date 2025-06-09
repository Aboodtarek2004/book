class User {
  final String uid; // Added uid field
  final String email; // Changed username to email for clarity
  String? name; // Made name nullable as it might not be set initially
  final bool isDoctor;

  User({required this.uid, required this.email, this.name, required this.isDoctor});

  // Factory constructor to create a User from Firestore data
  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    return User(
      uid: documentId,
      email: data['email'] ?? '',
      name: data['name'],
      isDoctor: data['isDoctor'] ?? false,
    );
  }

  // Method to convert User object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'isDoctor': isDoctor,
    };
  }
}
