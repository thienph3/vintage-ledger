import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vintage_ledger/core/app_exception.dart';

class ErrorMapper {
  /// Map any error to AppException with l10n key as message
  static AppException map(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseAuthException) return _mapAuth(error);
    if (error is FirebaseException) return _mapFirestore(error);
    return const AppException('unknown', 'genericError');
  }

  static AppException _mapFirestore(FirebaseException e) {
    return switch (e.code) {
      'unavailable' => const AppException('unavailable', 'noConnection'),
      'permission-denied' => const AppException('permission-denied', 'noPermission'),
      'resource-exhausted' => const AppException('resource-exhausted', 'systemOverload'),
      'not-found' => const AppException('not-found', 'notFound'),
      'already-exists' => const AppException('already-exists', 'alreadyExists'),
      _ => const AppException('firestore', 'genericError'),
    };
  }

  static AppException _mapAuth(FirebaseAuthException e) {
    return switch (e.code) {
      'wrong-password' || 'invalid-credential' => const AppException('wrong-password', 'wrongPassword'),
      'user-not-found' => const AppException('user-not-found', 'userNotFound'),
      'email-already-in-use' => const AppException('email-already-in-use', 'emailInUse'),
      'weak-password' => const AppException('weak-password', 'weakPassword'),
      'invalid-email' => const AppException('invalid-email', 'invalidEmail'),
      'too-many-requests' => const AppException('too-many-requests', 'tooManyRequests'),
      'network-request-failed' => const AppException('network', 'noConnection'),
      _ => const AppException('auth', 'genericError'),
    };
  }
}
