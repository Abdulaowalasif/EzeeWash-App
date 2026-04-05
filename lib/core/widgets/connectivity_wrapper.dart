// lib/core/widgets/connectivity_wrapper.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/no_internet_screen.dart';
import '../service/connectivity_service.dart';
import '../../features/services/presentation/bloc/service_bloc.dart';
import '../../features/services/presentation/bloc/service_event.dart';
import '../../features/store/presentation/bloc/store_bloc.dart';
import '../../features/store/presentation/bloc/stores_event.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';
import '../../features/orders/presentation/bloc/order_event.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final bool isDarkMode; // Add this line
  const ConnectivityWrapper({super.key, required this.child, required this.isDarkMode}); // Update constructor

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late bool _isConnected;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _isConnected = ConnectivityService.instance.isConnected;

    _sub = ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted && online != _isConnected) {
        if (online) {
          _refreshAppData();
        }
        setState(() => _isConnected = online);
      }
    });
  }

  void _refreshAppData() {
    context.read<ServicesBloc>().add(const ServicesLoadRequested());
    context.read<StoresBloc>().add(const StoresLoadRequested());
    context.read<OrdersBloc>().add(const OrdersLoadRequested());
    context.read<ProfileBloc>().add(const ProfileLoadRequested());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            reverseDuration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.05, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: !_isConnected
                ? NoInternetScreen(
              key: const ValueKey('no_internet_screen'),
              isDarkMode: widget.isDarkMode, // Pass the mode here
            )
                : const SizedBox.shrink(key: ValueKey('empty_connectivity_space')),
          ),
        ],
      ),
    );
  }
}