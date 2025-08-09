import 'package:flutter/material.dart';

enum SubscriptionStatus {
  none,
  active,
  expired,
  cancelled,
  pending,
  failed,
}

enum SubscriptionPlan {
  free,
  basic,
  premium,
  pro,
}

enum PaymentMethod {
  creditCard,
  paypal,
  applePay,
  googlePay,
  crypto,
}

class SubscriptionPlanData {
  final SubscriptionPlan plan;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String billingPeriod;
  final List<String> features;
  final Color color;
  final bool isPopular;
  final bool isRecommended;

  const SubscriptionPlanData({
    required this.plan,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.billingPeriod,
    required this.features,
    required this.color,
    this.isPopular = false,
    this.isRecommended = false,
  });

  String get formattedPrice {
    if (price == 0) return 'Free';
    return '$currency${price.toStringAsFixed(2)}';
  }

  String get fullPrice {
    if (price == 0) return 'Free';
    return '$formattedPrice/$billingPeriod';
  }
}

class Subscription {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? cancelledDate;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final double amount;
  final String currency;
  final String billingPeriod;
  final bool autoRenew;
  final Map<String, dynamic> metadata;

  Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.cancelledDate,
    required this.paymentMethod,
    this.transactionId,
    required this.amount,
    required this.currency,
    required this.billingPeriod,
    required this.autoRenew,
    this.metadata = const {},
  });

  bool get isActive => status == SubscriptionStatus.active;
  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isCancelled => status == SubscriptionStatus.cancelled;
  bool get isPending => status == SubscriptionStatus.pending;
  bool get isFailed => status == SubscriptionStatus.failed;

  int get daysRemaining {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  double get progressPercentage {
    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = DateTime.now().difference(startDate).inDays;
    return (elapsedDays / totalDays).clamp(0.0, 1.0);
  }

  Subscription copyWith({
    String? id,
    String? userId,
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? cancelledDate,
    PaymentMethod? paymentMethod,
    String? transactionId,
    double? amount,
    String? currency,
    String? billingPeriod,
    bool? autoRenew,
    Map<String, dynamic>? metadata,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cancelledDate: cancelledDate ?? this.cancelledDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      autoRenew: autoRenew ?? this.autoRenew,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'plan': plan.name,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'cancelledDate': cancelledDate?.toIso8601String(),
      'paymentMethod': paymentMethod.name,
      'transactionId': transactionId,
      'amount': amount,
      'currency': currency,
      'billingPeriod': billingPeriod,
      'autoRenew': autoRenew,
      'metadata': metadata,
    };
  }

  // Create from JSON
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['userId'],
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == json['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.none,
      ),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      cancelledDate: json['cancelledDate'] != null ? DateTime.parse(json['cancelledDate']) : null,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.creditCard,
      ),
      transactionId: json['transactionId'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      billingPeriod: json['billingPeriod'],
      autoRenew: json['autoRenew'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class PaymentInfo {
  final String id;
  final PaymentMethod method;
  final String? cardLast4;
  final String? cardBrand;
  final DateTime? expiryDate;
  final String? paypalEmail;
  final String? cryptoAddress;
  final bool isDefault;
  final DateTime createdAt;

  PaymentInfo({
    required this.id,
    required this.method,
    this.cardLast4,
    this.cardBrand,
    this.expiryDate,
    this.paypalEmail,
    this.cryptoAddress,
    this.isDefault = false,
    required this.createdAt,
  });

  String get displayName {
    switch (method) {
      case PaymentMethod.creditCard:
        return '•••• $cardLast4';
      case PaymentMethod.paypal:
        return paypalEmail ?? 'PayPal';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.crypto:
        return 'Crypto Wallet';
    }
  }

  PaymentInfo copyWith({
    String? id,
    PaymentMethod? method,
    String? cardLast4,
    String? cardBrand,
    DateTime? expiryDate,
    String? paypalEmail,
    String? cryptoAddress,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return PaymentInfo(
      id: id ?? this.id,
      method: method ?? this.method,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardBrand: cardBrand ?? this.cardBrand,
      expiryDate: expiryDate ?? this.expiryDate,
      paypalEmail: paypalEmail ?? this.paypalEmail,
      cryptoAddress: cryptoAddress ?? this.cryptoAddress,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method.name,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
      'expiryDate': expiryDate?.toIso8601String(),
      'paypalEmail': paypalEmail,
      'cryptoAddress': cryptoAddress,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      id: json['id'],
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.creditCard,
      ),
      cardLast4: json['cardLast4'],
      cardBrand: json['cardBrand'],
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      paypalEmail: json['paypalEmail'],
      cryptoAddress: json['cryptoAddress'],
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class SubscriptionStats {
  final int totalSubscriptions;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final double totalRevenue;
  final String currency;
  final DateTime lastUpdated;

  const SubscriptionStats({
    required this.totalSubscriptions,
    required this.activeSubscriptions,
    required this.expiredSubscriptions,
    required this.totalRevenue,
    required this.currency,
    required this.lastUpdated,
  });

  double get revenuePercentage {
    if (totalSubscriptions == 0) return 0.0;
    return (activeSubscriptions / totalSubscriptions) * 100;
  }

  String get formattedRevenue {
    return '$currency${totalRevenue.toStringAsFixed(2)}';
  }
}
