import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing subscriptions
class SubscriptionService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static const String _premiumStatusKey = 'is_premium';
  static const String _subscriptionProductId = 'guzomate_plus_monthly';

  /// Check if user has active premium subscription
  Future<bool> isPremium() async {
    try {
      // Check local cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedPremium = prefs.getBool(_premiumStatusKey);
      if (cachedPremium != null) {
        return cachedPremium;
      }

      await _inAppPurchase.restorePurchases();
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get available subscription products
  Future<List<ProductDetails>> getAvailableProducts() async {
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        throw Exception('In-app purchases not available');
      }

      const productIds = {_subscriptionProductId};
      final response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      return response.productDetails;
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  /// Purchase subscription
  Future<bool> purchaseSubscription(ProductDetails productDetails) async {
    try {
      final purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      return success;
    } catch (e) {
      throw Exception('Failed to purchase subscription: $e');
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      throw Exception('Failed to restore purchases: $e');
    }
  }

  /// Listen to purchase updates
  Stream<List<PurchaseDetails>> get purchaseUpdates =>
      _inAppPurchase.purchaseStream;

  /// Verify and update premium status
  Future<void> verifyPurchaseStatus(List<PurchaseDetails> purchases) async {
    final prefs = await SharedPreferences.getInstance();
    
    for (var purchase in purchases) {
      if (purchase.productID == _subscriptionProductId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await prefs.setBool(_premiumStatusKey, true);
          
          // Mark as complete
          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }
        } else if (purchase.status == PurchaseStatus.error) {
          await prefs.setBool(_premiumStatusKey, false);
        }
      }
    }
  }

  bool _hasActiveSubscription(List<PurchaseDetails> purchases) {
    return purchases.any((purchase) =>
        purchase.productID == _subscriptionProductId &&
        (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored));
  }

  /// Check daily walk invite limit (1 for free, unlimited for premium)
  Future<bool> canSendWalkInvite(String userId) async {
    final isPremiumUser = await isPremium();
    if (isPremiumUser) return true;

    // Check daily limit for free users
    final prefs = await SharedPreferences.getInstance();
    final lastInviteDate = prefs.getString('last_walk_invite_date_$userId');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastInviteDate == today) {
      return false; // Already sent invite today
    }

    return true;
  }

  /// Record walk invite sent
  Future<void> recordWalkInviteSent(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('last_walk_invite_date_$userId', today);
  }
}

