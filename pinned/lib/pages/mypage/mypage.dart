import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pinned/apis/mypageAPI.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:pinned/pages/main/selectPage.dart';
import 'package:pinned/class/storageService.dart';
import 'package:restart_app/restart_app.dart';
import 'package:pinned/apis/homeAPI.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:convert'; // for jsonDecode

class MyPage extends StatefulWidget {
  final String email;
  final int character;
  const MyPage({super.key, required this.email, required this.character});

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final StorageService storage = StorageService();
  List<double> scores = []; // 점수 데이터를 double로 저장
  List<String> dates = [];
  int selectedChar = 0;
  String userName = "";

  @override
  void initState() {
    super.initState();
    // 위젯이 초기화될 때 getTest 호출
    _getUserData();
    tokenCheck();
  }

  Future<void> deleteToken() async {
    await storage.deleteData('jwt_token');
  }

  Future<Map<String, dynamic>?> checkToken() async {
    final token = await storage.getData('jwt_token');

    if (token == null || Jwt.isExpired(token)) {
      return null;
    }

    try {
      Map<String, dynamic> payload = Jwt.parseJwt(token);
      return payload;
    } catch (e) {
      return null;
    }
  }

  Future<void> tokenCheck() async {
    final tokenInfo = await checkToken();
    print(tokenInfo);
  }

  Future<void> _getUserData() async {
    try {
      final response = await Mypageapi.getTest(widget.email);
      final data = json.decode(response!.body);

      setState(
        () {
          scores = List<double>.from(
            data['test']['scores'].map(
              (e) => e['score'].toDouble(),
            ),
          );
          scores = scores.sublist((scores.length > 5) ? scores.length - 5 : 0);
          dates = List<String>.from(
            data['test']['scores'].map(
              (e) => e['createdAt'].substring(
                5,
              ),
            ),
          );
          dates = dates.sublist((dates.length > 5) ? dates.length - 5 : 0);
          selectedChar = data['user']['character'];
          userName = data['user']['name'];
        },
      );
    } catch (e) {
      return;
    }
  }

  Future<void> _changeCharacter(int value) async {
    try {
      await Mypageapi.changeCharacter(widget.email, value);
    } catch (e) {
      return;
    }
  }

  SvgPicture getImage(int value) {
    if (value == 0) {
      return SvgPicture.asset(
        'assets/images/Koala.svg',
        height: 80,
        width: 320,
      );
    } else if (value == 1) {
      return SvgPicture.asset(
        'assets/images/Kangeroo.svg',
        height: 80,
        width: 320,
      );
    } else {
      return SvgPicture.asset(
        'assets/images/Quoka.svg',
        height: 80,
        width: 320,
      );
    }
  }

  String getName(int value) {
    if (value == 0) {
      return tr("coco");
    } else if (value == 1) {
      return tr("ruru");
    } else {
      return tr("kiki");
    }
  }

  void toggleSelect(int value) {
    setState(() {
      selectedChar = value;
      _changeCharacter(value); // 선택된 캐릭터의 인덱스 업데이트
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      extendBody: true,
      extendBodyBehindAppBar: false,
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFFFFFFF),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$userName${'greeting'.tr()}',
                  style: TextStyle(
                    fontFamily: 'LeeSeoYun',
                    fontSize: 24,
                  ),
                ),
                DropdownButton<String>(
                  value:
                      context.locale.languageCode == 'ko' ? '한국어' : 'English',
                  items: ['한국어', 'English']
                      .map<DropdownMenuItem<String>>((String i) {
                    return DropdownMenuItem<String>(
                      value: i,
                      child: Text(i),
                    );
                  }).toList(),
                  onChanged: (String? value) async {
                    if (value == '한국어') {
                      await context.setLocale(Locale('ko', 'KR'));
                    } else if (value == 'English') {
                      await context.setLocale(Locale('en', 'US'));
                    }
                    setState(() {});
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AlertDialog(
                              backgroundColor: Color(0xffFFFFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              content: Container(
                                padding: EdgeInsets.only(
                                  top: 20,
                                  right: 10,
                                  left: 10,
                                  bottom: 0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tr("logout_check"),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ).tr(),
                                    SizedBox(
                                      height: 16,
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xffFF516A),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        fixedSize: Size(250, 31),
                                      ),
                                      onPressed: () {
                                        deleteToken();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SelectPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        tr("confirm"),
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ).tr(),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        tr("No"),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ).tr(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              top: -265,
                              child: SvgPicture.asset(
                                'assets/images/dialogKoKo.svg',
                                fit: BoxFit.none,
                                width: 50,
                                height: 50,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    backgroundColor: Color(0xffE9E9E9),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    shadowColor: Colors.transparent,
                  ),
                  child: Text(
                    'logout',
                    style: TextStyle(color: Color(0xff333333), fontSize: 16),
                  ).tr(),
                ),
              ],
            ),
            SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 32 / 29,
              child: Container(
                padding:
                    EdgeInsets.only(top: 18, bottom: 18, right: 22, left: 22),
                decoration: BoxDecoration(
                  color: Color(0xffF8F8F8),
                  borderRadius: BorderRadius.all(
                    Radius.circular(15),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'emotion_graph',
                      style: TextStyle(
                        fontFamily: 'LeeSeoYun',
                        fontSize: 18,
                      ),
                    ).tr(),
                    Expanded(
                      child: scores.isEmpty
                          ? Center(child: Text("loading_data").tr())
                          : Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 36),
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawHorizontalLine: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (value) =>
                                          FlLine(
                                        color: Color(0xffe0e0e0), // 격자선 색상
                                        strokeWidth: 1,
                                      ),
                                      horizontalInterval: 10,
                                    ),
                                    titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            getTitlesWidget: (value, meta) {
                                              if (value % 10 == 0) {
                                                return Text(
                                                  '${value.toInt()}',
                                                  style: TextStyle(
                                                    color: Color(0xff7589a2),
                                                    fontSize: 12,
                                                  ),
                                                );
                                              }
                                              return Container();
                                            },
                                            interval: 10,
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            getTitlesWidget: (value, meta) {
                                              if (value.toInt() <
                                                  dates.length) {
                                                return Text(
                                                  dates[value.toInt()],
                                                  style: TextStyle(
                                                    color: Color(0xff7589a2),
                                                    fontSize: 12,
                                                  ),
                                                );
                                              }
                                              return Container();
                                            },
                                            interval: 1,
                                          ),
                                        ),
                                        topTitles: AxisTitles(),
                                        rightTitles: AxisTitles()),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        top: BorderSide(
                                          color: Color(0xffCCCCCC),
                                          width: 1,
                                        ),
                                        bottom: BorderSide(
                                          color: Color(0xffCCCCCC),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    minX: 0,
                                    maxX: 4,
                                    minY: 0,
                                    maxY: 30, // Y축 최대값 설정
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: scores
                                            .asMap()
                                            .entries
                                            .map((entry) => FlSpot(
                                                  entry.key.toDouble(),
                                                  entry.value,
                                                ))
                                            .toList(),
                                        isCurved: false,
                                        color: Color(0xffFF5C5C), // 선 색상
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,

                                          checkToShowDot: (spot, _) =>
                                              true, // 모든 점 표시
                                        ),
                                        belowBarData: BarAreaData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Text(
              'change_character',
              style: TextStyle(
                fontFamily: 'LeeSeoYun',
                fontSize: 18,
              ),
            ).tr(),
            SizedBox(
              height: 21,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 3; i++) ...[
                  _getCharacterButton(i),
                  if (i < 2) const SizedBox(width: 19), // 버튼 간 간격
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCharacterButton(int i) {
    return Column(
      children: [
        SizedBox(
          width: 103,
          height: 142,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xffFFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              side: BorderSide(
                color: selectedChar == i
                    ? const Color(0xffFB5D6F)
                    : const Color(0xffDADADA),
                width: 2.0,
              ),
              padding: const EdgeInsets.all(6),
            ),
            onPressed: () => {toggleSelect(i)},
            child: getImage(i),
          ),
        ),
        SizedBox(
          height: 17,
        ),
        Text(
          getName(i),
          style: TextStyle(fontFamily: 'LeeSeoYun', fontSize: 25),
          textAlign: TextAlign.center,
        ).tr(),
      ],
    );
  }
}
