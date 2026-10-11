import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'sync_backend.dart';
import 'sync_snapshot.dart';

const driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';

/// Hands the Drive backend an access token. Split out so tests can supply one
/// without Google Play services.
abstract class DriveAuth {
  /// Whether this build has what Google sign-in needs, else why not.
  String? get unavailableReason;

  /// Signs the user in (showing UI if needed) and authorises Drive's hidden
  /// app folder.
  Future<void> signIn();

  /// A token for the signed-in user. Throws [SyncException] when signed out.
  Future<String> accessToken();

  /// Drops [token] after Drive rejected it, so the next call gets a fresh one.
  Future<void> invalidate(String token);

  Future<void> signOut();
}

/// Google sign-in on Android. The web client id comes from the build:
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` (see docs/SYNC.md).
class GoogleDriveAuth implements DriveAuth {
  GoogleDriveAuth({String? serverClientId})
    : _serverClientId =
          serverClientId ?? const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final String _serverClientId;
  GoogleSignInAccount? _account;
  Future<void>? _init;

  @override
  String? get unavailableReason => _serverClientId.isEmpty
      ? 'This build has no Google sign-in set up. See docs/SYNC.md.'
      : null;

  Future<void> _ready() => _init ??= GoogleSignIn.instance.initialize(
    serverClientId: _serverClientId,
  );

  @override
  Future<void> signIn() async {
    await _ready();
    try {
      _account = await GoogleSignIn.instance.authenticate(
        scopeHint: const [driveAppDataScope],
      );
      await _account!.authorizationClient.authorizeScopes(const [
        driveAppDataScope,
      ]);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SyncException('Sign-in was cancelled.');
      }
      throw SyncException('Google sign-in failed: ${e.description ?? e.code.name}');
    }
  }

  /// Finds the account again after a restart, without showing UI.
  Future<GoogleSignInAccount?> _signedIn() async {
    if (_account != null) return _account;
    await _ready();
    return _account = await GoogleSignIn.instance
        .attemptLightweightAuthentication();
  }

  @override
  Future<String> accessToken() async {
    final account = await _signedIn();
    if (account == null) {
      throw const SyncException('Signed out of Google. Turn sync on again.');
    }
    final authz = await account.authorizationClient.authorizationForScopes(
      const [driveAppDataScope],
    );
    if (authz == null) {
      throw const SyncException(
        'Google needs you to approve access again. Turn sync off and on.',
      );
    }
    return authz.accessToken;
  }

  @override
  Future<void> invalidate(String token) async {
    final account = _account;
    if (account == null) return;
    await account.authorizationClient.clearAuthorizationToken(
      accessToken: token,
    );
  }

  @override
  Future<void> signOut() async {
    await _ready();
    _account = null;
    await GoogleSignIn.instance.signOut();
  }
}

/// One JSON file in the app's hidden folder of the user's Google Drive. The
/// app can see only files it made there, never the rest of Drive.
class DriveSyncBackend implements SyncBackend {
  DriveSyncBackend({required this.auth, required this.client});

  final DriveAuth auth;
  final http.Client client;

  static const fileName = 'wellbite-sync.json';
  static const _api = 'https://www.googleapis.com/drive/v3';
  static const _upload = 'https://www.googleapis.com/upload/drive/v3';

  @override
  String get label => 'Google Drive';

  @override
  String? get unavailableReason => auth.unavailableReason;

  @override
  Future<void> connect() => auth.signIn();

  @override
  Future<void> signOut() => auth.signOut();

  /// Sends a request with a fresh token, retrying once if Drive rejects it.
  Future<http.Response> _send(
    String method,
    Uri url, {
    Map<String, String> headers = const {},
    Object? body,
  }) async {
    for (var attempt = 0; ; attempt++) {
      final token = await auth.accessToken();
      final request = http.Request(method, url)
        ..headers.addAll({'Authorization': 'Bearer $token', ...headers});
      if (body is String) request.bodyBytes = utf8.encode(body);
      final http.Response response;
      try {
        response = await http.Response.fromStream(await client.send(request));
      } on Exception catch (e) {
        throw SyncException('Could not reach Google Drive: $e');
      }
      if (response.statusCode == 401 && attempt == 0) {
        await auth.invalidate(token);
        continue;
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw SyncException(_explain(response));
    }
  }

  String _explain(http.Response r) {
    String? reason;
    try {
      final error = (jsonDecode(r.body) as Map)['error'] as Map?;
      reason = error?['message'] as String?;
    } on Object {
      reason = null;
    }
    return switch (r.statusCode) {
      401 => 'Google rejected the sign-in. Turn sync off and on again.',
      403 =>
        'Google Drive refused access${reason == null ? '' : ': $reason'}. '
            'Check that the Drive API is enabled for this app.',
      >= 500 => 'Google Drive is having trouble. Try again later.',
      _ => 'Google Drive error ${r.statusCode}${reason == null ? '' : ': $reason'}',
    };
  }

  /// The sync file's id and version, or null if it does not exist yet. If two
  /// devices created one at once, the oldest wins.
  Future<({String id, String version})?> _find() async {
    final response = await _send(
      'GET',
      Uri.parse('$_api/files').replace(
        queryParameters: {
          'spaces': 'appDataFolder',
          'q': "name = '$fileName' and trashed = false",
          'orderBy': 'createdTime',
          'fields': 'files(id,version)',
        },
      ),
    );
    final files = (jsonDecode(response.body)['files'] as List?) ?? const [];
    if (files.isEmpty) return null;
    final f = files.first as Map;
    return (id: f['id'] as String, version: '${f['version']}');
  }

  @override
  Future<RemoteDoc?> read() async {
    final file = await _find();
    if (file == null) return null;
    final response = await _send(
      'GET',
      Uri.parse('$_api/files/${file.id}').replace(
        queryParameters: {'alt': 'media'},
      ),
    );
    return RemoteDoc(utf8.decode(response.bodyBytes), file.version);
  }

  @override
  Future<void> write(String text, {String? ifVersion}) async {
    // Drive has no "only if unchanged" upload, so check just before. A write
    // can still slip into the gap; the next sync of that device repairs it.
    final file = await _find();
    if (file?.version != ifVersion) throw const SyncConflict();
    if (file == null) {
      const boundary = 'wellbite-sync-boundary';
      await _send(
        'POST',
        Uri.parse('$_upload/files').replace(
          queryParameters: {'uploadType': 'multipart', 'fields': 'id'},
        ),
        headers: {'Content-Type': 'multipart/related; boundary=$boundary'},
        body:
            '--$boundary\r\n'
            'Content-Type: application/json; charset=UTF-8\r\n\r\n'
            '${jsonEncode({
              'name': fileName,
              'parents': ['appDataFolder'],
            })}\r\n'
            '--$boundary\r\n'
            'Content-Type: application/json; charset=UTF-8\r\n\r\n'
            '$text\r\n'
            '--$boundary--',
      );
    } else {
      await _send(
        'PATCH',
        Uri.parse('$_upload/files/${file.id}').replace(
          queryParameters: {'uploadType': 'media', 'fields': 'id'},
        ),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: text,
      );
    }
  }
}
