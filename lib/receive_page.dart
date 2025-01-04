import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

import 'wallet_provider.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  bool _showCopied = false;
  String? _address;

  @override
  void initState() {
    super.initState();
    // نجلب العنوان من الـ Provider
    final walletProvider = context.read<WalletProvider>();
    final fetchedAddress = walletProvider.currentFreshAddress;
    _address = (fetchedAddress != null && fetchedAddress.isNotEmpty)
        ? fetchedAddress
        : null;
  }

  /// عند النقر على العنوان:
  /// 1. نسخه إلى الحافظة
  /// 2. استبدال النص بـ "copied" لمدة ثانيتين
  /// 3. إعادة النص الأصلي
  Future<void> _onAddressTap() async {
    if (_address == null || _address!.isEmpty) return;

    // نسخ العنوان
    Clipboard.setData(ClipboardData(text: _address!));
    HapticFeedback.lightImpact();

    // إظهار نص "copied"
    setState(() {
      _showCopied = true;
    });

    // الانتظار ثانيتين
    await Future.delayed(const Duration(seconds: 2));

    // إخفاء "copied" وإرجاع العنوان
    if (mounted) {
      setState(() {
        _showCopied = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAddress = _address != null && _address!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Receive',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: hasAddress
            ? _buildWithAddress(context, _address!)
            : _buildNoAddress(context),
      ),
    );
  }

  // في حال توفر العنوان
  Widget _buildWithAddress(BuildContext context, String address) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // رمز QR في المنتصف
        Center(
          // ignore: deprecated_member_use
          child: PrettyQr(
            data: address,
            size: 240, // حجم الـ QR
            roundEdges: true, // حواف مستديرة
            elementColor: Colors.black, // لون مربعات الـ QR
          ),
        ),
        const SizedBox(height: 20),
        // العنوان أو "copied"
        GestureDetector(
          onTap: _onAddressTap,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showCopied
                ? const Text(
                    "copied",
                    key: ValueKey('copiedText'),
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  )
                : Text(
                    address,
                    key: const ValueKey('addressText'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
        const Spacer(),
        // زر المشاركة في الأسفل
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                // اللون المطلوب لزر Share
                backgroundColor: const Color(0xFF0057FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // مشاركة العنوان باستخدام share_plus
                Share.share(address, subject: "My BTC Address");
                HapticFeedback.lightImpact();
              },
              child: const Text(
                'Share...',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // في حال عدم توفر العنوان
  Widget _buildNoAddress(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.error_outline, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No fresh address available!",
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Please fetch wallet data or check the BIP path.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
