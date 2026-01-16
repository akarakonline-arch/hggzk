import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/verify_email_usecase.dart';
import '../../domain/usecases/resend_email_verification_usecase.dart';
import 'email_verification_event.dart';
import 'email_verification_state.dart';

class EmailVerificationBloc
    extends Bloc<EmailVerificationEvent, EmailVerificationState> {
  final VerifyEmailUseCase verifyEmailUseCase;
  final ResendEmailVerificationUseCase resendEmailVerificationUseCase;

  EmailVerificationBloc({
    required this.verifyEmailUseCase,
    required this.resendEmailVerificationUseCase,
  }) : super(const EmailVerificationInitial()) {
    on<VerifyEmailSubmitted>(_onVerify);
    on<ResendCodePressed>(_onResend);
  }

  Future<void> _onVerify(
    VerifyEmailSubmitted event,
    Emitter<EmailVerificationState> emit,
  ) async {
    emit(const EmailVerificationLoading());
    final result = await verifyEmailUseCase(
      VerifyEmailParams(userId: event.userId, code: event.code),
    );
    result.fold(
      (failure) => emit(EmailVerificationError(_mapFailureToMessage(failure))),
      (ok) => emit(ok
          ? const EmailVerificationSuccess()
          : const EmailVerificationError('رمز التحقق غير صحيح')),
    );
  }

  Future<void> _onResend(
    ResendCodePressed event,
    Emitter<EmailVerificationState> emit,
  ) async {
    emit(const EmailVerificationLoading());
    final result = await resendEmailVerificationUseCase(
      ResendEmailVerificationParams(userId: event.userId, email: event.email),
    );
    result.fold(
      (failure) => emit(EmailVerificationError(_mapFailureToMessage(failure))),
      (retryAfter) => emit(
        EmailVerificationCodeResent(retryAfterSeconds: retryAfter),
      ),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'يرجى التحقق من اتصالك بالإنترنت';
      case ServerFailure:
        return 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً';
      case ValidationFailure:
        return (failure as ValidationFailure).message;
      default:
        return 'حدث خطأ غير متوقع';
    }
  }
}
