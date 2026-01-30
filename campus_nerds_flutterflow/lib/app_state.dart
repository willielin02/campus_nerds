import 'package:flutter/material.dart';
import 'flutter_flow/request_manager.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/api_requests/api_manager.dart';
import 'backend/supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _currentCityName =
          prefs.getString('ff_currentCityName') ?? _currentCityName;
    });
    _safeInit(() {
      _currentCityId = prefs.getString('ff_currentCityId') ?? _currentCityId;
    });
    _safeInit(() {
      _queryEventsForTaipeiStudyCounts =
          prefs.getInt('ff_queryEventsForTaipeiStudyCounts') ??
              _queryEventsForTaipeiStudyCounts;
    });
    _safeInit(() {
      _queryEventsForTaoyuanStudyCounts =
          prefs.getInt('ff_queryEventsForTaoyuanStudyCounts') ??
              _queryEventsForTaoyuanStudyCounts;
    });
    _safeInit(() {
      _queryEventsForHsinchuStudyCounts =
          prefs.getInt('ff_queryEventsForHsinchuStudyCounts') ??
              _queryEventsForHsinchuStudyCounts;
    });
    _safeInit(() {
      _queryEventsForTaichungStudyCounts =
          prefs.getInt('ff_queryEventsForTaichungStudyCounts') ??
              _queryEventsForTaichungStudyCounts;
    });
    _safeInit(() {
      _queryEventsForChiayiStudyCounts =
          prefs.getInt('ff_queryEventsForChiayiStudyCounts') ??
              _queryEventsForChiayiStudyCounts;
    });
    _safeInit(() {
      _queryEventsForTainanStudyCounts =
          prefs.getInt('ff_queryEventsForTainanStudyCounts') ??
              _queryEventsForTainanStudyCounts;
    });
    _safeInit(() {
      _queryEventsForKaohsiungStudyCounts =
          prefs.getInt('ff_queryEventsForKaohsiungStudyCounts') ??
              _queryEventsForKaohsiungStudyCounts;
    });
    _safeInit(() {
      _queryEventsForTaipeiGamesCounts =
          prefs.getInt('ff_queryEventsForTaipeiGamesCounts') ??
              _queryEventsForTaipeiGamesCounts;
    });
    _safeInit(() {
      _queryEventsForTaoyuanGamesCounts =
          prefs.getInt('ff_queryEventsForTaoyuanGamesCounts') ??
              _queryEventsForTaoyuanGamesCounts;
    });
    _safeInit(() {
      _queryEventsForHsinchuGamesCounts =
          prefs.getInt('ff_queryEventsForHsinchuGamesCounts') ??
              _queryEventsForHsinchuGamesCounts;
    });
    _safeInit(() {
      _queryEventsForTaichungGamesCounts =
          prefs.getInt('ff_queryEventsForTaichungGamesCounts') ??
              _queryEventsForTaichungGamesCounts;
    });
    _safeInit(() {
      _queryEventsForChiayiGamesCounts =
          prefs.getInt('ff_queryEventsForChiayiGamesCounts') ??
              _queryEventsForChiayiGamesCounts;
    });
    _safeInit(() {
      _queryEventsForTainanGamesCounts =
          prefs.getInt('ff_queryEventsForTainanGamesCounts') ??
              _queryEventsForTainanGamesCounts;
    });
    _safeInit(() {
      _queryEventsForKaohsiungGamesCounts =
          prefs.getInt('ff_queryEventsForKaohsiungGamesCounts') ??
              _queryEventsForKaohsiungGamesCounts;
    });
    _safeInit(() {
      _allowedDomains =
          prefs.getStringList('ff_allowedDomains') ?? _allowedDomains;
    });
    _safeInit(() {
      _studyBalance = prefs.getInt('ff_studyBalance') ?? _studyBalance;
    });
    _safeInit(() {
      _gamesBalance = prefs.getInt('ff_gamesBalance') ?? _gamesBalance;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  String _currentCityName = '臺北';
  String get currentCityName => _currentCityName;
  set currentCityName(String value) {
    _currentCityName = value;
    prefs.setString('ff_currentCityName', value);
  }

  String _currentCityId = '2e7c8bc4-232b-4423-9526-002fc27ed1d3';
  String get currentCityId => _currentCityId;
  set currentCityId(String value) {
    _currentCityId = value;
    prefs.setString('ff_currentCityId', value);
  }

  int _queryEventsForTaipeiStudyCounts = 3;
  int get queryEventsForTaipeiStudyCounts => _queryEventsForTaipeiStudyCounts;
  set queryEventsForTaipeiStudyCounts(int value) {
    _queryEventsForTaipeiStudyCounts = value;
    prefs.setInt('ff_queryEventsForTaipeiStudyCounts', value);
  }

  int _queryEventsForTaoyuanStudyCounts = 3;
  int get queryEventsForTaoyuanStudyCounts => _queryEventsForTaoyuanStudyCounts;
  set queryEventsForTaoyuanStudyCounts(int value) {
    _queryEventsForTaoyuanStudyCounts = value;
    prefs.setInt('ff_queryEventsForTaoyuanStudyCounts', value);
  }

  int _queryEventsForHsinchuStudyCounts = 3;
  int get queryEventsForHsinchuStudyCounts => _queryEventsForHsinchuStudyCounts;
  set queryEventsForHsinchuStudyCounts(int value) {
    _queryEventsForHsinchuStudyCounts = value;
    prefs.setInt('ff_queryEventsForHsinchuStudyCounts', value);
  }

  int _queryEventsForTaichungStudyCounts = 3;
  int get queryEventsForTaichungStudyCounts =>
      _queryEventsForTaichungStudyCounts;
  set queryEventsForTaichungStudyCounts(int value) {
    _queryEventsForTaichungStudyCounts = value;
    prefs.setInt('ff_queryEventsForTaichungStudyCounts', value);
  }

  int _queryEventsForChiayiStudyCounts = 3;
  int get queryEventsForChiayiStudyCounts => _queryEventsForChiayiStudyCounts;
  set queryEventsForChiayiStudyCounts(int value) {
    _queryEventsForChiayiStudyCounts = value;
    prefs.setInt('ff_queryEventsForChiayiStudyCounts', value);
  }

  int _queryEventsForTainanStudyCounts = 3;
  int get queryEventsForTainanStudyCounts => _queryEventsForTainanStudyCounts;
  set queryEventsForTainanStudyCounts(int value) {
    _queryEventsForTainanStudyCounts = value;
    prefs.setInt('ff_queryEventsForTainanStudyCounts', value);
  }

  int _queryEventsForKaohsiungStudyCounts = 3;
  int get queryEventsForKaohsiungStudyCounts =>
      _queryEventsForKaohsiungStudyCounts;
  set queryEventsForKaohsiungStudyCounts(int value) {
    _queryEventsForKaohsiungStudyCounts = value;
    prefs.setInt('ff_queryEventsForKaohsiungStudyCounts', value);
  }

  int _queryEventsForTaipeiGamesCounts = 3;
  int get queryEventsForTaipeiGamesCounts => _queryEventsForTaipeiGamesCounts;
  set queryEventsForTaipeiGamesCounts(int value) {
    _queryEventsForTaipeiGamesCounts = value;
    prefs.setInt('ff_queryEventsForTaipeiGamesCounts', value);
  }

  int _queryEventsForTaoyuanGamesCounts = 3;
  int get queryEventsForTaoyuanGamesCounts => _queryEventsForTaoyuanGamesCounts;
  set queryEventsForTaoyuanGamesCounts(int value) {
    _queryEventsForTaoyuanGamesCounts = value;
    prefs.setInt('ff_queryEventsForTaoyuanGamesCounts', value);
  }

  int _queryEventsForHsinchuGamesCounts = 3;
  int get queryEventsForHsinchuGamesCounts => _queryEventsForHsinchuGamesCounts;
  set queryEventsForHsinchuGamesCounts(int value) {
    _queryEventsForHsinchuGamesCounts = value;
    prefs.setInt('ff_queryEventsForHsinchuGamesCounts', value);
  }

  int _queryEventsForTaichungGamesCounts = 3;
  int get queryEventsForTaichungGamesCounts =>
      _queryEventsForTaichungGamesCounts;
  set queryEventsForTaichungGamesCounts(int value) {
    _queryEventsForTaichungGamesCounts = value;
    prefs.setInt('ff_queryEventsForTaichungGamesCounts', value);
  }

  int _queryEventsForChiayiGamesCounts = 3;
  int get queryEventsForChiayiGamesCounts => _queryEventsForChiayiGamesCounts;
  set queryEventsForChiayiGamesCounts(int value) {
    _queryEventsForChiayiGamesCounts = value;
    prefs.setInt('ff_queryEventsForChiayiGamesCounts', value);
  }

  int _queryEventsForTainanGamesCounts = 3;
  int get queryEventsForTainanGamesCounts => _queryEventsForTainanGamesCounts;
  set queryEventsForTainanGamesCounts(int value) {
    _queryEventsForTainanGamesCounts = value;
    prefs.setInt('ff_queryEventsForTainanGamesCounts', value);
  }

  int _queryEventsForKaohsiungGamesCounts = 3;
  int get queryEventsForKaohsiungGamesCounts =>
      _queryEventsForKaohsiungGamesCounts;
  set queryEventsForKaohsiungGamesCounts(int value) {
    _queryEventsForKaohsiungGamesCounts = value;
    prefs.setInt('ff_queryEventsForKaohsiungGamesCounts', value);
  }

  List<String> _allowedDomains = [];
  List<String> get allowedDomains => _allowedDomains;
  set allowedDomains(List<String> value) {
    _allowedDomains = value;
    prefs.setStringList('ff_allowedDomains', value);
  }

  void addToAllowedDomains(String value) {
    allowedDomains.add(value);
    prefs.setStringList('ff_allowedDomains', _allowedDomains);
  }

  void removeFromAllowedDomains(String value) {
    allowedDomains.remove(value);
    prefs.setStringList('ff_allowedDomains', _allowedDomains);
  }

  void removeAtIndexFromAllowedDomains(int index) {
    allowedDomains.removeAt(index);
    prefs.setStringList('ff_allowedDomains', _allowedDomains);
  }

  void updateAllowedDomainsAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    allowedDomains[index] = updateFn(_allowedDomains[index]);
    prefs.setStringList('ff_allowedDomains', _allowedDomains);
  }

  void insertAtIndexInAllowedDomains(int index, String value) {
    allowedDomains.insert(index, value);
    prefs.setStringList('ff_allowedDomains', _allowedDomains);
  }

  int _studyBalance = 0;
  int get studyBalance => _studyBalance;
  set studyBalance(int value) {
    _studyBalance = value;
    prefs.setInt('ff_studyBalance', value);
  }

  int _gamesBalance = 0;
  int get gamesBalance => _gamesBalance;
  set gamesBalance(int value) {
    _gamesBalance = value;
    prefs.setInt('ff_gamesBalance', value);
  }

  final _myEventsUpcomingManager = FutureRequestManager<List<MyEventsVRow>>();
  Future<List<MyEventsVRow>> myEventsUpcoming({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<List<MyEventsVRow>> Function() requestFn,
  }) =>
      _myEventsUpcomingManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearMyEventsUpcomingCache() => _myEventsUpcomingManager.clear();
  void clearMyEventsUpcomingCacheKey(String? uniqueKey) =>
      _myEventsUpcomingManager.clearRequest(uniqueKey);

  final _myEventsHistoryManager = FutureRequestManager<List<MyEventsVRow>>();
  Future<List<MyEventsVRow>> myEventsHistory({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<List<MyEventsVRow>> Function() requestFn,
  }) =>
      _myEventsHistoryManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearMyEventsHistoryCache() => _myEventsHistoryManager.clear();
  void clearMyEventsHistoryCacheKey(String? uniqueKey) =>
      _myEventsHistoryManager.clearRequest(uniqueKey);

  final _homeFocusedStudyManager = FutureRequestManager<List<HomeEventsVRow>>();
  Future<List<HomeEventsVRow>> homeFocusedStudy({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<List<HomeEventsVRow>> Function() requestFn,
  }) =>
      _homeFocusedStudyManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearHomeFocusedStudyCache() => _homeFocusedStudyManager.clear();
  void clearHomeFocusedStudyCacheKey(String? uniqueKey) =>
      _homeFocusedStudyManager.clearRequest(uniqueKey);

  final _homeEnglishGamesManager = FutureRequestManager<List<HomeEventsVRow>>();
  Future<List<HomeEventsVRow>> homeEnglishGames({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<List<HomeEventsVRow>> Function() requestFn,
  }) =>
      _homeEnglishGamesManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearHomeEnglishGamesCache() => _homeEnglishGamesManager.clear();
  void clearHomeEnglishGamesCacheKey(String? uniqueKey) =>
      _homeEnglishGamesManager.clearRequest(uniqueKey);
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
