import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ข้อผิดพลาดจาก backend ที่มีข้อความภาษาไทยพร้อมแสดงให้ผู้ใช้
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// ข้อมูลผู้ใช้ที่เข้าสู่ระบบอยู่
class Session {
  final String username;
  final String fullName;
  final String? div;

  /// ชื่อหน่วยงานของ [div]
  final String? divName;
  final List<String> roles;
  final bool mustChangePassword;

  const Session({
    required this.username,
    required this.fullName,
    required this.div,
    required this.divName,
    required this.roles,
    required this.mustChangePassword,
  });

  factory Session.fromJson(Map<String, dynamic> j) => Session(
    username: (j['username'] ?? '') as String,
    fullName: (j['full_name'] ?? j['username'] ?? '') as String,
    div: j['div'] as String?,
    divName: j['div_name'] as String?,
    roles: [for (final r in (j['roles'] as List? ?? const [])) r.toString()],
    mustChangePassword: j['must_change_password'] == true,
  );

  Map<String, dynamic> toJson() => {
    'username': username,
    'full_name': fullName,
    'div': div,
    'div_name': divName,
    'roles': roles,
    'must_change_password': mustChangePassword,
  };

  Session copyWith({bool? mustChangePassword}) => Session(
    username: username,
    fullName: fullName,
    div: div,
    divName: divName,
    roles: roles,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );
}

/// เรียก backend งานเงินเดือน (Spring Boot `salary`) — แบบเดียวกับ ApiService ของ HTC
///
/// URL ของ API เลือกตอน run/build ด้วย `--dart-define=API_BASE=...`
///   ไม่ส่งมา = production `https://infdoh.doh.go.th/salapi`
class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://infdoh.doh.go.th/salapi',
  );

  static const String _accessKey = 'sal_access_token';
  static const String _refreshKey = 'sal_refresh_token';
  static const String _sessionKey = 'sal_session';

  final SharedPreferences prefs;
  final Dio dio;

  /// เรียกเมื่อ session หมดอายุและต่ออายุไม่ได้ (ถูกบังคับออกจากระบบ)
  void Function()? onSessionExpired;

  Session? _session;
  Session? get session => _session;

  /// มีการต่ออายุ token ค้างอยู่ คำขออื่นที่ได้ 401 พร้อมกันรอผลอันเดียวกัน
  Future<void>? _refreshing;

  ApiService(this.prefs, {Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Content-Type': 'application/json'},
            ),
          ) {
    final raw = prefs.getString(_sessionKey);
    if (raw != null && prefs.getString(_accessKey) != null) {
      try {
        _session = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _clear();
      }
    }
    this.dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  static bool _isAuthPath(String path) =>
      path.contains('/api/auth/login') ||
      path.contains('/api/auth/refresh-token') ||
      path.contains('/api/auth/logout');

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = prefs.getString(_accessKey);
    if (token != null && !options.path.contains('/api/auth/login')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// 401 = access token หมดอายุ ต่ออายุแล้วลองใหม่หนึ่งครั้ง
  /// (403 = ไม่มีสิทธิ์จริง ไม่ต้องต่ออายุ — ต่างจาก HTC ที่ backend ตอบ 403 ปนกัน)
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final retried = options.extra['retried'] == true;
    if (err.response?.statusCode != 401 ||
        _isAuthPath(options.path) ||
        retried ||
        prefs.getString(_refreshKey) == null) {
      return handler.next(err);
    }
    try {
      await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
      options.extra['retried'] = true;
      handler.resolve(await dio.fetch(options));
    } catch (_) {
      _clear();
      onSessionExpired?.call();
      handler.next(err);
    }
  }

  Future<void> _refresh() async {
    final res = await dio.post(
      '/api/auth/refresh-token',
      data: {'refresh_token': prefs.getString(_refreshKey)},
    );
    await prefs.setString(_accessKey, res.data['access_token'] as String);
    await prefs.setString(_refreshKey, res.data['refresh_token'] as String);
  }

  void _clear() {
    _session = null;
    prefs.remove(_accessKey);
    prefs.remove(_refreshKey);
    prefs.remove(_sessionKey);
  }

  Future<void> _saveSession(Session s) async {
    _session = s;
    await prefs.setString(_sessionKey, jsonEncode(s.toJson()));
  }

  /// แปลงข้อผิดพลาดเป็นข้อความที่แสดงให้ผู้ใช้ได้
  static ApiException _wrap(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return ApiException(
          data['message'] as String,
          statusCode: e.response?.statusCode,
        );
      }
      if (e.response == null) {
        return const ApiException(
          'เชื่อมต่อระบบไม่ได้ กรุณาตรวจสอบเครือข่ายแล้วลองใหม่',
        );
      }
      return ApiException(
        'เกิดข้อผิดพลาด (${e.response?.statusCode})',
        statusCode: e.response?.statusCode,
      );
    }
    return const ApiException('เกิดข้อผิดพลาด กรุณาลองใหม่');
  }

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw _wrap(e);
    }
  }

  // ---------------- เข้าสู่ระบบ ----------------

  Future<Session> login(String username, String password) => _call(() async {
    final res = await dio.post(
      '/api/auth/login',
      data: {'username': username, 'password': password},
    );
    final data = res.data as Map<String, dynamic>;
    await prefs.setString(_accessKey, data['access_token'] as String);
    await prefs.setString(_refreshKey, data['refresh_token'] as String);
    final s = Session.fromJson(data);
    await _saveSession(s);
    return s;
  });

  /// อ่านข้อมูลผู้ใช้ล่าสุดจาก backend (ชื่อ หน่วยงาน บทบาท) มาแทนค่าที่จำไว้ในเบราว์เซอร์
  /// ใช้ตอนเปิดหน้าเว็บใหม่ทั้งที่ยังเข้าสู่ระบบค้างอยู่ คืน true เมื่อข้อมูลเปลี่ยน
  Future<bool> refreshSession() async {
    if (_session == null) return false;
    try {
      final res = await dio.get('/api/auth/me');
      final data = res.data;
      if (data is! Map || data['username'] == null || _session == null) {
        return false;
      }
      final before = jsonEncode(_session!.toJson());
      final s = Session.fromJson(Map<String, dynamic>.from(data));
      await _saveSession(s);
      return jsonEncode(s.toJson()) != before;
    } catch (_) {
      return false; // เครือข่ายล่มก็ใช้ค่าที่จำไว้ต่อ; session หมดอายุ onSessionExpired จัดการเอง
    }
  }

  Future<void> logout() async {
    final refresh = prefs.getString(_refreshKey);
    try {
      await dio.post('/api/auth/logout', data: {'refresh_token': refresh});
    } catch (_) {
      // ออกจากระบบฝั่งหน้าเว็บให้ได้เสมอ แม้ backend ไม่ตอบ
    }
    _clear();
  }

  Future<String> changePassword(String oldPassword, String newPassword) =>
      _call(() async {
        final res = await dio.post(
          '/api/auth/changepassword',
          data: {'oldPassword': oldPassword, 'newPassword': newPassword},
        );
        final s = _session;
        if (s != null) {
          await _saveSession(s.copyWith(mustChangePassword: false));
        }
        return (res.data['message'] ?? 'เปลี่ยนรหัสผ่านสำเร็จ') as String;
      });

  // ---------------- จัดการผู้ใช้ (ADMIN) ----------------

  Future<Map<String, dynamic>> searchUsers({
    String? keyword,
    int page = 0,
    int size = 10,
  }) => _call(() async {
    final res = await dio.get(
      '/api/admin/users',
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
        'page': page,
        'size': size,
      },
    );
    return res.data as Map<String, dynamic>;
  });

  Future<void> createUser(Map<String, dynamic> body) =>
      _call(() => dio.post('/api/admin/users', data: body));

  Future<void> updateUser(String id, Map<String, dynamic> body) =>
      _call(() => dio.put('/api/admin/users/$id', data: body));

  Future<String> resetPassword(String id, String newPassword) =>
      _call(() async {
        final res = await dio.post(
          '/api/admin/users/$id/reset-password',
          data: {'newPassword': newPassword},
        );
        return (res.data['message'] ?? 'ตั้งรหัสผ่านใหม่สำเร็จ') as String;
      });

  /// รายชื่อหน่วยงาน [{div, divname}] ใช้ทำตัวเลือกในฟอร์มผู้ใช้ และให้ ADMIN/UPLOAD เลือกหน่วยงานในหน้าดาวน์โหลด
  Future<List<Map<String, String>>> divs() => _call(() async {
    final res = await dio.get('/api/download/divs');
    return [
      for (final d in res.data as List)
        {
          'div': (d['div'] ?? '').toString(),
          'divname': (d['divname'] ?? '').toString(),
        },
    ];
  });

  // ---------------- ไฟล์เงินเดือน ----------------

  /// อัปโหลด/ตัดไฟล์ใช้เวลานานกว่าคำขอทั่วไป
  static final Options _slow = Options(
    sendTimeout: const Duration(minutes: 5),
    receiveTimeout: const Duration(minutes: 5),
  );

  static FormData _form(
    String name,
    Uint8List bytes,
    Map<String, dynamic> fields,
  ) => FormData.fromMap({
    ...fields,
    'file': MultipartFile.fromBytes(bytes, filename: name),
  });

  /// ชุดที่ยังมีผลของเดือนนี้ (รอเผยแพร่ + เผยแพร่อยู่)
  Future<List<Map<String, dynamic>>> payrollUploads(int year, int month) =>
      _call(() async {
        final res = await dio.get(
          '/api/upload/payroll',
          queryParameters: {'year': year, 'month': month},
        );
        return [for (final u in res.data as List) Map<String, dynamic>.from(u)];
      });

  /// อัปโหลด PDF รวมทุกหน่วยงาน ระบบตรวจแล้วตัดเป็นไฟล์รายหน่วยงาน (ยังไม่เผยแพร่)
  Future<Map<String, dynamic>> uploadPayroll({
    required String name,
    required Uint8List bytes,
    required int year,
    required int month,
    required String type,
    void Function(int sent, int total)? onProgress,
  }) => _call(() async {
    final res = await dio.post(
      '/api/upload/payroll',
      data: _form(name, bytes, {'year': year, 'month': month, 'type': type}),
      options: _slow,
      onSendProgress: onProgress,
    );
    return Map<String, dynamic>.from(res.data as Map);
  });

  Future<Map<String, dynamic>> _payrollAction(String method, String path) =>
      _call(() async {
        final res = await dio.request(path, options: Options(method: method));
        return Map<String, dynamic>.from(res.data as Map);
      });

  Future<Map<String, dynamic>> publishPayroll(String id) =>
      _payrollAction('POST', '/api/upload/payroll/$id/publish');

  Future<Map<String, dynamic>> cancelPayroll(String id) =>
      _payrollAction('POST', '/api/upload/payroll/$id/cancel');

  Future<Map<String, dynamic>> deletePayrollSource(String id) =>
      _payrollAction('DELETE', '/api/upload/payroll/$id/source');

  Future<List<Map<String, dynamic>>> commonFiles(int year, int month) =>
      _call(() async {
        final res = await dio.get(
          '/api/upload/common',
          queryParameters: {'year': year, 'month': month},
        );
        return [for (final f in res.data as List) Map<String, dynamic>.from(f)];
      });

  /// อัปโหลดไฟล์ประกอบ ชื่อซ้ำได้ [ApiException] statusCode 409 — ถามผู้ใช้แล้วเรียกใหม่ด้วย [overwrite]
  Future<void> uploadCommon({
    required String name,
    required Uint8List bytes,
    required int year,
    required int month,
    bool overwrite = false,
  }) => _call(
    () => dio.post(
      '/api/upload/common',
      data: _form(name, bytes, {
        'year': year,
        'month': month,
        'overwrite': overwrite,
      }),
      options: _slow,
    ),
  );

  Future<void> deleteCommon(int year, int month, String name) => _call(
    () => dio.delete(
      '/api/upload/common',
      queryParameters: {'year': year, 'month': month, 'name': name},
    ),
  );

  /// ไฟล์ของหน่วยงานผู้ใช้ในเดือนที่เลือก + ไฟล์ประกอบ
  /// [div] = ดูหน่วยงานอื่น, [all] = ทุกหน่วยงาน (ทั้งสองใช้ได้เฉพาะ ADMIN/UPLOAD)
  Future<Map<String, dynamic>> downloadFiles(
    int year,
    int month, {
    String? div,
    bool all = false,
  }) => _call(() async {
    final res = await dio.get(
      '/api/download/files',
      queryParameters: {
        'year': year,
        'month': month,
        'div': ?div,
        if (all) 'all': true,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  });

  /// ดึงเนื้อไฟล์จาก [path] (แนบ token ให้เอง) ใช้กับทุกลิงก์ดาวน์โหลด
  Future<Uint8List> fetchFile(String path, [Map<String, dynamic>? query]) =>
      _call(() async {
        try {
          final res = await dio.get<List<int>>(
            path,
            queryParameters: query,
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(minutes: 5),
            ),
          );
          return Uint8List.fromList(res.data ?? const []);
        } on DioException catch (e) {
          // ขอเป็น bytes ข้อความผิดพลาดจึงมาเป็น bytes ด้วย แปลงกลับเป็น JSON ให้ _wrap อ่านข้อความได้
          final data = e.response?.data;
          if (data is List<int>) {
            try {
              e.response!.data = jsonDecode(utf8.decode(data));
            } catch (_) {}
          }
          rethrow;
        }
      });

  /// เดือนที่มีไฟล์ให้ดาวน์โหลด ใหม่สุดก่อน [{year, month}]
  /// [div] / [all] ใช้ได้เฉพาะ ADMIN/UPLOAD ผู้ใช้ทั่วไปได้ของหน่วยงานตัวเอง
  Future<List<({int year, int month})>> downloadPeriods({
    String? div,
    bool all = false,
  }) => _call(() async {
    final res = await dio.get(
      '/api/download/periods',
      queryParameters: {'div': ?div, if (all) 'all': true},
    );
    return [
      for (final p in res.data as List)
        (year: p['year'] as int, month: p['month'] as int),
    ];
  });

  /// หน่วยงานไหนดาวน์โหลดไฟล์ของเดือนนี้แล้ว/ยัง (UPLOAD/ADMIN)
  Future<Map<String, dynamic>> downloadStatus(int year, int month) =>
      _call(() async {
        final res = await dio.get(
          '/api/upload/download-status',
          queryParameters: {'year': year, 'month': month},
        );
        return Map<String, dynamic>.from(res.data as Map);
      });

  /// ประวัติการใช้งาน (UPLOAD/ADMIN) [kind] = downloads | payroll | common
  Future<Map<String, dynamic>> history(
    String kind, {
    String? keyword,
    int page = 0,
    int size = 10,
  }) => _call(() async {
    final res = await dio.get(
      '/api/upload/history/$kind',
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
        'page': page,
        'size': size,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  });
}
