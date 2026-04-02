// lib/routes/routes_name.dart
class RoutesName {
  RoutesName._();

  static const splash  = '/';
  static const login   = '/login';
  static const main    = '/main';
  static const services = '/services';
  static const orders  = '/orders';
  static const placeOrders    = 'place-orders';
  static const trackOrders    = 'track-orders';
  static const confirmedOrders = 'order-confirmed';
  static const alerts  = '/alerts';
  static const profile = '/profile';
  static const address     = 'address';
  static const helpSupport = 'help-support';
  static const termsPolicy = 'terms-policy';
  static const chatBot     = 'chat-bot';

  // Full navigation paths
  static const alertsNavigate           = alerts;
  static const placeOrdersNavigate      = '$orders/$placeOrders';
  static const trackOrdersNavigate      = '$orders/$trackOrders';
  static const confirmedOrdersNavigate  = '$orders/$confirmedOrders';
  static const addressNavigate          = '$profile/$address';
  static const helpSupportNavigate      = '$profile/$helpSupport';
  static const termsPolicyNavigate      = '$profile/$termsPolicy';
  static const chatBotNavigate          = '$profile/$chatBot';
}