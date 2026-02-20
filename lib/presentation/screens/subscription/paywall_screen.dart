import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:byure/services/subscription_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:go_router/go_router.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _listenToPurchases();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _subscriptionService.getAvailableProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  void _listenToPurchases() {
    _subscriptionService.purchaseUpdates.listen((purchases) {
      _subscriptionService.verifyPurchaseStatus(purchases);
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription activated!')),
        );
        context.pop();
      }
    });
  }

  Future<void> _purchaseProduct(ProductDetails product) async {
    setState(() => _isPurchasing = true);
    try {
      final success = await _subscriptionService.purchaseSubscription(product);
      if (!success) {
        setState(() => _isPurchasing = false);
      }
    } catch (e) {
      setState(() => _isPurchasing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GuzoMate+'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 60,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Upgrade to GuzoMate+',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Unlock unlimited walks and premium features',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Features list
                  _buildFeatureItem(
                    Icons.all_inclusive,
                    'Unlimited Walk Invites',
                    'Send as many walk invitations as you want',
                  ),
                  _buildFeatureItem(
                    Icons.chat,
                    'Unlimited Messaging',
                    'Chat with all your walking buddies without limits',
                  ),
                  _buildFeatureItem(
                    Icons.filter_alt,
                    'Advanced Filters',
                    'Filter by pace, distance, interests, and more',
                  ),
                  _buildFeatureItem(
                    Icons.route,
                    'Custom Routes',
                    'Create and save your own walking routes',
                  ),
                  _buildFeatureItem(
                    Icons.visibility_off,
                    'Ghost Mode',
                    'Hide your distance from others',
                  ),
                  _buildFeatureItem(
                    Icons.block,
                    'Ad-Free Experience',
                    'Enjoy walking without interruptions',
                  ),
                  _buildFeatureItem(
                    Icons.priority_high,
                    'Priority Visibility',
                    'Get seen first on the map',
                  ),
                  const SizedBox(height: 32),
                  // Subscription options
                  if (_products.isNotEmpty) ...[
                    ..._products.map((product) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 2,
                          child: ListTile(
                            title: Text(product.title),
                            subtitle: Text(product.description),
                            trailing: Text(
                              product.price,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: _isPurchasing
                                ? null
                                : () => _purchaseProduct(product),
                          ),
                        ),
                      );
                    }),
                  ] else
                    ElevatedButton(
                      onPressed: _isPurchasing ? null : _loadProducts,
                      child: const Text('Load Subscription Options'),
                    ),
                  const SizedBox(height: 16),
                  // Restore purchases
                  TextButton(
                    onPressed: () async {
                      await _subscriptionService.restorePurchases();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Purchases restored'),
                          ),
                        );
                      }
                    },
                    child: const Text('Restore Purchases'),
                  ),
                  const SizedBox(height: 8),
                  // Terms
                  Text(
                    'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscription will auto-renew unless cancelled.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


