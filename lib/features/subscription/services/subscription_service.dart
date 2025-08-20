import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../../../services/sound_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final StreamController<Subscription?> _subscriptionController = StreamController<Subscription?>.broadcast();
  final StreamController<List<SubscriptionPlanData>> _plansController = StreamController<List<SubscriptionPlanData>>.broadcast();
  final StreamController<List<PaymentInfo>> _paymentsController = StreamController<List<PaymentInfo>>.broadcast();
  final StreamController<SubscriptionStats> _statsController = StreamController<SubscriptionStats>.broadcast();
  
  Stream<Subscription?> get subscriptionStream => _subscriptionController.stream;
  Stream<List<SubscriptionPlanData>> get plansStream => _plansController.stream;
  Stream<List<PaymentInfo>> get paymentsStream => _paymentsController.stream;
  Stream<SubscriptionStats> get statsStream => _statsController.stream;

  Subscription? _currentSubscription;
  List<SubscriptionPlanData> _availablePlans = [];
  List<PaymentInfo> _paymentMethods = [];
  SubscriptionStats _stats = SubscriptionStats(
    totalSubscriptions: 0,
    activeSubscriptions: 0,
    expiredSubscriptions: 0,
    totalRevenue: 0.0,
    currency: 'USD',
    lastUpdated: DateTime.now(),
  );

  final Random _random = Random();

  // Initialize the subscription service
  Future<void> initialize() async {
    // Generate mock data
    _availablePlans = _generateSubscriptionPlans();
    _paymentMethods = _generatePaymentMethods();
    _currentSubscription = _generateMockSubscription();
    _stats = _generateMockStats();
    
    _plansController.add(_availablePlans);
    _paymentsController.add(_paymentMethods);
    _subscriptionController.add(_currentSubscription);
    _statsController.add(_stats);
  }

  // Get current subscription
  Subscription? get currentSubscription => _currentSubscription;

  // Get available plans
  List<SubscriptionPlanData> get availablePlans => List.unmodifiable(_availablePlans);

  // Get payment methods
  List<PaymentInfo> get paymentMethods => List.unmodifiable(_paymentMethods);

  // Get stats
  SubscriptionStats get stats => _stats;

  // Subscribe to a plan
  Future<bool> subscribeToPlan(SubscriptionPlan plan, PaymentMethod paymentMethod) async {
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      final planData = _availablePlans.firstWhere((p) => p.plan == plan);
      final paymentInfo = _paymentMethods.firstWhere((p) => p.method == paymentMethod);
      
      final subscription = Subscription(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        plan: plan,
        status: SubscriptionStatus.active,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        paymentMethod: paymentMethod,
        transactionId: 'txn_${_random.nextInt(1000000)}',
        amount: planData.price,
        currency: planData.currency,
        billingPeriod: planData.billingPeriod,
        autoRenew: true,
      );

      _currentSubscription = subscription;
      _subscriptionController.add(_currentSubscription);
      
      // Update stats
      _updateStats();
      
      SoundService().playSuccessSound();
      return true;
    } catch (e) {
      SoundService().playErrorSound();
      return false;
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    if (_currentSubscription == null) return false;

    try {
      // Simulate cancellation processing
      await Future.delayed(const Duration(seconds: 1));
      
      _currentSubscription = _currentSubscription!.copyWith(
        status: SubscriptionStatus.cancelled,
        cancelledDate: DateTime.now(),
        autoRenew: false,
      );
      
      _subscriptionController.add(_currentSubscription);
      _updateStats();
      
      SoundService().playButtonClickSound();
      return true;
    } catch (e) {
      SoundService().playErrorSound();
      return false;
    }
  }

  // Renew subscription
  Future<bool> renewSubscription() async {
    if (_currentSubscription == null) return false;

    try {
      // Simulate renewal processing
      await Future.delayed(const Duration(seconds: 1));
      
      _currentSubscription = _currentSubscription!.copyWith(
        status: SubscriptionStatus.active,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        cancelledDate: null,
        autoRenew: true,
      );
      
      _subscriptionController.add(_currentSubscription);
      _updateStats();
      
      SoundService().playSuccessSound();
      return true;
    } catch (e) {
      SoundService().playErrorSound();
      return false;
    }
  }

  // Add payment method
  Future<bool> addPaymentMethod(PaymentInfo paymentInfo) async {
    try {
      // Simulate payment method addition
      await Future.delayed(const Duration(milliseconds: 500));
      
      _paymentMethods.add(paymentInfo);
      _paymentsController.add(_paymentMethods);
      
      SoundService().playSuccessSound();
      return true;
    } catch (e) {
      SoundService().playErrorSound();
      return false;
    }
  }

  // Remove payment method
  Future<bool> removePaymentMethod(String paymentId) async {
    try {
      _paymentMethods.removeWhere((p) => p.id == paymentId);
      _paymentsController.add(_paymentMethods);
      
      SoundService().playButtonClickSound();
      return true;
    } catch (e) {
      SoundService().playErrorSound();
      return false;
    }
  }

  // Set default payment method
  Future<bool> setDefaultPaymentMethod(String paymentId) async {
    try {
      for (int i = 0; i < _paymentMethods.length; i++) {
        _paymentMethods[i] = _paymentMethods[i].copyWith(
          isDefault: _paymentMethods[i].id == paymentId,
        );
      }
      _paymentsController.add(_paymentMethods);
      
      SoundService().playSuccessSound();
      return true;
    } catch (e) {
      SoundService().playErrorSound();
      return false;
    }
  }

  // Get plan by type
  SubscriptionPlanData? getPlanByType(SubscriptionPlan plan) {
    try {
      return _availablePlans.firstWhere((p) => p.plan == plan);
    } catch (e) {
      return null;
    }
  }

  // Check if user has active subscription
  bool get hasActiveSubscription {
    return _currentSubscription?.isActive == true;
  }

  // Check if user has premium features
  bool hasPremiumFeature(String feature) {
    if (!hasActiveSubscription) return false;
    
    final plan = _currentSubscription!.plan;
    switch (feature) {
      case 'unlimited_radar':
        return plan == SubscriptionPlan.premium || plan == SubscriptionPlan.pro;
      case 'advanced_filters':
        return plan == SubscriptionPlan.premium || plan == SubscriptionPlan.pro;
      case 'priority_support':
        return plan == SubscriptionPlan.pro;
      case 'no_ads':
        return plan == SubscriptionPlan.basic || plan == SubscriptionPlan.premium || plan == SubscriptionPlan.pro;
      case 'custom_themes':
        return plan == SubscriptionPlan.premium || plan == SubscriptionPlan.pro;
      case 'analytics':
        return plan == SubscriptionPlan.pro;
      default:
        return false;
    }
  }

  // Update stats
  void _updateStats() {
    _stats = SubscriptionStats(
      totalSubscriptions: _stats.totalSubscriptions + 1,
      activeSubscriptions: _currentSubscription?.isActive == true ? 1 : 0,
      expiredSubscriptions: _currentSubscription?.isExpired == true ? 1 : 0,
      totalRevenue: _stats.totalRevenue + (_currentSubscription?.amount ?? 0),
      currency: _stats.currency,
      lastUpdated: DateTime.now(),
    );
    _statsController.add(_stats);
  }

  // Generate subscription plans
  List<SubscriptionPlanData> _generateSubscriptionPlans() {
    return [
      const SubscriptionPlanData(
        plan: SubscriptionPlan.free,
        name: 'Free',
        description: 'Basic features for everyone',
        price: 0.0,
        currency: 'USD',
        billingPeriod: 'month',
        features: [
          'Basic radar detection',
          'Limited friend requests',
          'Standard chat',
          'Basic profile',
        ],
        color: Colors.grey,
      ),
      const SubscriptionPlanData(
        plan: SubscriptionPlan.basic,
        name: 'Basic',
        description: 'Enhanced features for casual users',
        price: 4.99,
        currency: 'USD',
        billingPeriod: 'month',
        features: [
          'Enhanced radar detection',
          'Unlimited friend requests',
          'Advanced chat features',
          'No advertisements',
          'Priority support',
        ],
        color: Colors.blue,
        isRecommended: true,
      ),
      const SubscriptionPlanData(
        plan: SubscriptionPlan.premium,
        name: 'Premium',
        description: 'Advanced features for power users',
        price: 9.99,
        currency: 'USD',
        billingPeriod: 'month',
        features: [
          'Unlimited radar range',
          'Advanced user filters',
          'Custom themes',
          'Analytics dashboard',
          'Priority support',
          'No advertisements',
        ],
        color: Colors.purple,
        isPopular: true,
      ),
      const SubscriptionPlanData(
        plan: SubscriptionPlan.pro,
        name: 'Pro',
        description: 'Ultimate features for professionals',
        price: 19.99,
        currency: 'USD',
        billingPeriod: 'month',
        features: [
          'Everything in Premium',
          'Advanced analytics',
          'API access',
          'White-label options',
          'Dedicated support',
          'Custom integrations',
        ],
        color: Colors.orange,
      ),
    ];
  }

  // Generate payment methods
  List<PaymentInfo> _generatePaymentMethods() {
    return [
      PaymentInfo(
        id: 'pay_1',
        method: PaymentMethod.creditCard,
        cardLast4: '1234',
        cardBrand: 'Visa',
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        isDefault: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      PaymentInfo(
        id: 'pay_2',
        method: PaymentMethod.paypal,
        paypalEmail: 'user@example.com',
        isDefault: false,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      PaymentInfo(
        id: 'pay_3',
        method: PaymentMethod.applePay,
        isDefault: false,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  // Generate mock subscription
  Subscription? _generateMockSubscription() {
    // 70% chance of having a subscription
    if (_random.nextDouble() < 0.7) {
      final plans = [SubscriptionPlan.basic, SubscriptionPlan.premium, SubscriptionPlan.pro];
      final plan = plans[_random.nextInt(plans.length)];
      final planData = _availablePlans.firstWhere((p) => p.plan == plan);
      
      return Subscription(
        id: 'sub_mock_${_random.nextInt(1000)}',
        userId: 'current_user',
        plan: plan,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        endDate: DateTime.now().add(Duration(days: _random.nextInt(30))),
        paymentMethod: PaymentMethod.creditCard,
        transactionId: 'txn_mock_${_random.nextInt(1000000)}',
        amount: planData.price,
        currency: planData.currency,
        billingPeriod: planData.billingPeriod,
        autoRenew: _random.nextBool(),
      );
    }
    return null;
  }

  // Generate mock stats
  SubscriptionStats _generateMockStats() {
    return SubscriptionStats(
      totalSubscriptions: _random.nextInt(1000) + 100,
      activeSubscriptions: _random.nextInt(800) + 50,
      expiredSubscriptions: _random.nextInt(200) + 10,
      totalRevenue: _random.nextDouble() * 50000 + 10000,
      currency: 'USD',
      lastUpdated: DateTime.now(),
    );
  }

  // Dispose resources
  void dispose() {
    _subscriptionController.close();
    _plansController.close();
    _paymentsController.close();
    _statsController.close();
  }
}
