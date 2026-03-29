import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signUp(String email, String password);
  Future<UserModel> login(String email, String password);
}
