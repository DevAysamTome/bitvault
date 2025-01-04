import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

/// TransactionsProvider مسؤول عن جلب المعاملات من API خارجية
class TransactionsProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// قائمة المعاملات كمثال، كل معاملة تمثل خريطة
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> get transactions => _transactions;

  /// الدالة الرئيسية لجلب المعاملات
  Future<void> fetchTransactions(String addresses) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      const url = 'https://transaction-details.vercel.app/api/index';

      // بناء جسم الطلب
      final Map<String, dynamic> requestBody = {
        "addresses": addresses,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List) {
          _transactions = List<Map<String, dynamic>>.from(decoded);
        } else {
          _transactions = [];
        }
      } else {
        _error = "Error: ${response.statusCode}";
        _transactions = [];
      }
    } catch (e) {
      _error = e.toString();
      _transactions = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}

/// الصفحة الرئيسية لتجربة TransactionsProvider
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionsProvider = Provider.of<TransactionsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // زر لجلب البيانات
            ElevatedButton(
              onPressed: () {
                // استدعاء الدالة لجلب المعاملات
                transactionsProvider.fetchTransactions("sample_address_1");
              },
              child: const Text("Fetch Transactions"),
            ),

            const SizedBox(height: 16),

            // عرض حالة التحميل أو الأخطاء أو البيانات
            if (transactionsProvider.isLoading)
              const CircularProgressIndicator()
            else if (transactionsProvider.error != null)
              Text(
                transactionsProvider.error!,
                style: const TextStyle(color: Colors.red),
              )
            else if (transactionsProvider.transactions.isEmpty)
              const Text("No transactions found.")
            else
              Expanded(
                child: ListView.builder(
                  itemCount: transactionsProvider.transactions.length,
                  itemBuilder: (context, index) {
                    final transaction =
                        transactionsProvider.transactions[index];
                    return ListTile(
                      title: Text("Transaction ID: ${transaction['txid']}"),
                      subtitle: Text(
                          "Amount: ${transaction['amount']} | Fee: ${transaction['fee']}"),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// نقطة البداية للتطبيق
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransactionsProvider(),
        ),
      ],
      child: const MaterialApp(
        home: TransactionsPage(),
      ),
    ),
  );
}
