import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/support_message.dart';

abstract class SupportRepository {
  Future<Either<Failure, Map<String, dynamic>>> sendSupportMessage(
    SupportMessage message,
  );
}
