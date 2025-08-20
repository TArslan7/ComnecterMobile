import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'models/subscription_plan.dart';
import 'models/user_subscription.dart';
import 'services/monetization_service.dart';
import 'widgets/plan_card.dart';

class SubscriptionScreen extends HookWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = useState<List<SubscriptionPlan>>([]);
    final currentSubscription = useState<UserSubscription?>(null);
    final isLoading = useState(true);
    final isSubscribing = useState(false);

    Future<void> loadData() async {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 500));
      
      final monetizationService = MonetizationService();
      plans.value = monetizationService.getAvailablePlans();
      currentSubscription.value = await monetizationService.getCurrentUserSubscription();
      isLoading.value = false;
    }

    Future<void> subscribeToPlan(SubscriptionPlan plan) async {
      if (plan.tier == SubscriptionTier.free) return;
      
      isSubscribing.value = true;
      try {
        final monetizationService = MonetizationService();
        final success = await monetizationService.subscribeToPlan(plan.id);
        
        if (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully subscribed to ${plan.name}!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          await loadData(); // Refresh data
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to subscribe. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        isSubscribing.value = false;
      }
    }

    useEffect(() {
      loadData();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Go Back',
        ),
        title: const Text('Subscription Plans'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
            onPressed: () => context.push('/friends'),
            tooltip: 'Friends',
          ),
        ],
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current subscription status
                    if (currentSubscription.value != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Subscription',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentSubscription.value!.statusText,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: currentSubscription.value!.isActive 
                                      ? Colors.green 
                                      : Colors.orange,
                                ),
                              ),
                              if (currentSubscription.value!.remainingDays > 0)
                                Text(
                                  '${currentSubscription.value!.remainingDays} days remaining',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Plans section
                    Text(
                      'Choose Your Plan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upgrade to unlock more features and enhance your experience',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Plans grid
                    ...plans.value.map((plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PlanCard(
                        plan: plan,
                        isCurrentPlan: currentSubscription.value?.planId == plan.id,
                        onSubscribe: () => subscribeToPlan(plan),
                        isLoading: isSubscribing.value,
                      ),
                    )),
                  ],
                ),
              ),
            ),
    );
  }
} 