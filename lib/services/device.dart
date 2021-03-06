import 'dart:async';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType { RESUME }

class Device {
  static const EventChannel _notificationsChannel =
      const EventChannel('com.breez.client/lifecycle_events_notifications');

  final StreamController _eventsController =
      new StreamController<NotificationType>.broadcast();
  Stream get eventStream => _eventsController.stream;

  final _deviceClipboardController = new BehaviorSubject<String>();
  Stream get deviceClipboardStream => _deviceClipboardController.stream;

  String _lastClipping = "";
  static const String LAST_CLIPPING_PREFERENCES_KEY = "lastClipping";

  Device() {
    var sharedPrefrences = SharedPreferences.getInstance();
    sharedPrefrences.then((preferences) {
      _lastClipping = preferences.getString(LAST_CLIPPING_PREFERENCES_KEY) ?? "";
      fetchClipboard(preferences);
    });

    _notificationsChannel.receiveBroadcastStream().listen((event) {
      if (event == "resume") {
        _eventsController.add(NotificationType.RESUME);
        sharedPrefrences.then((preferences) {
          fetchClipboard(preferences);
        });        
      }
    });
  }

  fetchClipboard(SharedPreferences preferences){
    Clipboard.getData("text/plain").then((clipboardData) {
      if (clipboardData != null) {
        var text = clipboardData.text;

        if (text != _lastClipping) {
          _deviceClipboardController.add(text);
          preferences.setString(LAST_CLIPPING_PREFERENCES_KEY, text);
          _lastClipping = text;
        }
      }
    });
  }
}
