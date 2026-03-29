import '../entities/user_entity.dart';

class LoginUser {
  Future<UserEntity> execute(String email, String password) async {
    // implement use case logic
    return UserEntity(id: '0', name: 'Demo', email: email);
  }
}
