enum SubscriptionTier {
  free,
  basic,
  premium,
  enterprise,
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final SubscriptionTier tier;
  final List<String> features;
  final Duration billingCycle;
  final bool isPopular;
  final bool isActive;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.tier,
    required this.features,
    required this.billingCycle,
    this.isPopular = false,
    this.isActive = true,
  });

  String get formattedPrice => '$currency${price.toStringAsFixed(2)}';
  String get billingCycleText {
    if (billingCycle.inDays == 30) return 'month';
    if (billingCycle.inDays == 365) return 'year';
    if (billingCycle.inDays == 7) return 'week';
    return '${billingCycle.inDays} days';
  }

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    SubscriptionTier? tier,
    List<String>? features,
    Duration? billingCycle,
    bool? isPopular,
    bool? isActive,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      tier: tier ?? this.tier,
      features: features ?? this.features,
      billingCycle: billingCycle ?? this.billingCycle,
      isPopular: isPopular ?? this.isPopular,
      isActive: isActive ?? this.isActive,
    );
  }
} 