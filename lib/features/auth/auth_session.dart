import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

final authSession = AuthSession();

class AuthError implements Exception {
  const AuthError(this.message, [this.status]);
  final String message;
  final int? status;
}

bool validAuthPassword(String password) {
  final length = utf8.encode(password).length;
  return length >= 12 && length <= 128;
}

class AuthSession extends ChangeNotifier {
  AuthSession({http.Client? client, FlutterSecureStorage? storage, Uri? base})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage(),
      _base = base ?? Uri.parse(const String.fromEnvironment('HIGO_API_URL'));

  static const _key = 'higo.auth.refresh.v1';
  final http.Client _client;
  final FlutterSecureStorage _storage;
  final Uri _base;
  String? _access;
  String? _refresh;
  Future<void>? _refreshing;
  Future<void>? _loggingOut;
  Future<void> _sessionChanges = Future.value();
  int _signInAttempt = 0;
  Map<String, dynamic>? user;
  bool get authenticated => user != null;

  Future<Map<String, dynamic>> request(
    String path, {
    Map<String, String>? body,
    String? bearer,
    String method = 'POST',
  }) async {
    final loopback = [
      '127.0.0.1',
      'localhost',
      '10.0.2.2',
    ].contains(_base.host);
    if (!_base.hasAuthority ||
        (_base.scheme != 'https' &&
            !(kDebugMode && loopback && _base.scheme == 'http'))) {
      throw const AuthError('Configure a valid HiGO API URL.');
    }
    final request = http.Request(method, _base.resolve('/api/v1/$path'))
      ..followRedirects = false;
    if (bearer != null) request.headers['Authorization'] = 'Bearer $bearer';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const AuthError('Could not connect to HiGO. Try again.');
    }
    if (response.statusCode == 204) return {};
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const AuthError('HiGO returned an unexpected response.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return payload;
    final message = switch (payload['error']) {
      'invalid_credentials' => 'Invalid phone number or password.',
      'invalid_or_expired_code' => 'The code is invalid or expired.',
      'invalid_or_expired_recovery_token' =>
        'The reset expired. Request a new code.',
      'rate_limited' => 'Too many attempts. Please wait and try again.',
      'invalid_request' => 'Check the details and try again.',
      _ => 'HiGO could not complete the request. Try again.',
    };
    throw AuthError(message, response.statusCode);
  }

  Future<void> signIn(Map<String, dynamic> tokens) async {
    final attempt = ++_signInAttempt;
    final profile = await request(
      'me',
      bearer: tokens['access_token'] as String,
      method: 'GET',
    );
    await _changeSession(() async {
      if (attempt != _signInAttempt) return;
      await _save(tokens);
      user = profile;
      notifyListeners();
    });
  }

  Future<void> _changeSession(Future<void> Function() change) {
    final pending = _sessionChanges.then((_) => change());
    _sessionChanges = pending.then<void>((_) {}, onError: (Object _) {});
    return pending;
  }

  Future<void> _save(Map<String, dynamic> tokens) async {
    final refresh = tokens['refresh_token'] as String;
    await _storage.write(key: _key, value: refresh);
    _access = tokens['access_token'] as String;
    _refresh = refresh;
  }

  Future<void> restore() async {
    _refresh ??= await _storage.read(key: _key);
    if (_refresh == null) return;
    try {
      user = await currentUser();
      notifyListeners();
    } on AuthError catch (error) {
      if (error.status != 401) rethrow;
    }
  }

  Future<void> _rotate() async {
    if (_refresh == null) throw const AuthError('Please log in again.', 401);
    try {
      await _save(
        await request('auth/refresh', body: {'refresh_token': _refresh!}),
      );
    } on AuthError catch (error) {
      if (error.status == 401) await _clear();
      rethrow;
    }
  }

  Future<void> _ensureAccess() async {
    await (_refreshing ??= _rotate().whenComplete(() => _refreshing = null));
  }

  Future<Map<String, dynamic>> currentUser() => _requestCurrentUser();

  Future<Map<String, dynamic>> _requestCurrentUser({
    Map<String, String>? update,
    String path = 'me',
    String? method,
  }) async {
    Future<Map<String, dynamic>> send(String? token) => request(
      path,
      method: method ?? (update == null ? 'GET' : 'PATCH'),
      bearer: token,
      body: update,
    );
    if (_access == null) await _ensureAccess();
    final access = _access;
    try {
      return await send(access);
    } on AuthError catch (error) {
      if (error.status != 401) rethrow;
      if (_access == access) await _ensureAccess();
      return send(_access);
    }
  }

  Future<void> updateProfile({String? name, String? email}) {
    final fields = {'name': ?name, 'email': ?email};
    if (fields.isEmpty) return Future.value();
    final accountId = user?['id'];
    return _changeSession(() async {
      if (accountId == null || user?['id'] != accountId) {
        throw const AuthError('Please log in again.', 401);
      }
      user = await _requestCurrentUser(update: fields);
      notifyListeners();
    });
  }

  Future<void> requestEmailVerification(String email, String password) =>
      _emailAction('me/email/request', {'email': email, 'password': password});

  Future<void> verifyEmail(String code) =>
      _emailAction('me/email/verify', {'code': code});

  Future<void> _emailAction(String path, Map<String, String> body) {
    final accountId = user?['id'];
    return _changeSession(() async {
      if (accountId == null || user?['id'] != accountId) {
        throw const AuthError('Please log in again.', 401);
      }
      await _requestCurrentUser(update: body, path: path, method: 'POST');
      user = await currentUser();
      notifyListeners();
    });
  }

  Future<void> logout() => _loggingOut ??= _changeSession(
    _logout,
  ).whenComplete(() => _loggingOut = null);

  Future<void> _logout() async {
    try {
      await request('auth/logout', bearer: _access);
    } on AuthError catch (error) {
      if (error.status != 401) rethrow;
      try {
        await _ensureAccess();
        await request('auth/logout', bearer: _access);
      } on AuthError catch (refreshError) {
        if (refreshError.status != 401) rethrow;
      }
    }
    await _clear();
  }

  Future<void> _clear() async {
    await _storage.delete(key: _key);
    _access = null;
    _refresh = null;
    user = null;
    notifyListeners();
  }
}

String authErrorMessage(Object error) => error is AuthError
    ? error.message
    : 'HiGO could not complete the request. Try again.';
