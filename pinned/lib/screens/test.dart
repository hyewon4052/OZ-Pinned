import 'package:flutter/material.dart';
import 'KoreanList.dart';
import 'EnglishList.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'meditation.dart';
import 'chatbot.dart';
import 'package:easy_localization/easy_localization.dart';

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: TestPage(lang: true),
//     );
//   }
// }

class TestPage extends StatefulWidget {
  final String email;
  final String name;
  const TestPage({super.key, required this.email, required this.name});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> with WidgetsBindingObserver {
  late List<Map<String, dynamic>> testList;

  int testNum = 0; // 현재 질문 번호
  int totalScore = 0; // 총 점수
  Map<String, dynamic>? selectedAnswer; // 현재 선택된 답변
  List<Map<String, dynamic>> selectedAnswers = []; // 선택된 답변 리스트 추가
  bool _isPopupShown = false;
  String lan = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    lan = Localizations.localeOf(context).languageCode;
    testList = Localizations.localeOf(context).languageCode == 'en'
        ? englishList
        : koreanList;

    if (!_isPopupShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showPopup();
        _isPopupShown = true; // 팝업 표시 상태 업데이트
      });
    }
  }

// 팝업 표시 함수
  void showPopup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenPopup = prefs.getBool('hasSeenPopup') ?? false;

    // 팝업이 이전에 표시되지 않았을 때만 실행
    if (!hasSeenPopup) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            content: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "지난 2주 이내의 감정을\n바탕으로 선택해주세요!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Pretendard",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 25,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffFF516A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      fixedSize: Size(201, 31),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '확인',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      prefs.setBool('hasSeenPopup', true); // 팝업 본 상태 저장
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      "다시 보지 않기",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn); // 부모의 setState 호출

    // 조건에 따라 testList 초기화 (setState 내부에서 초기화하는 것이 아닌, 이미 초기화된 상태에서 업데이트 필요)
    if (lan == 'en') {
      testList = englishList;
    } else {
      testList = koreanList;
    }
  }

  // 답변 버튼 클릭 시 호출
  void answerPressed(Map<String, dynamic> answer) {
    setState(() {
      selectedAnswer = answer; // 선택된 답변 저장
    });
  }

  // 다음 질문 또는 결과 페이지로 이동
  void nextQuestion() {
    if (selectedAnswer != null) {
      setState(() {
        // 선택된 답변을 저장하고 점수 합산
        selectedAnswers.add(selectedAnswer!);
        totalScore += int.parse(selectedAnswer!['score']);

        // 다음 질문으로 이동
        if (testNum < testList.length - 1) {
          testNum++;
        } else {
          // 결과 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultPage(
                totalScore: totalScore,
                selectedAnswers: selectedAnswers,
                email: widget.email,
                name: widget.name,
              ),
            ),
          );
        }
      });
    }
  }

  // 이전 질문으로 이동
  void prevQuestion() {
    if (testNum > 0) {
      setState(() {
        testNum--; // 질문 번호 감소
        // 이전 질문의 선택 답변 정보 제거
        if (selectedAnswers.isNotEmpty) {
          totalScore -= int.parse(selectedAnswers.removeLast()['score']);
        }
        selectedAnswer = null; // 선택 초기화
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 350,
              height: 9,
              child: LinearProgressIndicator(
                value: (testNum + 1) / testList.length,
                color: Color(0xffFF516A),
                backgroundColor: Color(0xffF2F2F2),
                borderRadius: BorderRadius.circular(4.5),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 47),
            child: Text(
              '${testNum + 1}.',
              style: TextStyle(fontFamily: 'LeeSeoYun', fontSize: 20),
            ),
          ),
          Padding(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: 48),
              child: SizedBox(
                height: 60,
                child: Text(
                  testList[testNum]['questionText'],
                  style: TextStyle(fontFamily: 'LeeSeoYun', fontSize: 22),
                ),
              )),
          ...(testList[testNum]['answers'] as List<Map<String, dynamic>>)
              .map((answer) {
            return Container(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: selectedAnswer == answer
                    ? Color(0xffFFF1F1)
                    : Colors.white, // 선택 여부에 따라 배경색 변경
                border: Border.all(
                  color: selectedAnswer == answer
                      ? Color(0xffFF516A)
                      : Color(0xffBBBBBB), // 선택 여부에 따라 테두리 색상 변경
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => answerPressed(answer),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.5, horizontal: 21),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        answer['text'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      if (selectedAnswer == answer)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(255, 81, 106, 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xffFF516A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 버튼 간격
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20),
                child: ElevatedButton(
                  onPressed: testNum > 0 ? prevQuestion : null,
                  style: ElevatedButton.styleFrom(
                    side: BorderSide(
                      width: 1.0,
                      color: Color(0xffFF516A),
                    ),
                    fixedSize: Size(170, 50),
                    backgroundColor: testNum > 0 ? Colors.white : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ), // 이전 버튼
                  child: Text(
                    tr("before"),
                    style: TextStyle(fontSize: 18, color: Color(0xffFF516A)),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 20),
                child: ElevatedButton(
                  onPressed: selectedAnswer != null ? nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(170, 50),
                    backgroundColor: selectedAnswer != null
                        ? Color(0xffFF516A)
                        : Color(0xffFFB3B3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ), // 다음 버튼
                  child: Text(
                    testNum < testList.length - 1 ? tr("next") : tr("result"),
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class ResultPage extends StatefulWidget {
  final int totalScore;
  final List selectedAnswers;
  final String email;
  final String name;
  const ResultPage({
    super.key,
    required this.totalScore,
    required this.selectedAnswers,
    required this.email,
    required this.name,
  });

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String today = "";
  String lan = "";

  @override
  void initState() {
    super.initState();
    getToday(); // 화면 초기화 시 날짜 설정
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    lan = Localizations.localeOf(context).languageCode;
    print(lan);
  }

  // 날짜를 가져오는 함수
  String getToday() {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy.MM.dd');
    String strToday = formatter.format(now);

    return strToday;
  }

  String getTime() {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('H:m');
    String strToday = formatter.format(now);

    return strToday;
  }

  // 이메일을 비동기적으로 가져오는 함수
  Future<String?> getEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('email'); // 'email' 키에 저장된 값 반환
  }

  // 점수에 따른 결과 반환하는 함수
  String getResult(int totalScore) {
    save(totalScore); // 이메일을 받아오고 점수를 저장
    if (lan != "en") {
      if (totalScore >= 20) {
        return "매우 심함";
      } else if (totalScore >= 15) {
        return "약간 심함";
      } else if (totalScore >= 10) {
        return "중간";
      } else if (totalScore >= 5) {
        return "경미";
      } else
        return "정상";
    } else {
      if (totalScore >= 20) {
        return "Severe Level";
      } else if (totalScore >= 15) {
        return "Mildly Severe Level";
      } else if (totalScore >= 10) {
        return "Moderate Level";
      } else if (totalScore >= 5) {
        return "Mild Leve";
      } else
        return "Normal";
    }
  }

  String getResultContent(int totalScore) {
    save(totalScore); // 이메일을 받아오고 점수를 저장
    if (lan != "en") {
      if (totalScore >= 20) {
        return "광범위한 우을 증상을 매우 자주, 심한 수준에서 경험하는 것으로 보고하였습니다.\n일상생활의 다양한 영역에서 어려움이 초래될 경우 정신건강 전문가의 도움을 받는 것을 권해드립니다.";
      } else if (totalScore >= 15) {
        return "약간 심한 수준의 우울감을 자주 경험하는 것으로 보고하였습니다.\n직업적/사회적 적응에 일부 영향을 미칠 경우 정신건강 전문가의 도움을 받아 보시기를 권해 드립니다.";
      } else if (totalScore >= 10) {
        return "중간 수준의 우울감을 비교적 자주 경험하는 것으로 보고하였습니다.\n직업적/사회적 적응에 일부 영향을 미칠 수 있어 주의 깊은 관찰과 관심이 필요합니다.";
      } else if (totalScore >= 5) {
        return "경미한 수준의 우울감이 있으나 일상생활에 지장을 줄 정도는 아닙니다.";
      } else
        return "적응상의 지장을 초래할만한 우울 관련 증상을 거의 보고하지 않았습니다.";
    } else {
      if (totalScore >= 20) {
        return "You experience severe symptoms of depression very frequently. If difficulties persist across various areas of daily life, additional evaluation and assistance from a mental health professional are strongly advised.";
      } else if (totalScore >= 15) {
        return "You frequently experience mildly severe levels of depression, which may affect your professional and social functioning. It is recommended to seek help from a mental health professional.";
      } else if (totalScore >= 10) {
        return "You frequently experience moderate levels of depression. It may have some impact on your professional or social life, so careful attention and interest are required.";
      } else if (totalScore >= 5) {
        return "You experience mild levels of depression, but it does not significantly interfere with daily life.";
      } else
        return "You have reported almost no symptoms of depression exceeding normal adjustment levels.";
    }
  }

  // 점수와 이메일을 서버에 저장하는 함수
  Future<void> save(int score) async {
    try {
      String? email = await getEmail(); // 이메일을 가져옴
      if (email != null) {
        final response = await http.post(
          Uri.parse('http://localhost:3000/test/save'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'email': email,
            'score': score,
          }),
        );

        final data = json.decode(response.body);

        if (data['success']) {
          print('Test Score Save successful : $data');
        } else {
          print('Test Score Save failed : ${data['errorMessage']}');
        }
      } else {
        print("이메일을 찾을 수 없습니다.");
      }
    } catch (error) {
      print('Error during save: $error');
    }
  }

  List buttonImageList = [
    'testMeditationButtonBackground.svg',
    'testChatbotButtonBackground.svg',
  ];

  String getButtonImage(int value) {
    return buttonImageList[value];
  }

  @override
  Widget build(BuildContext context) {
    int totalScore = widget.totalScore;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffFF516A),
        iconTheme: IconThemeData(
          color: Color(0xffFFFFFF), //색변경
        ),
      ),
      body: Container(
        padding: EdgeInsets.only(top: 60),
        color: Color(0xffFF516A), // 핑크색 배경
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        PieChartView(
                          totalScore: totalScore,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 19),
                  Align(
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Container(
                        padding: EdgeInsets.only(right: 20, left: 20),
                        alignment: Alignment.center,
                        height: 34,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Color(0xffFFEEF0)),
                        child: Text(
                          getResult(totalScore),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xffFF516A),
                              backgroundColor: Color(0xffFFEEF0)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 42),
                  Align(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      width: 320,
                      height: 146,
                      decoration: BoxDecoration(
                          color: Color(0xffF4F4F4),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        getResultContent(totalScore),
                        style: TextStyle(fontFamily: 'LeeSeoYun', fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 2; i++) ...[
                        Stack(
                          children: [
                            SvgPicture.asset(
                              'assets/images/${getButtonImage(i)}',
                              width: 143,
                              height: 122,
                              fit: BoxFit.fill,
                            ),
                            Positioned.fill(
                              top: 40,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(7),
                                  onTap: () {
                                    if (i == 0) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MeditationVideoList(),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatBot(
                                            email: widget.email,
                                            name: widget.name,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Center(
                                    child: Text(
                                      i == 0
                                          ? tr("test_meditation")
                                          : tr("test_chat"),
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontFamily: 'LeeSeoYun',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (i < 1) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  SizedBox(height: 50),
                ],
              ),
            ),
            Positioned(
                left: 20, // 왼쪽 여백
                top: -35, // 상단 여백
                child: Row(
                  children: [
                    Text(
                      '${getToday()}  ',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      getTime(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

class PieChartView extends StatefulWidget {
  final int totalScore;
  const PieChartView({super.key, required this.totalScore});

  @override
  _PieChartViewState createState() => _PieChartViewState();
}

class _PieChartViewState extends State<PieChartView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    double maxTotal = 30;
    double fillRatio = widget.totalScore / maxTotal;

    _animation = Tween<double>(begin: 0, end: fillRatio).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 4,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              double size = 172;
              double innerCircleSize = 110;

              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: size,
                      height: size,
                      decoration: const BoxDecoration(
                        color: Color(0xffF4F4F4),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            spreadRadius: 0,
                            blurRadius: 6,
                            offset: Offset(0, 0),
                            color: Colors.white,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: PieChartPainter(_animation.value),
                      ),
                    ),
                    Container(
                      width: innerCircleSize,
                      height: innerCircleSize,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              spreadRadius: 10,
                              blurRadius: 17,
                              offset: Offset(1, 2),
                              color: Color(0x21000000),
                            ),
                          ]),
                      child: Center(
                        child: Text(
                          '${widget.totalScore}${tr("score")}',
                          style: const TextStyle(
                            fontSize: 37,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final double fillRatio;

  PieChartPainter(this.fillRatio);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Color(0xffFF516A)
      ..style = PaintingStyle.fill;

    // 원의 중심과 반지름을 계산
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 2;

    // 채워질 부분의 각도 계산 (360도 * 채워질 비율)
    double sweepAngle = 2 * 3.14159 * fillRatio;

    // 원 그리기
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // 시작 각도 (위쪽부터 시작)
      sweepAngle, // 채워지는 각도
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
