enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  pending,
  trial,
}

class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? cancelledAt;
  final DateTime? trialEndDate;
  final int remainingDays;
  final bool autoRenew;
  final String? paymentMethodId;
  final double amountPaid;
  final String currency;

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.cancelledAt,
    this.trialEndDate,
    required this.remainingDays,
    required this.autoRenew,
    this.paymentMethodId,
    required this.amountPaid,
    required this.currency,
  });

  bool get isActive => status == SubscriptionStatus.active;
  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isCancelled => status == SubscriptionStatus.cancelled;
  bool get isTrial => status == SubscriptionStatus.trial;
  bool get hasTrial => trialEndDate != null;
  bool get isTrialExpired => trialEndDate != null && DateTime.now().isAfter(trialEndDate!);

  String get statusText {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.pending:
        return 'Pending';
      case SubscriptionStatus.trial:
        return 'Trial';
    }
  }

  UserSubscription copyWith({
    String? id,
    String? userId,
    String? planId,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? cancelledAt,
    DateTime? trialEndDate,
    int? remainingDays,
    bool? autoRenew,
    String? paymentMethodId,
    double? amountPaid,
    String? currency,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      remainingDays: remainingDays ?? this.remainingDays,
      autoRenew: autoRenew ?? this.autoRenew,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      amountPaid: amountPaid ?? this.amountPaid,
      currency: currency ?? this.currency,
    );
  }
} 