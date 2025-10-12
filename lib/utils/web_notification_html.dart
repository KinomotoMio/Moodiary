// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

Future<bool> requestPermission() async {
  if (!html.Notification.supported) {
    return false;
  }
  final permission = html.Notification.permission;
  if (permission == 'granted') {
    return true;
  }
  if (permission == 'denied') {
    return false;
  }
  final result = await html.Notification.requestPermission();
  return result == 'granted';
}

bool canShowNotifications() {
  return html.Notification.supported &&
      html.Notification.permission == 'granted';
}

void showNotification({required String title, required String body}) {
  if (!canShowNotifications()) {
    return;
  }
  html.Notification(title, body: body);
}
