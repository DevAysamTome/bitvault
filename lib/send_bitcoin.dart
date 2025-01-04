import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// عدّل الاستيرادات أدناه حسب مشروعك
import 'wallet_provider.dart';
import 'currency_rate_provider.dart';

class SendBitcoinPage extends StatefulWidget {
  final String address;

  const SendBitcoinPage({super.key, required this.address});

  @override
  State<SendBitcoinPage> createState() => _SendBitcoinPageState();
}

class _SendBitcoinPageState extends State<SendBitcoinPage> {
  /// حقل إدخال مبلغ العملة الورقية
  final TextEditingController _amountController = TextEditingController();

  /// نعرض دائمًا العنوان مختصرًا في الأعلى
  String get _displayAddress {
    final addr = widget.address;
    if (addr.length <= 11) return addr;
    return "${addr.substring(0, 4)}...${addr.substring(addr.length - 4)}";
  }

  /// يتوفر لدى المستخدم الرصيد بالفيات (تحسبه في build)
  double _userFiatBalance = 0.0;

  /// الحد الأدنى بالفيات (مثلاً ما يعادل 546 ساتوشي)
  double _minFiat = 0.0;

  /// إظهار العنوان الكامل في BottomSheet مع "Full Address!"
  void _showAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          height: 150, // حجم ثابت بغض النظر عن طول العنوان
          color: Colors.white,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Full Address!",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.address,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// عند الضغط على "Use all funds"
  void _onUseAllFunds(
      WalletProvider walletProvider, CurrencyRateProvider rateProvider) {
    // رصيد المستخدم بالـ BTC
    final bipType = walletProvider.preferredBipType;
    final userBtc = walletProvider.getBalanceInBTC(bipType);
    final rate = rateProvider.rate ?? 0.0;

    // تحويله للفيّات
    final userFiatBalance = userBtc * rate;

    // نضع القيمة في الحقل
    _amountController.text = userFiatBalance.toStringAsFixed(2);
    setState(() {});
  }

  /// التحقق من قابلية التأكيد
  /// - يجب ألا يكون فارغًا
  /// - يجب ألا يتجاوز الرصيد المتاح
  /// - يجب ألا يقل عن الحد الأدنى (546 ساتوشي بالعملة الورقية)
  bool get _canConfirm {
    final txt = _amountController.text.trim();
    if (txt.isEmpty) return false;

    final parsed = double.tryParse(txt);
    if (parsed == null || parsed <= 0) return false;

    // الشرطان الإضافيان:
    if (parsed > _userFiatBalance) return false; // لا يتجاوز الرصيد
    if (parsed < _minFiat) return false; // لا يقل عن الحد الأدنى

    return true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context, listen: true);
    final rateProvider =
        Provider.of<CurrencyRateProvider>(context, listen: true);

    // رمز العملة الورقية (مثل "USD", "ILS" ...)
    final fiatSymbol = rateProvider.fiatSymbol;

    // 1) حساب الرصيد الكلي للمستخدم بالـ BTC
    final bipType = walletProvider.preferredBipType;
    final userBtcBalance = walletProvider.getBalanceInBTC(bipType);

    // 2) تحويله للفيّات
    final double userFiatBalance = (rateProvider.rate ?? 0.0) * userBtcBalance;
    _userFiatBalance = userFiatBalance;

    // 3) حساب الحد الأدنى بالـ فيات:
    //    546 sat = 546 / 100000000 BTC
    //    minFiat = (546 / 100000000) * rate
    final rate = rateProvider.rate ?? 0.0;
    final double minFiat = (546 / 100000000.0) * rate;
    _minFiat = minFiat;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Send bitcoin',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          // لإخفاء لوحة المفاتيح بالنقر على أي مكان فارغ
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // الديفايدر العلوي
                const Divider(
                  thickness: 1,
                  height: 1,
                  color: Colors.black12,
                ),

                // الصف: "To" ... [العنوان المختصر] ... خط عمودي ... أيقونة العين
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // نص "To"
                      const Text(
                        "To",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      // العنوان المختصر
                      Text(
                        _displayAddress,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),

                      // الخط العمودي بين العنوان والأيقونة
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 1,
                        height: 22,
                        color: Colors.black26,
                      ),

                      // أيقونة العين => تعرض العنوان الكامل في BottomSheet
                      IconButton(
                        onPressed: () {
                          _showAddressSheet(context);
                        },
                        icon: const Icon(
                          Icons.remove_red_eye_outlined,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),

                // الديفايدر السفلي
                const Divider(
                  thickness: 1,
                  height: 1,
                  color: Colors.black12,
                ),

                const SizedBox(height: 20),

                // حقل الإدخال (العملة الورقية) + رمز العملة
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 48,
                        color: Colors.blue[300],
                        margin: const EdgeInsets.only(right: 10),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: false,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: "0",
                            hintStyle: TextStyle(
                              fontSize: 32,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            setState(() {});
                          },
                        ),
                      ),
                      Text(
                        fiatSymbol,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.black87,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // الرصيد + Use all funds
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Balance: ${userFiatBalance.toStringAsFixed(2)} $fiatSymbol",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () =>
                            _onUseAllFunds(walletProvider, rateProvider),
                        child: const Text(
                          "Use all funds",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // تنبيه للمستخدم إن كان المبلغ المدخل يفوق الرصيد أو أقل من الحد الأدنى
                Builder(
                  builder: (ctx) {
                    final amountStr = _amountController.text.trim();
                    if (amountStr.isEmpty) return const SizedBox.shrink();

                    final parsed = double.tryParse(amountStr);
                    if (parsed == null) return const SizedBox.shrink();
                    if (parsed > userFiatBalance) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(top: 10, left: 16, right: 16),
                        child: const Text(
                          "Amount exceeds your balance!",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      );
                    } else if (parsed < minFiat && parsed > 0) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(top: 10, left: 16, right: 16),
                        child: Text(
                          "Minimum amount is ${minFiat.toStringAsFixed(2)} $fiatSymbol",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 40),

                // زر CONFIRM AMOUNT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canConfirm
                          ? () {
                              final val = double.tryParse(
                                  _amountController.text.trim());
                              if (val != null && val > 0) {
                                // منطق التأكيد النهائي هنا
                                // ...
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        // لون الزر
                        backgroundColor: const Color(0xFF0057FF),
                        disabledBackgroundColor: Colors.blueGrey[100],
                        // بدون أية زوايا
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                      child: const Text(
                        "CONFIRM AMOUNT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
