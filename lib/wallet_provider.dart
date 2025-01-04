import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WalletProvider extends ChangeNotifier {
  // ----------------------------------------
  // 1) مفاتيحنا القديمة
  // ----------------------------------------
  static const String bip44 = 'BIP44';
  static const String bip49 = 'BIP49';
  static const String bip84 = 'BIP84';

  // الوضع الافتراضي: bip44
  String _preferredBipType = bip44;
  String get preferredBipType => _preferredBipType;

  void setPreferredBipType(String newType) {
    _preferredBipType = newType;
    notifyListeners();
  }

  // ----------------------------------------
  // 2) الوحدة الحالية (BTC أو SAT)
  // ----------------------------------------
  String _currentUnit = "BTC";
  String get currentUnit => _currentUnit;

  void setUnit(String newUnit) {
    _currentUnit = newUnit; // "BTC" or "SAT"
    notifyListeners();
  }

  // ----------------------------------------
  // 3) بيانات المحفظة من الـ API
  // ----------------------------------------
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// سنخزّن كامل الـ JSON القادم من السيرفر (داخل result)
  Map<String, dynamic>? _walletData;
  Map<String, dynamic>? get walletData => _walletData;

  /// بالإضافة إلى مفاتيح أخرى قد ترغب بعرضها مثل:
  String? _apiStatus;
  String? get apiStatus => _apiStatus;

  String? _apiMessage;
  String? get apiMessage => _apiMessage;

  String? _apiTimestamp;
  String? get apiTimestamp => _apiTimestamp;

  /// استدعاء الدالة لجلب البيانات من الـ API
  Future<void> fetchWalletData({
    required String mnemonic,
    String passphrase = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // تعديل عنوان الـ API إلى:
      final uri = Uri.parse('https://generate-wallet.vercel.app/api/index');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "mnemonic": mnemonic,
          // لو أنّ الـ API يستقبل passphrase = null عند عدم وجودها:
          "passphrase": passphrase.isEmpty ? null : passphrase,
        }),
      );

      if (response.statusCode == 200) {
        // تحويل الـ body إلى JSON
        final jsonResp = json.decode(response.body);

        // نلتقط مفاتيح عامة (status, message, timestamp)
        _apiStatus = jsonResp['status'];
        _apiMessage = jsonResp['message'];
        _apiTimestamp = jsonResp['timestamp'];

        // البيانات الأساسية موجودة أسفل المفتاح "result"
        _walletData = jsonResp['result'];
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching wallet data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ----------------------------------------
  // 4) دوال الرصيد (حسب المسار)
  // ----------------------------------------
  /// مابين "bip44" → "bip44_legacy"
  ///        "bip49" → "bip49_nested"
  ///        "bip84" → "bip84_native"
  final Map<String, String> _bipTypeMapping = {
    bip44: 'bip44_legacy',
    bip49: 'bip49_nested',
    bip84: 'bip84_native',
  };

  /// إن أردت الرصيد لمسار معيّن حسب _preferredBipType
  /// نجمع رصيد العناوين used + fresh لـ (receive + change)
  int getBalanceInSatoshi(String bipType) {
    // إن لم تكن البيانات جاهزة، نعيد 0
    if (_walletData == null) return 0;

    // نصل إلى: _walletData?['data']?['bip44_legacy'] مثلًا
    final mappedKey = _bipTypeMapping[bipType];
    final dataObj = _walletData?['data']?[mappedKey];
    if (dataObj == null) return 0;

    int totalSat = 0;

    // ----- receive -----
    final receive = dataObj['receive'];
    if (receive is Map) {
      // used[]
      final usedArr = receive['used'];
      if (usedArr is List) {
        for (var addr in usedArr) {
          final bal = addr['totalBalance'];
          if (bal is int) totalSat += bal;
        }
      }
      // fresh{}
      final fresh = receive['fresh'];
      if (fresh is Map) {
        final bal = fresh['totalBalance'];
        if (bal is int) totalSat += bal;
      }
    }

    // ----- change -----
    final change = dataObj['change'];
    if (change is Map) {
      // used[]
      final usedArr = change['used'];
      if (usedArr is List) {
        for (var addr in usedArr) {
          final bal = addr['totalBalance'];
          if (bal is int) totalSat += bal;
        }
      }
      // fresh{}
      final fresh = change['fresh'];
      if (fresh is Map) {
        final bal = fresh['totalBalance'];
        if (bal is int) totalSat += bal;
      }
    }

    return totalSat;
  }

  double getBalanceInBTC(String bipType) {
    final satoshi = getBalanceInSatoshi(bipType);
    return satoshi / 100000000.0;
  }

  /// عرض جاهز: "0.00001960 BTC" أو "1960 SATS"
  String getDisplayBalance(String bipType) {
    if (_walletData == null) {
      return _currentUnit == "BTC" ? "0.00000000 BTC" : "0 SATS";
    }

    if (_currentUnit == "BTC") {
      final btcValue = getBalanceInBTC(bipType);
      // نعرض 8 خانات عشرية
      return "${btcValue.toStringAsFixed(8)} BTC";
    } else {
      final satValue = getBalanceInSatoshi(bipType);
      return "$satValue SATS";
    }
  }

  // ----------------------------------------
  // 5) بعض الدوال المساعدة (مثال fresh address)
  // ----------------------------------------
  /// يمكن تطوير هذه الدالة لاحقاً إن أردت عرض grandTotals أو غيره
  Map<String, dynamic>? get currentBipStats => null;

  /// عنوان الاستقبال الحالي للمسار المفضّل
  String? get currentFreshAddress {
    if (_walletData == null) return null;

    final mappedKey = _bipTypeMapping[_preferredBipType];
    final dataObj = _walletData?['data']?[mappedKey];
    if (dataObj == null) return null;

    final freshAddr = dataObj['receive']?['fresh']?['address'];
    if (freshAddr is String) return freshAddr;
    return null;
  }
}
