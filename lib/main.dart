import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/service_service.dart';
import 'services/category_service.dart';
import 'services/chat_service.dart';
import 'services/transaction_service.dart';
import 'services/notification_service.dart';
import 'services/review_service.dart';
import 'services/wishlist_service.dart';
import 'services/report_service.dart';
import 'services/payment_service.dart';
import 'services/analytics_service.dart';
import 'services/location_service.dart';
import 'services/push_notification_service.dart';
import 'services/stripe_payment_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create notification service first since it's needed by other services
    final notificationService = NotificationService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ProductService()),
        ChangeNotifierProvider(create: (_) => ServiceService()),
        ChangeNotifierProvider(create: (_) => CategoryService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider.value(value: notificationService),
        ChangeNotifierProvider(
          create: (_) => TransactionService(
            productService: ProductService(),
            serviceService: ServiceService(),
            categoryService: CategoryService(),
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewService(
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => WishlistService()),
        ChangeNotifierProvider(create: (_) => ReportService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProvider(create: (_) => AnalyticsService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => StripePaymentService()),
        ChangeNotifierProvider(
          create: (_) => PushNotificationService(
            notificationService: notificationService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Vendo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}

