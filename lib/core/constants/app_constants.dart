// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();
  // Supabase
  static const supabaseUrl = 'https://xxvicmprwtbxinuluyqx.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_RGFSfrrMcY-uqQrFxNCNaw_Z6D6Jmo2';

  // App
  static const appName = 'EzeeWash';
  static const appVersion = '1.0.0';

  // Colors
  static const primaryColorHex = 0xFF1D4BC7;
  static const secondaryColorHex = 0xFF2F2E98;

  // Breakpoints
  static const mobileBreakpoint = 600.0;
  static const tabletBreakpoint = 900.0;
  static const desktopBreakpoint = 1200.0;

  // Order Statuses
  static const orderPending = 'pending';
  static const orderConfirmed = 'confirmed';
  static const orderPickedUp = 'picked_up';
  static const orderInProcess = 'in_process';
  static const orderReady = 'ready';
  static const orderOutForDelivery = 'out_for_delivery';
  static const orderDelivered = 'delivered';
  static const orderCancelled = 'cancelled';

  // Supabase Table Names
  static const profilesTable = 'profiles';
  static const servicesTable = 'services';
  static const storesTable = 'stores';
  static const ordersTable = 'orders';
  static const orderTimelinesTable = 'order_timelines';
  static const notificationsTable = 'notifications';
  static const reviewsTable = 'reviews';
  static const addressesTable = 'user_addresses';

  //darkmap style

  static const String darkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]''';

}