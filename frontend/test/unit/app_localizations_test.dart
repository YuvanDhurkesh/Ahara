import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

void main() {
  group('AppLocalizations - translate', () {
    test('should return English translations for en locale', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.translate('welcome'), 'Welcome back');
      expect(l10n.translate('login'), 'Login');
      expect(l10n.translate('register'), 'Create New Account');
      expect(l10n.translate('home'), 'Home');
      expect(l10n.translate('orders'), 'Orders');
    });

    test('should return Hindi translations for hi locale', () {
      final l10n = AppLocalizations(const Locale('hi'));
      expect(l10n.translate('welcome'), isNotEmpty);
      expect(l10n.translate('login'), isNotEmpty);
    });

    test('should return Tamil translations for ta locale', () {
      final l10n = AppLocalizations(const Locale('ta'));
      expect(l10n.translate('welcome'), isNotEmpty);
      expect(l10n.translate('login'), isNotEmpty);
    });

    test('should return Telugu translations for te locale', () {
      final l10n = AppLocalizations(const Locale('te'));
      expect(l10n.translate('welcome'), isNotEmpty);
      expect(l10n.translate('login'), isNotEmpty);
    });

    test('should return the key itself for unknown keys in en locale', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.translate('nonexistent_key_xyz'), 'nonexistent_key_xyz');
    });

    test('should return key as fallback for unsupported locale', () {
      final l10n = AppLocalizations(const Locale('fr'));
      expect(l10n.translate('welcome'), 'welcome');
    });

    test('should translate common UI keys correctly', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.translate('profile'), 'Profile');
      expect(l10n.translate('settings'), 'Settings');
      expect(l10n.translate('logout'), 'Logout');
      expect(l10n.translate('cancel'), 'Cancel');
      expect(l10n.translate('error'), 'Error');
    });

    test('should translate seller-related keys', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.translate('seller_dashboard'), 'Seller Dashboard');
      expect(l10n.translate('active_listings'), 'Active Listings');
      expect(l10n.translate('pending_orders'), 'Pending Orders');
    });

    test('should translate buyer-related keys', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.translate('discover'), 'Discover');
      expect(l10n.translate('browse'), 'Browse');
      expect(l10n.translate('favourites'), 'Favourites');
    });

    test('should translate volunteer-related keys', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.translate('deliveries'), 'Deliveries');
      expect(l10n.translate('verification'), 'Verification');
    });
  });

  group('AppLocalizationsDelegate', () {
    test('should support en, hi, ta, te locales', () {
      const delegate = AppLocalizationsDelegate();
      expect(delegate.isSupported(const Locale('en')), true);
      expect(delegate.isSupported(const Locale('hi')), true);
      expect(delegate.isSupported(const Locale('ta')), true);
      expect(delegate.isSupported(const Locale('te')), true);
    });

    test('should not support unsupported locales', () {
      const delegate = AppLocalizationsDelegate();
      expect(delegate.isSupported(const Locale('fr')), false);
      expect(delegate.isSupported(const Locale('de')), false);
      expect(delegate.isSupported(const Locale('ja')), false);
    });

    test('shouldReload should return false', () {
      const delegate = AppLocalizationsDelegate();
      expect(delegate.shouldReload(delegate), false);
    });

    test('load should return AppLocalizations instance', () async {
      const delegate = AppLocalizationsDelegate();
      final l10n = await delegate.load(const Locale('en'));
      expect(l10n, isA<AppLocalizations>());
    });
  });
}
