import 'package:flutter/foundation.dart';
import 'package:shaya_ai/features/profile/profile_repository.dart';
import 'package:shaya_ai/shared/models/subscription_tier.dart';
import 'package:shaya_ai/shared/models/user_profile.dart';

class SubscriptionController extends ChangeNotifier {
  SubscriptionController({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository;

  final ProfileRepository _profileRepository;

  SubscriptionTier _selectedTier = SubscriptionTier.basic;
  bool _isBusy = false;
  String? _message;

  SubscriptionTier get selectedTier => _selectedTier;
  bool get isBusy => _isBusy;
  String? get message => _message;

  void selectTier(SubscriptionTier tier) {
    _selectedTier = tier;
    notifyListeners();
  }

  Future<UserProfile?> loadProfile() => _profileRepository.fetchProfile();

  Future<void> startPurchase() async {
    _isBusy = true;
    _message =
        'Purchase verification is scaffolded for the verify-purchase Edge Function and store setup.';
    notifyListeners();
    _isBusy = false;
    notifyListeners();
  }
}
