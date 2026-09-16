import 'user_model.dart';

class StoredAccount {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  StoredAccount({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory StoredAccount.fromJson(Map<String, dynamic> json) {
    return StoredAccount(
      user: UserModel.fromJson(
        json['user'] as Map<String, dynamic>,
      ),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }
}