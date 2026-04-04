import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shaya_ai/core/app_exception.dart';
import 'package:shaya_ai/core/hive_cache.dart';
import 'package:shaya_ai/core/secure_storage.dart';
import 'package:shaya_ai/features/auth/auth_repository.dart';
import 'package:shaya_ai/features/profile/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSessionController extends ChangeNotifier {
  AppSessionController({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required SecureStore secureStore,
    required EncryptedHiveCache hiveCache,
  }) : _authRepository = authRepository,
       _profileRepository = profileRepository,
       _secureStore = secureStore,
       _hiveCache = hiveCache;

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final SecureStore _secureStore;
  final EncryptedHiveCache _hiveCache;

  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;
  bool _initialized = false;
  bool _onboardingComplete = false;
  bool _isBusy = false;
  String? _pendingVerificationEmail;

  bool get initialized => _initialized;
  bool get onboardingComplete => _onboardingComplete;
  bool get isBusy => _isBusy;
  bool get isAuthenticated => _session?.user != null;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  Session? get session => _session;

  Future<void> initialize() async {
    _onboardingComplete = await _secureStore.isOnboardingComplete();
    _session = _authRepository.currentSession;
    _authSubscription = _authRepository.authStateChanges.listen((event) {
      _session = event.session;
      notifyListeners();
    });
    _initialized = true;
    notifyListeners();
    if (isAuthenticated) {
      await _syncOnboardingPreferences();
    }
  }

  Future<void> completeOnboarding({
    required List<String> genres,
    required String mood,
  }) async {
    await _secureStore.savePreferredGenres(genres);
    await _secureStore.savePreferredMood(mood);
    await _secureStore.markOnboardingComplete();
    _onboardingComplete = true;
    notifyListeners();
    if (isAuthenticated) {
      await _syncOnboardingPreferences();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _runBusy(() async {
      final response = await _authRepository.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AppException('We could not sign you in.');
      }
      if (user.emailConfirmedAt == null) {
        _pendingVerificationEmail = email;
        await _authRepository.signOut();
        throw const AppException(
          'Verify your email address before logging in.',
        );
      }
      _session = response.session;
      notifyListeners();
      await _syncOnboardingPreferences();
    });
  }

  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (password.length < 8) {
      throw const AppException('Password must be at least 8 characters.');
    }

    await _runBusy(() async {
      final response = await _authRepository.signUp(
        displayName: displayName,
        email: email,
        password: password,
      );
      _pendingVerificationEmail = email;
      if (response.user == null) {
        throw const AppException('Unable to create your account right now.');
      }
      if (response.user?.emailConfirmedAt == null && response.session != null) {
        await _authRepository.signOut();
      }
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    await _runBusy(_authRepository.signInWithGoogle);
  }

  Future<void> requestPasswordReset(String email) async {
    await _runBusy(() => _authRepository.requestPasswordReset(email));
  }

  Future<void> signOut() async {
    await _runBusy(() async {
      await _authRepository.signOut();
      await _secureStore.clearSessionArtifacts();
      await _hiveCache.clearLibraryCache();
      _session = null;
      notifyListeners();
    });
  }

  Future<void> _syncOnboardingPreferences() async {
    final genres = await _secureStore.readPreferredGenres();
    final mood = await _secureStore.readPreferredMood();
    if (genres.isEmpty && (mood == null || mood.isEmpty)) {
      return;
    }
    await _profileRepository.syncOnboardingPreferences(
      genres: genres,
      mood: mood,
    );
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } on AuthException catch (error) {
      throw AppException(error.message);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
