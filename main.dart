import 'package:flutter/material.dart';
import 'service_locator.dart' as di; // استدعاء المدير

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تشغيل المدير وقاعدة البيانات قبل ما الأبلكيشن يفتح
  await di.init(); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'فطين POS',
      home: const BillingScreen(), // الصفحة اللي عملناها المرة اللي فاتت
    );
  }
}
