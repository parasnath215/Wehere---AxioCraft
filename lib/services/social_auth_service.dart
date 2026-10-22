import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/constants/app_constants.dart';

class SocialCredential {
  final String provider; // 'google' | 'apple'
  final String idToken;
  final String? accessToken;
  final String? nonce;
  final String? email;
  final String? displayName;
  final String? givenName;
  final String? familyName;
  final String? photoUrl;
  final DateTime? suggestedDob;
  final String? suggestedPhone;

  SocialCredential({
    required this.provider,
    required this.idToken,
    this.accessToken,
    this.nonce,
    this.email,
    this.displayName,
    this.givenName,
    this.familyName,
    this.photoUrl,
    this.suggestedDob,
    this.suggestedPhone,
  });
}

class SocialAuthService {
  static Future<SocialCredential?> signInWithGoogle() async {
    if (AppConstants.googleServerClientId.isEmpty) {
      if (kDebugMode) {
        debugPrint('[Google Sign-In] GOOGLE_SERVER_CLIENT_ID is empty. Run with --dart-define=GOOGLE_SERVER_CLIENT_ID=...');
      }
    }

    final scopes = <String>[
      'email',
      'profile',
      if (AppConstants.googlePeopleApi) ...[
        'https://www.googleapis.com/auth/user.birthday.read',
        'https://www.googleapis.com/auth/user.phonenumbers.read',
      ],
    ];

    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: scopes,
      serverClientId: AppConstants.googleServerClientId.isNotEmpty
          ? AppConstants.googleServerClientId
          : null,
    );

    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) return null;

    final GoogleSignInAuthentication auth = await account.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Failed to obtain Google ID token');
    }

    DateTime? suggestedDob;
    String? suggestedPhone;

    if (AppConstants.googlePeopleApi && accessToken != null && accessToken.isNotEmpty) {
      try {
        final plainDio = Dio();
        final res = await plainDio.get(
          'https://people.googleapis.com/v1/people/me?personFields=birthdays,phoneNumbers',
          options: Options(
            headers: {'Authorization': 'Bearer $accessToken'},
          ),
        );
        if (res.statusCode == 200 && res.data is Map) {
          final birthdays = res.data['birthdays'] as List?;
          if (birthdays != null) {
            for (final b in birthdays) {
              final date = b['date'];
              if (date != null &&
                  date['year'] != null &&
                  date['month'] != null &&
                  date['day'] != null) {
                suggestedDob = DateTime(date['year'], date['month'], date['day']);
                break;
              }
            }
          }

          final phoneNumbers = res.data['phoneNumbers'] as List?;
          if (phoneNumbers != null) {
            for (final p in phoneNumbers) {
              final val = p['value']?.toString().trim();
              if (val != null && RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(val.replaceAll(' ', ''))) {
                suggestedPhone = val.replaceAll(' ', '');
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[People API error, silent fallback]: $e');
      }
    }

    return SocialCredential(
      provider: 'google',
      idToken: idToken,
      accessToken: accessToken,
      displayName: account.displayName,
      email: account.email,
      photoUrl: account.photoUrl,
      suggestedDob: suggestedDob,
      suggestedPhone: suggestedPhone,
    );
  }

  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static Future<SocialCredential?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Failed to obtain Apple identity token');
    }

    return SocialCredential(
      provider: 'apple',
      idToken: idToken,
      nonce: rawNonce,
      email: credential.email,
      givenName: credential.givenName,
      familyName: credential.familyName,
      displayName: [credential.givenName, credential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ')
          .trim(),
    );
  }
}
