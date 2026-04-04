// lib/routes/routes_name.dart
class RoutesName {
  RoutesName._();

  static const splash          = '/';
  static const onboarding      = '/onboarding'; // ← NEW
  static const login           = '/login';
  static const home            = '/home';
  static const services        = '/services';
  static const orders          = '/orders';
  static const placeOrders     = 'place-orders';
  static const trackOrders     = 'track-orders';
  static const confirmedOrders = 'order-confirmed';
  static const alerts          = '/alerts';
  static const settings        = 'settings';
  static const address         = 'address';
  static const helpSupport     = 'help-support';
  static const termsPolicy     = 'terms-policy';
  static const changePassword     = 'change-password';
  static const chatBot         = '/chat-bot';

  // Full navigation paths
  static const alertsNavigate          = alerts;
  static const placeOrdersNavigate     = '$orders/$placeOrders';
  static const trackOrdersNavigate     = '$orders/$trackOrders';
  static const confirmedOrdersNavigate = '$orders/$confirmedOrders';
  static const addressNavigate         = '$home/$address';
  static const changePasswordNavigate  = '$home/$changePassword';
  static const helpSupportNavigate     = '$home/$helpSupport';
  static const termsPolicyNavigate     = '$home/$termsPolicy';
  static const chatBotNavigate         = '$home/$chatBot';
  static const settingsNavigate        = '$home/$settings';
}
