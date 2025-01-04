import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// الصفحات الأخرى
import 'bitcoin_unit_page.dart';
import 'currency_page.dart';

// المزود للعملة الورقية
import 'currency_rate_provider.dart';

// المزود للوحدة (BTC أو SAT)
import 'wallet_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // لون خلفية مختلف
    const backgroundColor = Color(0xFFF8FAFB);

    // العملة الورقية (رمز + علم)
    final currencyRateProv = context.watch<CurrencyRateProvider>();
    final symbol = currencyRateProv.fiatSymbol; // "USD", ...
    final flagUrl = currencyRateProv.fiatFlagUrl; // رابط العلم (قد يكون فارغ)

    // الوحدة (BTC أو SAT)
    final walletProvider = context.watch<WalletProvider>();
    final currentUnit = walletProvider.currentUnit;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            _buildSettingsItem(
              title: "Wallets",
              onTap: () {
                HapticFeedback.lightImpact();
                // ...
              },
            ),
            _buildSettingsItem(
              title: "Security",
              onTap: () {
                HapticFeedback.lightImpact();
                // ...
              },
            ),
            _buildSettingsItem(
              title: "App Preferences",
              onTap: () {
                HapticFeedback.lightImpact();
                // ...
              },
            ),

            // ================================
            // سطر "Currency" مع العلم (بدون خلفية)
            // ================================
            _buildSettingsItem(
              title: "Currency",
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (flagUrl != null && flagUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        flagUrl,
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.flag, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    symbol,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                // الانتقال بالسحب من اليمين لليسار
                Navigator.push(
                  context,
                  _buildRouteSlideTransition(const CurrencyPage()),
                );
              },
            ),

            // ================================
            // سطر "Bitcoin Unit" (بدون خلفية)
            // ================================
            _buildSettingsItem(
              title: "Bitcoin Unit",
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // أيقونة البيتكوين
                  Image.asset(
                    'assets/image/bitcoin-910307_1280.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentUnit == "BTC" ? "Bitcoin" : "Satoshi",
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  _buildRouteSlideTransition(const BitcoinUnitPage()),
                );
              },
            ),

            const SizedBox(height: 12),

            // زر Logout (بدون سهم)
            _buildLogoutItem(
              title: "Logout",
              onTap: () {
                HapticFeedback.heavyImpact();
                _showLogoutWarning(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// عنصر إعداد افتراضي (سطر واحد)
  Widget _buildSettingsItem({
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                // إن لم يُرسل trailing، نضع سهم افتراضي
                trailing ??
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// عنصر Logout (سطر واحد) بلون أحمر **بدون سهم**
  Widget _buildLogoutItem({
    required String title,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
                // تم إزالة الأيقونة هنا
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// نافذة تحذير عند تسجيل الخروج
  void _showLogoutWarning(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            "Warning",
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "You are about to reset your wallet data.\n\n"
            "Make sure you have backed up your secret phrase so you can restore your wallet next time.\n\n"
            "Are you sure you want to log out and lose all data?",
            style: TextStyle(fontFamily: 'SpaceGrotesk'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "No",
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, true);
              },
              child: const Text(
                "Yes",
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        // هنا يتم إعادة التطبيق من الصفر
        // انتقل مثلاً لصفحة البداية وأزل كل الصفحات السابقة
        // ignore: use_build_context_synchronously
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    });
  }

  /// دالة لبناء تأثير انتقال (سحب من اليمين لليسار)
  Route _buildRouteSlideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // بداية الحركة من يمين الشاشة
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOut));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
