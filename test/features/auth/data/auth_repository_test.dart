import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/auth/data/auth_repository.dart';
import 'package:my_career_app/features/auth/domain/app_user.dart';

class MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockUserCredential extends Mock implements fb.UserCredential {}

class MockFirebaseUser extends Mock implements fb.User {}

class FakeAuthCredential extends Fake implements fb.AuthCredential {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late FirebaseAuthRepository repository;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    repository = FirebaseAuthRepository(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('FirebaseAuthRepository.authStateChanges', () {
    test('Firebase User を AppUser にマッピングして流す', () {
      final mockUser = MockFirebaseUser();
      when(() => mockUser.uid).thenReturn('uid-123');
      when(() => mockUser.displayName).thenReturn('テストユーザー');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(mockUser));

      expect(
        repository.authStateChanges(),
        emits(const AppUser(
          uid: 'uid-123',
          displayName: 'テストユーザー',
          email: 'test@example.com',
        )),
      );
    });

    test('サインアウト時は null を流す', () {
      when(() => mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(null));

      expect(repository.authStateChanges(), emits(null));
    });
  });

  group('FirebaseAuthRepository.signInWithGoogle', () {
    test('サインイン成功時に AppUser を返す', () async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();
      final mockCredential = MockUserCredential();
      final mockUser = MockFirebaseUser();

      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockAuth);
      when(() => mockAuth.accessToken).thenReturn('access-token');
      when(() => mockAuth.idToken).thenReturn('id-token');
      when(() => mockFirebaseAuth.signInWithCredential(any()))
          .thenAnswer((_) async => mockCredential);
      when(() => mockCredential.user).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('uid-456');
      when(() => mockUser.displayName).thenReturn('Hanako');
      when(() => mockUser.email).thenReturn('hanako@example.com');
      when(() => mockUser.photoURL).thenReturn(null);

      final result = await repository.signInWithGoogle();

      expect(result.uid, equals('uid-456'));
      expect(result.displayName, equals('Hanako'));
      expect(result.email, equals('hanako@example.com'));
    });

    test('ユーザーがキャンセルした場合は例外をスロー', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      expect(repository.signInWithGoogle(), throwsException);
    });
  });

  group('FirebaseAuthRepository.signOut', () {
    test('Firebase と Google 両方のサインアウトを呼び出す', () async {
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      await repository.signOut();

      verify(() => mockFirebaseAuth.signOut()).called(1);
      verify(() => mockGoogleSignIn.signOut()).called(1);
    });
  });
}
