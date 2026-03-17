import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

final sl = GetIt.instance; // ده "المدير" اللي بننادي عليه في أي مكان

Future<void> init() async {
  // 1. تشغيل قاعدة البيانات (الدرج)
  await Hive.initFlutter();
  
  // 2. فتح "صندوق" للمنتجات وصندوق للإعدادات
  var productBox = await Hive.openBox('products_box');
  var settingsBox = await Hive.openBox('settings_box');

  // 3. تسجيل الحاجات دي عند "المدير" عشان الكل يشوفها
  sl.registerLazySingleton(() => productBox);
  sl.registerLazySingleton(() => settingsBox);
  
  print("✅ تم تجهيز قاعدة البيانات والمدير بنجاح!");
}
