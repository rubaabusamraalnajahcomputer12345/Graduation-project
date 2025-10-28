// ignore_for_file: avoid_print

import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/UserProvider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/material.dart';

class AuthUtils {
  /// Check if the JWT token is expired
  static bool isTokenExpired(String token) {
    try {
      final isExpired = JwtDecoder.isExpired(token);
      return isExpired;
    } catch (e) {
      return true; // Consider invalid tokens as expired
    }
  }

  /// Get token expiration date
  static DateTime? getTokenExpirationDate(String token) {
    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      print('Error getting token expiration date: $e');
      return null;
    }
  }

  /// Check token and logout if expired
  static Future<bool> checkTokenAndLogoutIfExpired(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        // No token found, user should be logged out
        await logout(context);
        return true; // Token was invalid/expired
      }

      if (isTokenExpired(token)) {
        await logout(context);
        return true; // Token was expired
      }

      return false; // Token is valid
    } catch (e) {
      await logout(context);
      return true; // Error occurred, logout for safety
    }
  }

  /// Check token before making API requests
  static Future<String?> getValidToken(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      

      if (token == null || token.isEmpty) {
        await logout(context);
        return null;
      }

      if (isTokenExpired(token)) {
        await logout(context);
        return null;
      }

      return token;
    } catch (e) {
      await logout(context);
      return null;
    }
  }

  /// Get valid token from preferences without context (for service calls)
  static Future<String?> getValidTokenFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        return null;
      }

      if (isTokenExpired(token)) {
        return null;
      }

      return token;
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout(context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // Remove user data from provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.logout();

  }
}
