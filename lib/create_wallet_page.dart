import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// إذا أردت استخدامه لتوليد العبارة سرية فعليًا:
// import 'package:bip39/bip39.dart' as bip39;

// استورد الـ WalletProvider وملف wallet_page.dart
// تأكد أن wallet_provider.dart يعرف دالة fetchWalletData(...) و setPreferredBipType(...)
// تأكد أن wallet_page.dart يعرف صفحة WalletPage()
import 'wallet_provider.dart';
import 'wallet_page.dart';

// NEW: لاستعمال Supabase
import 'package:supabase_flutter/supabase_flutter.dart'; // NEW

class CreateWalletPage extends StatefulWidget {
  const CreateWalletPage({super.key});

  @override
  State<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<CreateWalletPage> {
  /// هل نعرض جدول المسارات أم نعرض الحقل الذي يحوي العبارة السرية؟
  bool _showTable = true;

  /// العبارة السرية (ستُنشأ/تُحدد في initState)
  String _mnemonic = "";

  /// هل هي مموهة؟
  bool _isObscured = true;

  /// هل نعرض نص "Copied!" لمؤقت قصير؟
  bool _copied = false;

  /// أي عنصر تم اختياره (BIP44, BIP49, BIP84) في الجدول؟
  int? _selectedIndex;

  /// المسارات (عرض صغير منسق) مع أيقونتها
  final List<PathItem> _paths = [
    PathItem(
      title: "Native SegWit (BIP84)",
      subtitle: "Recommended",
      icon: Icons.lock_outline_rounded,
    ),
    PathItem(
      title: "SegWit (BIP49)",
      subtitle: "More privacy",
      icon: Icons.security_rounded,
    ),
    PathItem(
      title: "Legacy (BIP44)",
      subtitle: "Higher Integration",
      icon: Icons.history_edu_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // لو كنت تريد توليد العبارة سرية فعليًا باستخدام bip39:
    // _mnemonic = bip39.generateMnemonic();

    // في هذا المثال ثابتة:
    _mnemonic =
        "apple brave copper dolphin empty frozen garage hammer island joker king lemon";
    debugPrint("Generated mnemonic: $_mnemonic");
  }

  /// اختيار العنصر من الجدول
  void _onSelectPath(int index) {
    setState(() {
      _selectedIndex = index;
    });
    HapticFeedback.lightImpact();
  }

  /// عند الضغط على Continue في "الجدول"
  /// نجلب بيانات الـ Provider بعد ضبط المسار المختار
  Future<void> _onConfirmPath() async {
    if (_selectedIndex == null) return;

    // حدد المسار نصيًا (BIP44/BIP49/BIP84)
    late String chosenBip;
    switch (_selectedIndex) {
      case 0:
        chosenBip = WalletProvider.bip84; // مثلًا لو كان NativeSegWit
        break;
      case 1:
        chosenBip = WalletProvider.bip49;
        break;
      case 2:
        chosenBip = WalletProvider.bip44;
        break;
      default:
        chosenBip = WalletProvider.bip84;
    }

    final walletProv = context.read<WalletProvider>();

    // نضبط المسار في الـ Provider
    walletProv.setPreferredBipType(chosenBip);

    // نجلب البيانات (walletData) بالعبارة
    await walletProv.fetchWalletData(
      mnemonic: _mnemonic,
      passphrase: '', // لو لديك passphrase ضعه هنا
    );

    // NEW: بعد اكتمال الجلب، نخزّن النتيجة في Supabase بعمود walletInfo
    final supabase = Supabase.instance.client; // NEW
    await supabase.from('wallet').insert({
      // NEW
      'walletInfo': walletProv.walletData, // NEW -> JSONB column
    }); // NEW

    // ADDED: لو أراد المستخدم إظهار عبارة السيرفر الجديدة:
    // نحدّث _mnemonic بقيمة walletData["mnemonic"] إن وجدت.
    final newMnemonic = walletProv.walletData?["mnemonic"]; // ADDED
    if (newMnemonic is String && newMnemonic.isNotEmpty) {
      // ADDED
      _mnemonic = newMnemonic; // ADDED
      debugPrint("Updated local mnemonic to: $_mnemonic"); // ADDED
    } // ADDED

    // بعد اكتمال الجلب والحفظ، نعطل الجدول ونُظهر العبارة
    setState(() {
      _showTable = false;
    });
    HapticFeedback.lightImpact();
  }

  /// عند الضغط على Continue في الخطوة الثانية (العبارة السرية)
  /// ننتقل إلى WalletPage
  void _onContinueMnemonic() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletPage()),
    );
  }

  /// تبديل الإخفاء/الإظهار
  void _toggleMnemonic() {
    setState(() {
      _isObscured = !_isObscured;
    });
    HapticFeedback.lightImpact();
  }

  /// نسخ العبارة الأصلية (دون تمويه)
  void _copyMnemonic() async {
    final textToCopy = _mnemonic;
    await Clipboard.setData(ClipboardData(text: textToCopy));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _copied = false);
    });
  }

  /// نص معروض (##### أو عادي)
  String get displayedMnemonic {
    if (!_isObscured) return _mnemonic;
    return _mnemonic.split(" ").map((_) => "#####").join(" ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F4F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Create Wallet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _showTable
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildTableSection(),
            secondChild: _buildMnemonicSection(),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            // لو ما زلنا في الجدول => عند الضغط نثبت الاختيار
            // لو في الحقل => ننتقل للصفحة التالية
            onPressed: _showTable
                ? (_selectedIndex == null ? null : _onConfirmPath)
                : _onContinueMnemonic,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_showTable && _selectedIndex == null)
                  ? Colors.grey
                  : const Color(0xFF3949AB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "CONTINUE",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// المرحلة الأولى: الجدول المصغر (3 عناصر) مع علامة صح
  Widget _buildTableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select a derivation path:",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _paths.length,
          itemBuilder: (context, index) {
            final item = _paths[index];
            final isSelected = (index == _selectedIndex);

            // بديل عن color.withOpacity(0.1)
            final Color highlightColor =
                const Color(0xFF3949AB).withValues(alpha: 0.1);

            final containerColor = isSelected ? highlightColor : Colors.white;
            final containerBorderColor =
                isSelected ? const Color(0xFF3949AB) : Colors.transparent;

            return GestureDetector(
              onTap: () => _onSelectPath(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: containerBorderColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected ? const Color(0xFF3949AB) : Colors.grey,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: (item.subtitle == "Recommended")
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check,
                        color: Color(0xFF3949AB),
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// المرحلة الثانية: العبارة السرية (مموهة)، أيقونة عين، زر نسخ
  Widget _buildMnemonicSection() {
    const Color mainColor = Color(0xFF3949AB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Secret Recovery Phrase",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: mainColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // النص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayedMnemonic,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    if (_copied)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          "Copied!",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // فاصل عمودي
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey,
              ),

              // أيقونة العين
              InkWell(
                onTap: _toggleMnemonic,
                child: Icon(
                  _isObscured ? Icons.visibility : Icons.visibility_off,
                  color: mainColor,
                  size: 20,
                ),
              ),

              // فاصل عمودي
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey,
              ),

              // أيقونة النسخ
              InkWell(
                onTap: _copyMnemonic,
                child: Icon(
                  Icons.copy,
                  color: mainColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Keep this phrase somewhere safe. Do NOT share it with anyone.\n"
          "It can recover your wallet if you lose this device.",
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// يمثل العنصر في الجدول (العنوان + الوصف + الأيقونة)
class PathItem {
  final String title;
  final String subtitle;
  final IconData icon;

  PathItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
