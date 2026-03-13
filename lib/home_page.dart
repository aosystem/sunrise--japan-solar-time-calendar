import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:sunrise/setting_page.dart';
import 'package:sunrise/ad_manager.dart';
import 'package:sunrise/ad_banner_widget.dart';
import 'package:sunrise/my_web_view_controller.dart';
import 'package:sunrise/local_server.dart';
import 'package:sunrise/loading_screen.dart';
import 'package:sunrise/model.dart';
import 'package:sunrise/theme_color.dart';
import 'package:sunrise/main.dart';
import 'package:sunrise/parse_locale_tag.dart';
import 'package:sunrise/theme_mode_number.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});
  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  late AdManager _adManager;
  final MyWebViewController _myWebViewController = MyWebViewController();
  final LocalServer _localServer = LocalServer();
  late final WebViewController _webViewController;
  late final List<int> _yearList;
  late final List<DropdownMenuItem<int>> _yearDropdownItems;
  int _selectedYear = DateTime.now().year;
  //
  late ThemeColor _themeColor;
  bool _isReady = false;
  bool _isFirst = true;
  //
  final List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県',
    '岐阜県', '静岡県', '愛知県', '三重県',
    '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県',
    '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県',
    '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
  ];
  int _selectedPrefecture = 12;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _adManager = AdManager();
    _yearList = _generateYearList();
    _yearDropdownItems = _yearList.map<DropdownMenuItem<int>>((int year) {
      return DropdownMenuItem<int>(
        value: year,
        child: Text(year.toString()),
      );
    }).toList();
    _selectedPrefecture = Model.prefecture;
    _webViewController = _myWebViewController.controller();
    await _localServer.start();
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    _adManager.dispose();
    _localServer.close();
    super.dispose();
  }

  void _updateWebView() async {
    String serverUrl = _localServer.url();
    await _webViewController.loadRequest(Uri.parse('${serverUrl}index.html?year=${_selectedYear}&pref=${_selectedPrefecture}&colorBg=${_themeColor.mainBackColor}'));
  }

  List<int> _generateYearList() {
    int currentYear = DateTime.now().year;
    return List<int>.generate(161, (index) => currentYear - 80 + index);
  }
  void _incrementYear() {
    setState(() {
      if (_selectedYear < _yearList.last) {
        _selectedYear += 1;
      }
      _updateWebView();
    });
  }
  void _decrementYear() {
    setState(() {
      if (_selectedYear > _yearList.first) {
        _selectedYear -= 1;
      }
      _updateWebView();
    });
  }

  Future<void> _onOpenSetting() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingPage()),
    );
    if (!mounted) {
      return;
    }
    if (updated == true) {
      final mainState = context.findAncestorStateOfType<MainAppState>();
      if (mainState != null) {
        mainState
          ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
          ..locale = parseLocaleTag(Model.languageCode)
          ..setState(() {});
      }
      _isFirst = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        body: LoadingScreen(),
      );
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: Model.themeNumber, context: context);
      _updateWebView();
    }
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: _themeColor.mainBackColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: AppBar(
          backgroundColor: _themeColor.mainBackColor,
          title: Text('日の出/日の入り時刻', style: t.titleSmall?.copyWith(color: _themeColor.mainForeColor)),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              color: _themeColor.mainForeColor,
              onPressed: _onOpenSetting,
            ),
            const SizedBox(width:10),
          ]
        )
      ),
      body: SafeArea(
        child: Column(children:[
          Center(
            child: Row(children:[
              const Spacer(),
              _selectYear(),
              const Spacer(),
              _selectPrefecture(),
              const Spacer(flex: 2),
            ])
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 0, left: 8, right: 8, bottom: 0),
              child: Center(
                child: WebViewWidget(controller: _webViewController),
              ),
            )
          ),
        ])
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _selectYear() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: _decrementYear,
        ),
        DropdownButton<int>(
          value: _selectedYear,
          onChanged: (int? newValue) {
            setState(() {
              _selectedYear = newValue!;
              _updateWebView();
            });
          },
          items: _yearDropdownItems,
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: _incrementYear,
        ),
      ],
    );
  }

  Widget _selectPrefecture() {
    return DropdownButton<int>(
      value: _selectedPrefecture,
      onChanged: (int? newIndex) {
        setState(() {
          _selectedPrefecture = newIndex!;
          _updateWebView();
          Model.setPrefecture(_selectedPrefecture);
        });
      },
      items: List.generate(_prefectures.length, (index) {
        return DropdownMenuItem<int>(
          value: index,
          child: Text(_prefectures[index]),
        );
      }),
    );
  }

}
