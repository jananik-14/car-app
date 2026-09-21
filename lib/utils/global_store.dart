import 'package:flutter/material.dart';

class GlobalStore {
  // Global notifications list
  static List<Map<String, dynamic>> notifications = [];

  // Global pending subscriptions list
  static List<Map<String, dynamic>> pendingSubscriptions = [];
}
