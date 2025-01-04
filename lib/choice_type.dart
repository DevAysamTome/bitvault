import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'wallet_provider.dart';
import 'wallet_page.dart';

class ChoiceTypePage extends StatefulWidget {
  const ChoiceTypePage({super.key});

  @override
  State<ChoiceTypePage> createState() => _ChoiceTypePageState();
}

class _ChoiceTypePageState extends State<ChoiceTypePage> {
  int? _selectedIndex;

  /// الخيارات المتاحة لأنواع المحافظ
  final List<WalletTypeOption> walletOptions = [
    WalletTypeOption(
      title: "Native SegWit",
      subtitle: "Recommended",
      description: "m/84'/0'/0'",
      bipType: WalletProvider.bip84,
      icon: Icons.lock_outline_rounded,
    ),
    WalletTypeOption(
      title: "SegWit",
      subtitle: "More privacy",
      description: "m/49'/0'/0'",
      bipType: WalletProvider.bip49,
      icon: Icons.security_rounded,
    ),
    WalletTypeOption(
      title: "Legacy",
      subtitle: "Higher Integration",
      description: "m/44'/0'/0'",
      bipType: WalletProvider.bip44,
      icon: Icons.history_edu_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Add Wallet',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose Wallet Type",
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Select the derivation path and wallet type that best suits your needs.",
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: walletOptions.length,
                itemBuilder: (context, index) {
                  final option = walletOptions[index];

                  // جلب الرصيد من مزوّد المحافظ
                  final satBalance =
                      walletProvider.getBalanceInSatoshi(option.bipType);

                  // إذا الرصيد أكبر من صفر => تعتبر مستخدمة
                  final isUsed = satBalance > 0;
                  final statusText = isUsed ? "Used" : "Unused";

                  // نعرض الرصيد بصيغة العرض (BTC أو SAT)
                  final displayBalance =
                      walletProvider.getDisplayBalance(option.bipType);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: _buildWalletOption(
                        option: option,
                        displayBalance: displayBalance,
                        statusText: statusText,
                        isSelected: _selectedIndex == index,
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_selectedIndex == null) return;

                final chosenOption = walletOptions[_selectedIndex!];
                walletProvider.setPreferredBipType(chosenOption.bipType);

                // الانتقال لصفحة المحافظ
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3949AB), // لون زر المتابعة
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'CONTINUE',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletOption({
    required WalletTypeOption option,
    required String displayBalance,
    required String statusText,
    required bool isSelected,
  }) {
    // لون التحديد الجديد
    const Color selectedColor = Color(0xFF1A237E);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: selectedColor, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(option.icon, color: selectedColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  option.subtitle,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  option.description,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // عرض الرصيد بالوحدة الحالية (BTC أو SAT)
              Text(
                displayBalance,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: selectedColor, // نفس لون التحديد
                ),
              ),
              const SizedBox(height: 5),
              Text(
                statusText, // تظهر "Used" أو "Unused"
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: selectedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WalletTypeOption {
  final String title;
  final String subtitle;
  final String description;
  final String bipType;
  final IconData icon;

  WalletTypeOption({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.bipType,
    required this.icon,
  });
}
