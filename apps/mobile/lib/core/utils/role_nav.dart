import '../../core/models/app_user.dart';

String homePathForRole(UserRole role) {
  return switch (role) {
    UserRole.driver => '/driver/radar',
    UserRole.merchant => '/merchant',
    UserRole.admin => '/admin',
    UserRole.consumer => '/home',
  };
}
