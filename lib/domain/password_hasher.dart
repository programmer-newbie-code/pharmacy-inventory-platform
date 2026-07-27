import 'package:bcrypt/bcrypt.dart';

/// Wraps bcrypt so the rest of the app never imports a crypto library
/// directly — if the hashing scheme ever changes, this is the one file that
/// changes.
class PasswordHasher {
  String hash(String plainPassword) => BCrypt.hashpw(plainPassword, BCrypt.gensalt());

  bool verify(String plainPassword, String hashedPassword) =>
      BCrypt.checkpw(plainPassword, hashedPassword);
}
