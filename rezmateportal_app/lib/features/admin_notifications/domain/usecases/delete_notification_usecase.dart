import 'package:dartz/dartz.dart';
import 'package:rezmateportal/features/admin_notifications/domain/repositories/admin_notifications_repository.dart';
import '../../../../../core/error/failures.dart';

class DeleteAdminNotificationUseCase {
  final AdminNotificationsRepository repository;
  DeleteAdminNotificationUseCase(this.repository);

  Future<Either<Failure, bool>> call(String notificationId) =>
      repository.delete(notificationId);
}
