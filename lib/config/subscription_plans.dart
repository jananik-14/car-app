class SubscriptionPlan {
  final String id;
  final String name;
  final int price;
  final int durationDays;
  final String tagline;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.tagline,
    required this.features,
  });
}

class SubscriptionPlans {
  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'yearly',
      name: '1 Year',
      price: 4999,
      durationDays: 365,
      tagline: 'SAVE 58% • BEST VALUE',
      features: [
        'Unlimited bids',
        'Unlimited vehicle listings',
        'Instant RTO verification',
        'Priority lot alerts',
        'Priority support',
      ],
    ),
    SubscriptionPlan(
      id: 'quarterly',
      name: '3 Months',
      price: 1999,
      durationDays: 90,
      tagline: 'SAVE 33%',
      features: [
        'Unlimited bids',
        'Unlimited vehicle listings',
        'Instant RTO verification',
        'Priority lot alerts',
      ],
    ),
    SubscriptionPlan(
      id: 'monthly',
      name: '1 Month',
      price: 999,
      durationDays: 30,
      tagline: '',
      features: [
        'Unlimited bids',
        'Unlimited vehicle listings',
        'Instant RTO verification',
        'Priority lot alerts',
      ],
    ),
  ];

  static SubscriptionPlan? getPlanById(String id) {
    try {
      return plans.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
