import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

class SubscriptionPackage {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<String> features;

  const SubscriptionPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.features = const [],
  });
}

const subscriptionPackages = [
  SubscriptionPackage(
    id: 'basic',
    name: 'الأساسي',
    price: 0,
    description: 'للاطلاع على السوق والمزايا الأساسية',
    features: ['تصفح العقارات والبحث', 'تقدير سعر واحد شهرياً', 'الرسائل مع الوسطاء'],
  ),
  SubscriptionPackage(
    id: 'pro',
    name: 'الاحترافي',
    price: 99,
    description: 'للمستثمرين والباحثين الجادين',
    features: [
      'كل مزايا الأساسي',
      'تقدير أسعار غير محدود',
      'نبض الحي وتقارير السوق',
      'إدارة مفضلة متقدمة وإشعارات فورية',
      'عرض عقاراتك في القوائم المميزة',
    ],
  ),
  SubscriptionPackage(
    id: 'enterprise',
    name: 'المؤسسات',
    price: 299,
    description: 'للوساطات وشركات التطوير العقاري',
    features: [
      'كل مزايا الاحترافي',
      'حسابات فريق غير محدودة',
      'تقارير وبيانات مخصصة',
      'دعم فني ذو أولوية',
      'API للبيانات العقارية',
      'إدارة محافظ عقارية متعددة',
    ],
  ),
];

class PaymentState {
  final bool testMode;
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> history;
  final String? processingPackageId;

  const PaymentState({
    this.testMode = false,
    this.isLoading = false,
    this.error,
    this.history = const [],
    this.processingPackageId,
  });

  PaymentState copyWith({
    bool? testMode,
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? history,
    String? processingPackageId,
    bool clearError = false,
  }) {
    return PaymentState(
      testMode: testMode ?? this.testMode,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      history: history ?? this.history,
      processingPackageId: processingPackageId ?? this.processingPackageId,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(const PaymentState());

  Future<void> loadConfig() async {
    try {
      final config = await ApiService.getPaymentsConfig();
      state = state.copyWith(testMode: config['testMode'] == true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadHistory() async {
    try {
      final history = await ApiService.getMyPayments();
      state = state.copyWith(history: history);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// إنشاء دفعة لباقة. يُرجع خريطة النتيجة من الخادم.
  Future<Map<String, dynamic>?> createIntent(String packageId) async {
    state = state.copyWith(isLoading: true, processingPackageId: packageId, clearError: true);
    try {
      final res = await ApiService.createPaymentIntent(packageId);
      state = state.copyWith(isLoading: false, processingPackageId: null);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, processingPackageId: null, error: e.toString());
      return null;
    }
  }

  /// إتمام دفعة تجريبية (بدون بوابة خارجية).
  Future<bool> completeTest(String paymentId) async {
    try {
      await ApiService.completeTestPayment(paymentId);
      await loadHistory();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final paymentsProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier();
});
