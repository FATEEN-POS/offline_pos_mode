import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:intl/intl.dart';

// --- 1. Model (Entity) ---
class CartItem {
  final String name;
  final double price;
  int quantity;

  CartItem({required this.name, required this.price, this.quantity = 1});
}

// --- 2. State Management (Cubit) ---
class BillingCubit extends Cubit<List<CartItem>> {
  BillingCubit() : super([]);

  // إضافة منتج للسلة بناءً على الباركود
  void addProduct(String barcode) {
    // محاكاة قاعدة بيانات Hive (في الواقع ستقوم بعمل Repo.getProduct)
    final dbMock = {
      "6221007011447": {"name": "بسكويت لوتس", "price": 10.0},
      "01234567": {"name": "بيبسي كانز", "price": 12.0},
    };

    final currentState = List<CartItem>.from(state);
    final product = dbMock[barcode];

    if (product != null) {
      int index = currentState.indexWhere((item) => item.name == product['name']);
      if (index != -1) {
        currentState[index].quantity++;
      } else {
        currentState.add(CartItem(name: product['name'] as String, price: product['price'] as double));
      }
      emit(currentState);
    }
  }

  void updateQty(int index, int delta) {
    final currentState = List<CartItem>.from(state);
    currentState[index].quantity += delta;
    if (currentState[index].quantity <= 0) currentState.removeAt(index);
    emit(currentState);
  }

  double get totalPrice => state.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

// --- 3. UI Layer (Presentation) ---
class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BillingCubit(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: const BillingView(),
      ),
    );
  }
}

class BillingView extends StatelessWidget {
  const BillingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // القسم العلوي: الكاميرا
        Positioned(
          top: 0, left: 0, right: 0,
          height: MediaQuery.of(context).size.height * 0.5,
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                context.read<BillingCubit>().addProduct(barcodes.first.rawValue ?? "");
              }
            },
          ),
        ),

        // إطار المسح (Overlay)
        Align(
          alignment: const Alignment(0, -0.5),
          child: Container(
            width: 250, height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // القسم السفلي: السلة (Bottom Sheet)
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.52,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 15),
                Expanded(child: _buildCartList(context)),
                const SizedBox(height: 15),
                _buildPrintButton(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<BillingCubit, List<CartItem>>(
      builder: (context, state) {
        final total = context.read<BillingCubit>().totalPrice;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("الأصناف الممسوحة", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text("${state.length} أصناف في السلة", style: const TextStyle(color: Colors.grey)),
              ],
            ),
            Text("${total.toStringAsFixed(2)} ج.م", 
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2A36B1))),
          ],
        );
      },
    );
  }

  Widget _buildCartList(BuildContext context) {
    return BlocBuilder<BillingCubit, List<CartItem>>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.length,
          itemBuilder: (context, index) {
            final item = state[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("${item.price} ج.م", style: const TextStyle(color: Color(0xFF2A36B1))),
                    ],
                  ),
                  Row(
                    children: [
                      _qtyBtn(context, index, -1, Icons.remove),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      _qtyBtn(context, index, 1, Icons.add),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _qtyBtn(BuildContext context, int index, int delta, IconData icon) {
    return GestureDetector(
      onTap: () => context.read<BillingCubit>().updateQty(index, delta),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: const Color(0xFFEEF1F4), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 20, color: const Color(0xFF2A36B1)),
      ),
    );
  }

  Widget _buildPrintButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2A36B1),
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
      ),
      onPressed: () => _handlePrint(context),
      child: const Text("مراجعة وطباعة الفاتورة", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // --- وظيفة الطباعة الحرارية ---
  Future<void> _handlePrint(BuildContext context) async {
    final cubit = context.read<BillingCubit>();
    if (cubit.state.isEmpty) return;

    bool isConnected = await PrintBluetoothThermal.connectionStatus;
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("برجاء ربط طابعة البلوتوث أولاً")));
      return;
    }

    String receipt = "   فاتورة مبيعات فطين\n";
    receipt += "--------------------------------\n";
    receipt += "الوقت: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n\n";
    
    for (var item in cubit.state) {
      receipt += "${item.name}\n";
      receipt += "${item.quantity} x ${item.price} = ${(item.quantity * item.price).toStringAsFixed(2)} ج.م\n";
    }
    
    receipt += "--------------------------------\n";
    receipt += "الإجمالي النهائي: ${cubit.totalPrice.toStringAsFixed(2)} ج.م\n";
    receipt += "\n   شكراً لزيارتكم\n\n\n";

    await PrintBluetoothThermal.writeBytes(receipt.codeUnits);
  }
}
