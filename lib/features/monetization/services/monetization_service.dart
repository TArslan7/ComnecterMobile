import '../models/subscription_plan.dart';
import '../models/user_subscription.dart';

class MonetizationService {
  static final MonetizationService _instance = MonetizationService._internal();
  factory MonetizationService() => _instance;
  MonetizationService._internal();

  // Get available subscription plans
  List<SubscriptionPlan> getAvailablePlans() {
    return [
      const SubscriptionPlan(
        id: 'free',
        name: 'Free',
        description: 'Basic features for everyone',
        price: 0.0,
        currency: '\$',
        tier: SubscriptionTier.free,
        features: [
          '5km radar radius',
          'Basic chat',
          'Profile management',
          'Standard support',
        ],
        billingCycle: Duration(days: 30),
        isPopular: false,
      ),
      const SubscriptionPlan(
        id: 'basic',
        name: 'Basic',
        description: 'Enhanced features for active users',
        price: 4.99,
        currency: '\$',
        tier: SubscriptionTier.basic,
        features: [
          '10km radar radius',
          'Unlimited chat',
          'Advanced profile features',
          'Priority support',
          'Ad-free experience',
        ],
        billingCycle: Duration(days: 30),
        isPopular: true,
      ),
      const SubscriptionPlan(
        id: 'premium',
        name: 'Premium',
        description: 'Full features for power users',
        price: 9.99,
        currency: '\$',
        tier: SubscriptionTier.premium,
        features: [
          'Unlimited radar radius',
          'Unlimited chat',
          'Advanced profile features',
          'Priority support',
          'Ad-free experience',
          'Custom themes',
          'Advanced privacy controls',
          'Export data',
        ],
        billingCycle: Duration(days: 30),
        isPopular: false,
      ),
      const SubscriptionPlan(
        id: 'enterprise',
        name: 'Enterprise',
        description: 'Custom solutions for organizations',
        price: 29.99,
        currency: '\$',
        tier: SubscriptionTier.enterprise,
        features: [
          'All Premium features',
          'Custom branding',
          'Analytics dashboard',
          'Dedicated support',
          'API access',
          'White-label solution',
        ],
        billingCycle: Duration(days: 30),
        isPopular: false,
      ),
    ];
  }

  // Get current user subscription
  Future<UserSubscription?> getCurrentUserSubscription() async {
    // Mock implementation - in real app, this would fetch from backend
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return null for free user
    return null;
    
    // Or return a mock subscription for testing
    // return const UserSubscription(
    //   id: 'sub_123',
    //   userId: 'user_123',
    //   planId: 'basic',
    //   status: SubscriptionStatus.active,
    //   startDate: DateTime(2024, 1, 1),
    //   endDate: DateTime(2024, 2, 1),
    //   remainingDays: 15,
    //   autoRenew: true,
    //   amountPaid: 4.99,
    //   currency: '\$',
    // );
  }

  // Subscribe to a plan
  Future<bool> subscribeToPlan(String planId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      // Mock implementation - in real app, this would process payment
      return true;
    } catch (e) {
      return false;
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // Mock implementation - in real app, this would cancel with payment provider
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get subscription benefits based on tier
  List<String> getSubscriptionBenefits(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return [
          '5km radar radius',
          'Basic chat functionality',
          'Standard profile features',
          'Community support',
        ];
      case SubscriptionTier.basic:
        return [
          '10km radar radius',
          'Unlimited chat messages',
          'Advanced profile customization',
          'Priority support',
          'Ad-free experience',
          'Enhanced privacy controls',
        ];
      case SubscriptionTier.premium:
        return [
          'Unlimited radar radius',
          'Unlimited chat messages',
          'Advanced profile features',
          'Priority support',
          'Ad-free experience',
          'Custom themes',
          'Advanced privacy controls',
          'Data export',
          'Analytics dashboard',
        ];
      case SubscriptionTier.enterprise:
        return [
          'All Premium features',
          'Custom branding',
          'Analytics dashboard',
          'Dedicated support',
          'API access',
          'White-label solution',
          'Custom integrations',
        ];
    }
  }

  // Check if user has access to a feature
  bool hasFeatureAccess(SubscriptionTier userTier, SubscriptionTier requiredTier) {
    final tierOrder = {
      SubscriptionTier.free: 0,
      SubscriptionTier.basic: 1,
      SubscriptionTier.premium: 2,
      SubscriptionTier.enterprise: 3,
    };
    
    return tierOrder[userTier]! >= tierOrder[requiredTier]!;
  }
} 