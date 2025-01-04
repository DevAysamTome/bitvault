import 'dart:async'; // لإستخدام Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

// استبدل هذا بملفاتك الخاصة
import 'wallet_provider.dart';
import 'currency_rate_provider.dart';
import 'scan_qr_page.dart';
import 'write_address.dart';
import 'receive_page.dart';
import 'settings_page.dart';

// تأكد أنك تستورد الـ PopScope المناسب من الحزمة أو من الملف الذي عرّفته أنت.
// import 'package:my_package/pop_scope.dart'; // مثلاً

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // استدعاء أول مرة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currencyProv = context.read<CurrencyRateProvider>();
      currencyProv.fetchRate(currencySymbol: "USD");

      // إن كان لديك دالة تحديث في WalletProvider، استدعها أيضاً:
      // final walletProv = context.read<WalletProvider>();
      // walletProv.fetchWalletData(...);
      // أو أي دالة تريدها لتحديث بيانات WalletProvider.
    });

    // بعد ذلك نجعل المؤقّت يستدعي نفس الدوال كل 7 ثوانٍ
    _refreshTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      final currencyProv = context.read<CurrencyRateProvider>();
      currencyProv.fetchRate(currencySymbol: "USD");

      // نفس الشيء لعمل تحديث لـ WalletProvider إذا لزم
      // final walletProv = context.read<WalletProvider>();
      // walletProv.fetchWalletData(...);
    });
  }

  @override
  void dispose() {
    // إلغاء المؤقت عند الخروج لتجنّب الاستدعاء المستمر
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF1F4F8);

    final walletProvider = context.watch<WalletProvider>();
    final bipType = walletProvider.preferredBipType;

    // رصيد المستخدم بالـ BTC أو SAT
    final displayBalance = walletProvider.getDisplayBalance(bipType);
    final double btcBalance = walletProvider.getBalanceInBTC(bipType);

    // القراءة من CurrencyRateProvider
    final currencyRateProv = context.watch<CurrencyRateProvider>();
    final isLoadingFiat = currencyRateProv.isLoading;
    final rate = currencyRateProv.rate; // قد تكون null
    final fiatSymbol = currencyRateProv.fiatSymbol;

    // حساب قيمة المستخدم بالعملة الورقية
    double fiatValue = 0.0;
    if (rate != null) {
      fiatValue = btcBalance * rate;
    }

    return PopScope(
      // تعطيل الرجوع للخلف
      canPop: false,

      // استبدل onPopInvoked بـ onPopInvokedWithResult
      onPopInvokedWithResult: (didPop, route) {
        // لا نريد طباعة أي شيء
      },

      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: backgroundColor,
          elevation: 0,
          title: Row(
            children: [
              IconButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final scannedResult = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanQrPage()),
                  );
                  if (scannedResult != null && scannedResult.isNotEmpty) {
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WriteAddressPage(preFilledAddress: scannedResult),
                      ),
                    );
                  }
                },
                icon: SvgPicture.asset(
                  'assets/image/qr-reader-svgrepo-com.svg',
                  width: 34,
                  height: 34,
                  // ignore: deprecated_member_use
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // هنا يمكن ربط زر عرض المعاملات مثلاً
                },
                icon: const Icon(Icons.access_time, color: Colors.black),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
                icon: const Icon(Icons.settings, color: Colors.black),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // الرصيد BTC/SAT
                  const Text(
                    "WALLET BALANCE",
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayBalance,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // عرض قيمة الرصيد بالعملة الورقية
                  if (isLoadingFiat)
                    const Text(
                      "Fetching fiat rate...",
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    )
                  else if (rate == null)
                    const Text(
                      "Fiat rate not available",
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    )
                  else
                    Text(
                      "${fiatValue.toStringAsFixed(2)} $fiatSymbol",
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),

                  const SizedBox(height: 40),

                  // زرا SEND / RECEIVE مع الأيقونات
                  Container(
                    height: 40,
                    width: 320,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        // زر SEND
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomLeft: Radius.circular(4),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomLeft: Radius.circular(4),
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WriteAddressPage(
                                      preFilledAddress: "",
                                    ),
                                  ),
                                );
                              },
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.arrow_upward,
                                      color: Colors.black87,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Send",
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // زر RECEIVE
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF3949AB),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReceivePage(),
                                  ),
                                );
                              },
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.arrow_downward,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Receive",
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
