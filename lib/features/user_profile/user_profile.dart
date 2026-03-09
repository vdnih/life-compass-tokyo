import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile.g.dart';

class UserProfile {
  final String name;
  final DateTime? birthDate;

  UserProfile({required this.name, this.birthDate});

  int? get age => calculateAgeAt(DateTime.now());

  int? calculateAgeAt(DateTime date) {
    if (birthDate == null) return null;
    int age = date.year - birthDate!.year;
    if (date.month < birthDate!.month ||
        (date.month == birthDate!.month && date.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  UserProfile copyWith({String? name, DateTime? birthDate}) {
    return UserProfile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
    );
  }
}

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  @override
  UserProfile build() {
    return UserProfile(name: 'ユーザー');
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateBirthDate(DateTime birthDate) {
    state = state.copyWith(birthDate: birthDate);
  }
}
