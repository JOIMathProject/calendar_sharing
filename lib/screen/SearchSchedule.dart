import 'dart:ffi';

import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;
import 'package:googleapis/bigquerydatatransfer/v1.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../services/UserData.dart';

enum SortOrder { time, participants }

class SearchSchedule extends StatefulWidget {
  final String? groupId;
  SearchSchedule({required this.groupId});
  @override
  _SearchScheduleState createState() => _SearchScheduleState();
}

class _SearchScheduleState extends State<SearchSchedule> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate =
      DateTime.now().add(Duration(days: 1)); // Default to next day

  DateTime now = DateTime.now();
  TimeOfDay startTime = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = TimeOfDay(hour: 20, minute: 0);
  //int startTime = 8;
  //int endTime = 20;
  int minHours = 1;
  int minMinutes = 0;
  int minParticipants = 1;
  int GroupSize = 6;
  String location = '';
  bool considerWeather = false;
  String? selectedRegion;
  String? selectedCity;
  bool isSunny = true;
  bool isCloudy = true;
  bool isRainy = true;
  bool isSnowy = true;
  late FixedExtentScrollController _minuteScrollController;
  List<String> regions = [
    '北海道',
    '東北',
    '関東甲信',
    '東海',
    '北陸',
    '近畿',
    '中国',
    '四国',
    '九州',
    '沖縄'
  ];
  List<String> cities = [''];
  List<String> _getCitiesForRegion(String region) {
    switch (region) {
      case '北海道':
        return [
          '宗谷地方',
          '上川・留萌地方',
          '網走・北見・紋別地方',
          '釧路・根室地方',
          '胆振・日高地方',
          '石狩・空知・後志地方',
          '渡島・檜山地方'
        ];
      case '東北':
        return ['青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県'];
      case '関東甲信':
        return ['茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県', '山梨県', '長野県'];
      case '東海':
        return ['岐阜県', '静岡県', '愛知県', '三重県'];
      case '北陸':
        return ['新潟県', '富山県', '石川県', '福井県'];
      case '近畿':
        return ['滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県'];
      case '中国':
        return ['鳥取県', '島根県', '岡山県', '広島県', '山口県'];
      case '四国':
        return ['徳島県', '香川県', '愛媛県', '高知県'];
      case '九州':
        return ['福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県'];
      case '沖縄':
        return ['沖縄本島地方', '大東島地方', '宮古島地方', '石垣島地方', '与那国島地方'];
      default:
        return ['Unknown'];
    }
  }

  void initState() {
    super.initState();
    _getGroupLocation();
    setState(() {});
    _getGroupSize();
    _getGroupUsers();
    getPrimaryCalendar();
  }

  List<int> years = List.generate(10, (index) => DateTime.now().year + index);
  List<int> months = List.generate(12, (index) => index + 1);
  List<int> days = List.generate(31, (index) => index + 1);
  List<int> hours = List.generate(24, (index) => index);
  List<int> minHoursOptions = List.generate(18, (index) => index);
  List<UserInformation> users = [];

  List<SearchResultEvent> searchResults = [];
  final expansionTileController = ExpansionTileController();
  String? primaryCalendar;
  Future<void> getPrimaryCalendar() async {
    primaryCalendar = await GetGroupPrimaryCalendar().getGroupPrimaryCalendar(
        widget.groupId, Provider.of<UserData>(context, listen: false).uid);
  }

  Future<void> _getGroupUsers() async {
    users = await GetUserInGroup().getUserInGroup(widget.groupId!);
    users.remove(users.firstWhere((element) =>
        element.uid == Provider.of<UserData>(context, listen: false).uid));
  }

  Future<void> _getGroupLocation() async {
    location = await GetGroupLoc().getGroupLoc(widget.groupId);

    selectedRegion = getRegionAndCity(location).split(' - ')[0];
    selectedCity = getRegionAndCity(location).split(' - ')[1];
    print('$selectedRegion, $selectedCity');
    print(location);
  }

  Future<void> _updateGroupLocation() async {
    await UpdateGroupLoc().updateGroupLoc(
        widget.groupId, getAreaCode(selectedRegion!, selectedCity!));
  }

  Future<void> _getGroupSize() async {
    var group = await GetUserInGroup().getUserInGroup(widget.groupId);
    GroupSize = group.length;
    setState(() {});
  }

  String getAreaCode(String region, String city) {
    switch (region) {
      case '北海道':
        switch (city) {
          case '宗谷地方':
            return '011000';
          case '上川・留萌地方':
            return '012000';
          case '網走・北見・紋別地方':
            return '013000';
          case '釧路・根室地方':
            return '015000';
          case '胆振・日高地方':
            return '016000';
          case '石狩・空知・後志地方':
            return '017000';
          case '渡島・檜山地方':
            return '018000';
          default:
            return 'Unknown';
        }
      case '東北':
        switch (city) {
          case '青森県':
            return '020000';
          case '岩手県':
            return '030000';
          case '宮城県':
            return '040000';
          case '秋田県':
            return '050000';
          case '山形県':
            return '060000';
          case '福島県':
            return '070000';
          default:
            return 'Unknown';
        }
      case '関東甲信':
        switch (city) {
          case '茨城県':
            return '080000';
          case '栃木県':
            return '090000';
          case '群馬県':
            return '100000';
          case '埼玉県':
            return '110000';
          case '千葉県':
            return '120000';
          case '東京都':
            return '130000';
          case '神奈川県':
            return '140000';
          case '山梨県':
            return '190000';
          case '長野県':
            return '200000';
          default:
            return 'Unknown';
        }
      case '東海':
        switch (city) {
          case '岐阜県':
            return '210000';
          case '静岡県':
            return '220000';
          case '愛知県':
            return '230000';
          case '三重県':
            return '240000';
          default:
            return 'Unknown';
        }
      case '北陸':
        switch (city) {
          case '新潟県':
            return '150000';
          case '富山県':
            return '160000';
          case '石川県':
            return '170000';
          case '福井県':
            return '180000';
          default:
            return 'Unknown';
        }
      case '近畿':
        switch (city) {
          case '滋賀県':
            return '250000';
          case '京都府':
            return '260000';
          case '大阪府':
            return '270000';
          case '兵庫県':
            return '280000';
          case '奈良県':
            return '290000';
          case '和歌山県':
            return '300000';
          default:
            return 'Unknown';
        }
      case '中国':
        switch (city) {
          case '鳥取県':
            return '310000';
          case '島根県':
            return '320000';
          case '岡山県':
            return '330000';
          case '広島県':
            return '340000';
          case '山口県':
            return '350000';
          default:
            return 'Unknown';
        }
      case '四国':
        switch (city) {
          case '徳島県':
            return '360000';
          case '香川県':
            return '370000';
          case '愛媛県':
            return '380000';
          case '高知県':
            return '390000';
          default:
            return 'Unknown';
        }
      case '九州北部':
        switch (city) {
          case '福岡県':
            return '400000';
          case '佐賀県':
            return '410000';
          case '長崎県':
            return '420000';
          case '熊本県':
            return '430000';
          case '大分県':
            return '440000';
          default:
            return 'Unknown';
        }
      case '九州南部・奄美':
        switch (city) {
          case '宮崎県':
            return '450000';
          case '鹿児島県':
            return '460100';
          case '奄美地方':
            return '460040';
          default:
            return 'Unknown';
        }
      case '沖縄':
        switch (city) {
          case '沖縄本島地方':
            return '471000';
          case '大東島地方':
            return '472000';
          case '宮古島地方':
            return '473000';
          case '石垣島地方':
            return '474000';
          case '与那国島地方':
            return '474010';
          default:
            return 'Unknown';
        }
      default:
        return 'Unknown';
    }
  }

  String getRegionAndCity(String id) {
    switch (id) {
      // 北海道
      case '011000':
        return '北海道 - 宗谷地方';
      case '012000':
        return '北海道 - 上川・留萌地方';
      case '013000':
        return '北海道 - 網走・北見・紋別地方';
      case '015000':
        return '北海道 - 釧路・根室地方';
      case '016000':
        return '北海道 - 胆振・日高地方';
      case '017000':
        return '北海道 - 石狩・空知・後志地方';
      case '018000':
        return '北海道 - 渡島・檜山地方';

      // 東北
      case '020000':
        return '東北 - 青森県';
      case '030000':
        return '東北 - 岩手県';
      case '040000':
        return '東北 - 宮城県';
      case '050000':
        return '東北 - 秋田県';
      case '060000':
        return '東北 - 山形県';
      case '070000':
        return '東北 - 福島県';

      // 関東甲信
      case '080000':
        return '関東甲信 - 茨城県';
      case '090000':
        return '関東甲信 - 栃木県';
      case '100000':
        return '関東甲信 - 群馬県';
      case '110000':
        return '関東甲信 - 埼玉県';
      case '120000':
        return '関東甲信 - 千葉県';
      case '130000':
        return '関東甲信 - 東京都';
      case '140000':
        return '関東甲信 - 神奈川県';
      case '190000':
        return '関東甲信 - 山梨県';
      case '200000':
        return '関東甲信 - 長野県';

      // 東海
      case '210000':
        return '東海 - 岐阜県';
      case '220000':
        return '東海 - 静岡県';
      case '230000':
        return '東海 - 愛知県';
      case '240000':
        return '東海 - 三重県';

      // 北陸
      case '150000':
        return '北陸 - 新潟県';
      case '160000':
        return '北陸 - 富山県';
      case '170000':
        return '北陸 - 石川県';
      case '180000':
        return '北陸 - 福井県';

      // 近畿
      case '250000':
        return '近畿 - 滋賀県';
      case '260000':
        return '近畿 - 京都府';
      case '270000':
        return '近畿 - 大阪府';
      case '280000':
        return '近畿 - 兵庫県';
      case '290000':
        return '近畿 - 奈良県';
      case '300000':
        return '近畿 - 和歌山県';

      // 中国
      case '310000':
        return '中国 - 鳥取県';
      case '320000':
        return '中国 - 島根県';
      case '330000':
        return '中国 - 岡山県';
      case '340000':
        return '中国 - 広島県';
      case '350000':
        return '中国 - 山口県';

      // 四国
      case '360000':
        return '四国 - 徳島県';
      case '370000':
        return '四国 - 香川県';
      case '380000':
        return '四国 - 愛媛県';
      case '390000':
        return '四国 - 高知県';

      // 九州北部
      case '400000':
        return '九州北部 - 福岡県';
      case '410000':
        return '九州北部 - 佐賀県';
      case '420000':
        return '九州北部 - 長崎県';
      case '430000':
        return '九州北部 - 熊本県';
      case '440000':
        return '九州北部 - 大分県';

      // 九州南部・奄美
      case '450000':
        return '九州南部・奄美 - 宮崎県';
      case '460100':
        return '九州南部・奄美 - 鹿児島県';
      case '460040':
        return '九州南部・奄美 - 奄美地方';

      // 沖縄
      case '471000':
        return '沖縄 - 沖縄本島地方';
      case '472000':
        return '沖縄 - 大東島地方';
      case '473000':
        return '沖縄 - 宮古島地方';
      case '474000':
        return '沖縄 - 石垣島地方';
      case '474010':
        return '沖縄 - 与那国島地方';

      default:
        return '関東甲信 - 東京都';
    }
  }

  Future<void> _searchSchedule() async {
    expansionTileController.collapse();
    try {
      if (considerWeather) {
        String formatWithLeadingZero(int value) {
          return value.toString().padLeft(2, '0');
        }

        String formatDate(DateTime date) {
          return DateFormat('yyyy-MM-dd').format(date);
        }

        String formattedStartDate = formatDate(_startDate);
        String formattedEndDate = formatDate(_endDate);

        String startHourString = startTime.hour.toString().padLeft(2, '0');
        String startMinuteString = startTime.minute.toString().padLeft(2, '0');
        String endHourString = endTime.hour.toString().padLeft(2, '0');
        String endMinuteString = endTime.minute.toString().padLeft(2, '0');
        _updateGroupLocation();
        searchResults =
            await SearchContentScheduleWeather().searchContentScheduleWeather(
          widget.groupId.toString(),
          formattedStartDate,
          formattedEndDate,
          startHourString,
          startMinuteString,
          endHourString,
          endMinuteString,
          '${minHours * 60}',
          '${GroupSize - minParticipants}',
          getAreaCode(selectedRegion!, selectedCity!),
          isSunny ? '1' : '0',
          isCloudy ? '1' : '0',
          isRainy ? '1' : '0',
          isSnowy ? '1' : '0',
        );

        searchResults.removeWhere((result) => result.members.any((member) =>
            member.uid == Provider.of<UserData>(context, listen: false).uid));
      } else {
        String formatDate(DateTime date) {
          return DateFormat('yyyy-MM-dd').format(date);
        }

        String formattedStartDate = formatDate(_startDate);
        String formattedEndDate = formatDate(_endDate);

        String startHourString = startTime.hour.toString().padLeft(2, '0');
        String startMinuteString = startTime.minute.toString().padLeft(2, '0');
        String endHourString = endTime.hour.toString().padLeft(2, '0');
        String endMinuteString = endTime.minute.toString().padLeft(2, '0');

        searchResults = await SearchContentSchedule().searchContentSchedule(
          widget.groupId,
          formattedStartDate,
          formattedEndDate,
          startHourString,
          startMinuteString,
          endHourString,
          endMinuteString,
          '${minHours * 60}',
          '${GroupSize - minParticipants}',
        );

        searchResults.removeWhere((result) => result.members.any((member) =>
            member.uid == Provider.of<UserData>(context, listen: false).uid));
      }

      setState(() {});
    } catch (error) {
      // Check for 404 error and set searchResults to null
      if (error.toString().contains('404')) {
        searchResults = [];
        setState(() {});
      }
      print("Error: $error");
    }
  }

  String formatDateTime(DateTime dateTime) {
    // Format month and day
    String monthDay = DateFormat('MM/dd ').format(dateTime);

    // Format hour
    String hour = DateFormat('HH:mm').format(dateTime);

    // Combine them
    return '$monthDay$hour';
  }

  SortOrder _sortOrder = SortOrder.time; // Default sorting order

  void _sortList() {
    setState(() {
      searchResults.removeWhere((result) => result.members.any((member) =>
          member.uid == Provider.of<UserData>(context, listen: false).uid));
      if (_sortOrder == SortOrder.time) {
        searchResults.sort((a, b) => a.startTime.compareTo(b.startTime));
      } else if (_sortOrder == SortOrder.participants) {
        searchResults.sort((a, b) {
          int countComparison = a.count.compareTo(b.count);
          if (countComparison != 0) {
            return countComparison;
          } else {
            return a.startTime.compareTo(b.startTime);
          }
        });
      }
    });
  }

  Future<void> _pickStartDate() async {
    DateTime today = DateTime.now();
    DateTime firstSelectableDate = DateTime(today.year, today.month, today.day);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(firstSelectableDate)
          ? firstSelectableDate
          : _startDate,
      firstDate: firstSelectableDate, // Prevent selecting dates before today
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary:
              GlobalColor.timeDateSelectionCol, // Header background color (selected day)
              onPrimary: Colors.black, // Header text color
              surface: GlobalColor.SubCol, // Dialog background color
              onSurface: Colors.black, // Body text color (dates)
            ),
            dialogBackgroundColor: GlobalColor.SubCol, // Dialog background
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                backgroundColor: GlobalColor.timeDateSelectionCol,
                foregroundColor: GlobalColor.SubCol, // Button text color
                // backgroundColor can be set if needed
              ),
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: Colors.black), // Date text color
              // You can customize other text styles if needed
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;

        // **Updated Logic:** If the new Start Date is after the current End Date,
        // adjust the End Date to be the same as the new Start Date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate, // End date cannot be before Start date
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary:
              GlobalColor.timeDateSelectionCol, // Header background color (selected day)
              onPrimary: Colors.black, // Header text color
              surface: GlobalColor.SubCol, // Dialog background color
              onSurface: Colors.black, // Body text color (dates)
            ),
            dialogBackgroundColor: GlobalColor.SubCol, // Dialog background
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                backgroundColor: GlobalColor.timeDateSelectionCol,
                foregroundColor: GlobalColor.SubCol, // Button text color
                // backgroundColor can be set if needed
              ),
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: Colors.black), // Date text color
              // You can customize other text styles if needed
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }

  int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

// Calculate the difference in hours between startTime and endTime
  int calculateHourDifference(TimeOfDay startTime, TimeOfDay endTime) {
    int startMinutes = timeOfDayToMinutes(startTime);
    int endMinutes = timeOfDayToMinutes(endTime);

    int differenceInMinutes = endMinutes - startMinutes;

    // Convert difference to hours (floor division)
    return (differenceInMinutes / 60).floor();
  }

  String formatTimeOfDay(TimeOfDay time) {
    // Format the hour and minute with leading zeroes if necessary
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Function to pick the start time
  Future<void> _pickStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: startTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary:
              GlobalColor.timeDateSelectionCol, // Header background color (selected day)
              onPrimary: Colors.black, // Header text color
              surface: GlobalColor.SubCol, // Dialog background color
              onSurface: Colors.black, // Body text color (dates)
            ),
            dialogBackgroundColor: GlobalColor.SubCol, // Dialog background
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                backgroundColor: GlobalColor.timeDateSelectionCol,
                foregroundColor: GlobalColor.SubCol, // Button text color
                // backgroundColor can be set if needed
              ),
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: Colors.black), // Date text color
              // You can customize other text styles if needed
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        startTime = picked;

        // Ensure the end time is later than the start time
        if (endTime.hour < startTime.hour ||
            (endTime.hour == startTime.hour &&
                endTime.minute < startTime.minute)) {
          endTime =
              TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute);
        }
      });
    }
  }

  // Function to pick the end time
  Future<void> _pickEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: endTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary:
              GlobalColor.timeDateSelectionCol, // Header background color (selected day)
              onPrimary: Colors.black, // Header text color
              surface: GlobalColor.SubCol, // Dialog background color
              onSurface: Colors.black, // Body text color (dates)
            ),
            dialogBackgroundColor: GlobalColor.SubCol, // Dialog background
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                backgroundColor: GlobalColor.timeDateSelectionCol,
                foregroundColor: GlobalColor.SubCol, // Button text color
                // backgroundColor can be set if needed
              ),
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: Colors.black), // Date text color
              // You can customize other text styles if needed
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null &&
        (picked.hour > startTime.hour ||
            (picked.hour == startTime.hour &&
                picked.minute > startTime.minute))) {
      setState(() {
        endTime = picked;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('終了時間は開始時間より後でなければなりません')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int hourDifference = calculateHourDifference(startTime, endTime);
    List<int> minHoursOptions =
        List.generate(hourDifference + 1, (index) => index);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.AppBarCol,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'スケジュール検索',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Theme(
              data: Theme.of(context).copyWith(
                listTileTheme: ListTileTheme.of(context).copyWith(
                  dense: true,
                ),
              ),
              child: ExpansionTile(
                controller: expansionTileController,
                initiallyExpanded: true,
                title: Text(
                    '${_startDate.year}/${_startDate.month}/${_startDate.day}~${_endDate.year}/${_endDate.month}/${_endDate.day} の ${formatTimeOfDay(startTime)}~${formatTimeOfDay(endTime)}\n'
                    '最低${minHours}時間以上/${minParticipants}人以上が参加可能\n'
                    '${(selectedRegion != null && considerWeather == true) ? selectedRegion : ''} '
                    '${(selectedCity != null && considerWeather == true) ? selectedCity : ''} '
                    '${[
                  if (isSunny) considerWeather == true ? '晴れ' : '',
                  if (isCloudy) considerWeather == true ? '曇り' : '',
                  if (isRainy) considerWeather == true ? '雨' : '',
                  if (isSnowy) considerWeather == true ? '雪' : ''
                ].where((condition) => condition.isNotEmpty).join('/')}'),
                dense: true,
                children: [
                  SizedBox(height: 16.0), // Start Date Picker Button
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickStartDate,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '開始日: ${DateFormat('yyyy/MM/dd').format(_startDate)}',
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickEndDate,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '終了日: ${DateFormat('yyyy/MM/dd').format(_endDate)}',
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.0),

                  // Time Selection
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickStartTime(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '開始時間: ${startTime.format(context)}',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickEndTime(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '終了時間: ${endTime.format(context)}',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Row(
                    children: [
                      Text('最低'),
                      SizedBox(width: 4.0),
                      Expanded(
                        child: Container(
                          height: 80,
                          padding: EdgeInsets.symmetric(
                              vertical: 10.0), // Reduce padding for visibility
                          decoration: BoxDecoration(
                            //border: Border.all(color: Colors.grey), // Optional: add border for visual separation
                            borderRadius:
                                BorderRadius.circular(10), // Rounded corners
                          ),
                          child: CupertinoPicker(
                            itemExtent: 40.0, // Height of each item
                            magnification:
                                1.2, // Slight magnification on selected item
                            useMagnifier: true, // Enable magnifier effect
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                minHours = minHoursOptions[index];
                              });
                            },
                            scrollController: FixedExtentScrollController(
                                initialItem: minHours),
                            children: List.generate(
                              minHoursOptions.length,
                              (index) => Center(
                                child: Text(
                                  '${minHoursOptions[index]}',
                                  style: TextStyle(
                                      fontSize: 20), // Adjust text size
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.0),
                      Text('時間'),
                      Spacer(flex: 1),
                      Text('最低'),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Container(
                          height: 80,
                          padding: EdgeInsets.symmetric(
                              vertical: 10.0), // Add space above and below
                          decoration: BoxDecoration(
                            //border: Border.all(color: Colors.grey), // Optional: add border
                            borderRadius:
                                BorderRadius.circular(10), // Rounded corners
                          ),
                          child: CupertinoPicker(
                            itemExtent:
                                40.0, // Increased item extent for better visibility
                            magnification:
                                1.2, // Magnification for the selected item
                            useMagnifier: true, // Enable magnifier
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                minParticipants =
                                    index + 1; // Update selected value
                              });
                            },
                            scrollController: FixedExtentScrollController(
                                initialItem: minParticipants - 1),
                            children: List.generate(
                              GroupSize, // Generate items based on group size
                              (index) => Center(
                                child: Text(
                                  '${index + 1}', // Display numbers starting from 1
                                  style: TextStyle(
                                      fontSize: 20), // Adjust text size
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.0),
                      Text('人参加可能'),
                      Spacer(flex: 1),
                    ],
                  ),

                  SizedBox(height: 10.0),
                  // Weather Consideration Switch and Options
                  Row(
                    children: [
                      Text('天気も考慮する'),
                      Switch(
                        value: considerWeather,
                        onChanged: (bool value) {
                          setState(() {
                            considerWeather = value;
                            if (considerWeather) {
                              selectedRegion ??= regions.first;
                              cities = _getCitiesForRegion(selectedRegion!);
                              selectedCity ??= cities.first;
                            }
                          });
                        },
                        activeColor: GlobalColor.MainCol, // color of the toggle
                        inactiveTrackColor:
                            GlobalColor.Unselected, // color of the background
                        inactiveThumbColor: Colors.black26, // color of the thumb when the switch is off
                      ),
                    ],
                  ),
                  // Display region and city dropdowns if considering weather
                  if (considerWeather) ...[
                    Row(
                      children: [
                        SizedBox(width: 8.0),
                        _buildDropdownString(regions, selectedRegion!,
                            (newValue) {
                          setState(() {
                            selectedRegion = newValue;
                            cities = _getCitiesForRegion(selectedRegion!);
                            selectedCity = cities.first;
                          });
                        }, hintText: '地域を選択'),
                        Spacer(flex: 8),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(width: 8.0),
                        _buildDropdownString(cities, selectedCity!, (newValue) {
                          setState(() {
                            selectedCity = newValue;
                          });
                        }, hintText: '市を選択'),
                        Spacer(flex: 3),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isSunny = !isSunny; // Toggle state for sunny
                              });
                            },
                            child: Container( // Use Container to make the entire area tappable
                              color: Colors.transparent, // Ensures the entire area is tappable
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.wb_sunny,
                                    color: isSunny
                                        ? GlobalColor.weatherMark
                                        : Colors.grey, // Highlight when selected
                                    size: 30, // Increased size for larger buttons
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '晴れ',
                                    style: TextStyle(
                                        color: isSunny
                                            ? GlobalColor.weatherMark
                                            : Colors.grey,
                                        fontSize: 14), // Larger text
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isCloudy = !isCloudy; // Toggle state for cloudy
                              });
                            },
                            child: Container(
                              color: Colors.transparent, // Ensures the entire area is tappable
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud,
                                    color: isCloudy
                                        ? GlobalColor.weatherMark
                                        : Colors.grey, // Highlight when selected
                                    size: 30, // Increased size for larger buttons
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '曇り',
                                    style: TextStyle(
                                        color: isCloudy
                                            ? GlobalColor.weatherMark
                                            : Colors.grey,
                                        fontSize: 14), // Larger text
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isRainy = !isRainy; // Toggle state for rainy
                              });
                            },
                            child: Container(
                              color: Colors.transparent, // Ensures the entire area is tappable
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.beach_access,
                                    color: isRainy
                                        ? GlobalColor.weatherMark
                                        : Colors.grey, // Highlight when selected
                                    size: 30, // Increased size for larger buttons
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '雨',
                                    style: TextStyle(
                                        color: isRainy
                                            ? GlobalColor.weatherMark
                                            : Colors.grey,
                                        fontSize: 14), // Larger text
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isSnowy = !isSnowy; // Toggle state for snowy
                              });
                            },
                            child: Container(
                              color: Colors.transparent, // Ensures the entire area is tappable
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.ac_unit,
                                    color: isSnowy
                                        ? GlobalColor.weatherMark
                                        : Colors.grey, // Highlight when selected
                                    size: 30, // Increased size for larger buttons
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '雪',
                                    style: TextStyle(
                                        color: isSnowy
                                            ? GlobalColor.weatherMark
                                            : Colors.grey,
                                        fontSize: 14), // Larger text
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                  ],
                ],
              ),
            ),
            SizedBox(height: 5.0),
            Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(
                        8.0), // Add padding for a better appearance
                    child: considerWeather
                        ? Text(
                            '出典：気象庁ＨＰ',
                            style: TextStyle(
                              fontSize: 10, // Smaller font size
                              color: Colors.black87, // Light font color
                            ),
                          )
                        : Container(),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalColor.MainCol,
                        ),
                        onPressed: _searchSchedule,
                        child: Text('検索',
                            style: TextStyle(
                                fontSize: 20, color: GlobalColor.SubCol)),
                      ),
                      SizedBox(
                          width: 20), // Spacing between button and dropdown
                      DropdownButton<SortOrder>(
                        value: _sortOrder,
                        items: [
                          DropdownMenuItem(
                            value: SortOrder.time,
                            child: Text('時間'),
                          ),
                          DropdownMenuItem(
                            value: SortOrder.participants,
                            child: Text('参加人数'),
                          ),
                        ],
                        onChanged: (SortOrder? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _sortOrder = newValue;
                              _sortList(); // Sort the list when option changes
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.only(right: 8.0), // Adjust the right padding value as needed
              child: Align(
                alignment: Alignment.centerRight, // Still aligns to the right but slightly padded left
                child: Text(
                  'ヒット件数：${searchResults.length}件', // Displays the count of search results
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            ),


            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  // Determine the weather icon based on the weather code
                  IconData weatherIcon;
                  Color weatherColor = Colors.black54;
                  switch (searchResults[index].weather) {
                    case -1:
                      weatherIcon = Icons.help_outline; // '?' icon for -1
                      weatherColor = Colors.grey;
                      break;
                    case 0:
                      weatherIcon = Icons.wb_sunny; // 'sun' icon for 0
                      weatherColor = Colors.orange;
                      break;
                    case 1:
                      weatherIcon = Icons.cloud; // 'cloud' icon for 1
                      weatherColor = Colors.grey;
                      break;
                    case 2:
                      weatherIcon = Icons.beach_access; // 'rain' icon for 2
                      weatherColor = Colors.blue;
                      break;
                    case 3:
                      weatherIcon = Icons.ac_unit; // 'snow' icon for 3
                      break;
                    default:
                      weatherIcon = Icons
                          .help_outline; // '?' icon for unknown weather code
                  }

                  return ListTile(
                    title: Text(
                      '${formatDateTime(searchResults[index].startTime)} ~ \n      ${formatDateTime(searchResults[index].endTime)}',
                    ),
                    subtitle: searchResults[index].count != 0
                        ? Text('${searchResults[index].count}人参加できません')
                        : Text('全員参加可能'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Warning IconButton with fixed width
                        SizedBox(
                          width: 40, // Fixed width to reserve space
                          child: searchResults[index].members.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.warning, color: Colors.red),
                            onPressed: () {
                              showModalBottomSheet(
                                backgroundColor: GlobalColor.SubCol,
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (BuildContext context) {
                                  return Container(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '参加できないユーザー',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Flexible(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: searchResults[index].members.length,
                                            itemBuilder: (context, i) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundImage: NetworkImage(
                                                        'https://calendar-files.woody1227.com/user_icon/${searchResults[index].members[i].uicon}',
                                                      ),
                                                      radius: 20,
                                                    ),
                                                    SizedBox(width: 16),
                                                    Text(
                                                      '${searchResults[index].members[i].uname}',
                                                      style: TextStyle(fontSize: 16),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          )
                              : SizedBox(), // Empty SizedBox to reserve space when no warning is needed
                        ),

                        // 2. Weather Icon with fixed width
                        SizedBox(
                          width: 30, // Fixed width to reserve space
                          child: considerWeather
                              ? Icon(
                            weatherIcon,
                            color:  weatherColor, // Optional: Customize icon color
                          )
                              : SizedBox(), // Empty SizedBox to reserve space when weather is not considered
                        ),

                        // 3. Spacing between Weather Icon and Weather Text
                        SizedBox(width: 8.0),

                        // 4. Weather Text with fixed width
                        SizedBox(
                          width: 30, // Fixed width to reserve space for text
                          child: considerWeather
                              ? Text(
                            searchResults[index].reliability?.isNotEmpty == true
                                ? searchResults[index].reliability
                                : '-',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87, // Optional: Customize text color
                            ),
                          )
                              : SizedBox(), // Empty SizedBox to reserve space when weather text is not needed
                        ),

                        // 5. Add IconButton with fixed width
                        SizedBox(
                          width: 40, // Fixed width to reserve space
                          child: IconButton(
                            icon: Icon(Icons.add, color: Colors.black54), // Optional: Customize icon color
                            onPressed: () {
                              _showScheduleDialog(context, index);
                            },
                          ),
                        ),
                      ],
                    ),
                  );

                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      List<int> options, int value, ValueChanged<int?> onChanged) {
    return Expanded(
      flex: 2,
      child: DropdownButton<int>(
        value: value,
        onChanged: onChanged,
        items: options.map<DropdownMenuItem<int>>((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDropdownString(
      List<String> options, String value, ValueChanged<String?> onChanged,
      {String? hintText}) {
    return Expanded(
      flex: 4,
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        hint: hintText != null ? Text(hintText) : null,
        items: options.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
      ),
    );
  }

  Future<void> SendRequest(
      String uid2, String Summary, DateTime startTime, DateTime endTime) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    print(
        'uid: $uid uid2: $uid2 Summary: $Summary startTime: $startTime endTime: $endTime');
    await SendEventRequest().sendEventRequest(
        uid, uid2, widget.groupId, Summary, startTime, endTime);
  }

  Future<void> AddSchedule(
      String Summary, DateTime startTime, DateTime endTime) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    AddEventToTheCalendar().addEventToTheCalendar(
        uid, primaryCalendar, Summary, '', startTime, endTime);
  }

  void _showScheduleDialog(BuildContext context, int index) {
    // Initialize selected values
    int selectedHour = searchResults[index].startTime.hour;
    int selectedMinute = searchResults[index].startTime.minute;
    int selectedDurationHours = 0;
    int selectedDurationMinutes = 0;
    _minuteScrollController = FixedExtentScrollController(initialItem: selectedMinute);
    // Time and duration limits
    final int startHour = searchResults[index].startTime.hour;
    final int endHour = searchResults[index].endTime.hour;
    final int startMinute = searchResults[index].startTime.minute;
    final int endMinute = searchResults[index].endTime.minute;
    final SummaryEditor = TextEditingController();
    String Summary = '';
    int exceedTime =
        0; //0 not exceeding, 1 exceeded but cancelled 2 exceeded and continued
    // Function to show the main dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '予定を追加',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),
                  TextField(
                    controller: SummaryEditor,
                    decoration: InputDecoration(
                      labelText: '予定名',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: GlobalColor.SubCol,
                    ),
                    onChanged: (String value) {
                      setState(() {
                        Summary = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    '予定開始時刻',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoPicker(
                            itemExtent: 40,
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                selectedHour = startHour + index;
                                if (selectedHour == startHour && selectedMinute < startMinute) {
                                  selectedMinute = startMinute;
                                }
                                if (selectedHour == endHour && selectedMinute > endMinute) {
                                  selectedMinute = endMinute;
                                }
                              });
                            },

                            children: List.generate(
                              endHour - startHour + 1,
                                  (int index) => Center(
                                child: Text(
                                  '${startHour + index}時',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoPicker(
                            scrollController: _minuteScrollController,
                            itemExtent: 40,
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                selectedMinute = index;
                                if (selectedHour == startHour && selectedMinute < startMinute) {
                                  selectedMinute = startMinute;
                                }
                                if (selectedHour == endHour && selectedMinute > endMinute) {
                                  selectedMinute = endMinute;
                                }
                              });
                            },
                            children: List.generate(
                              60,
                                  (int index) {
                                final formattedMinute = index < 10 ? '0$index' : '$index';
                                return Center(
                                  child: Text(
                                    '$formattedMinute分',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    '予定長さ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoPicker(
                            itemExtent: 40,
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                selectedDurationHours = index;
                              });
                            },
                            children: List.generate(
                              24,
                                  (int index) => Center(
                                child: Text(
                                  '$index 時間',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoPicker(
                            itemExtent: 40,
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                selectedDurationMinutes = index * 5;
                              });
                            },
                            children: List.generate(
                              60,
                                  (int index) => Center(
                                child: Text(
                                  '${index} 分',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          child: Text('予定追加リクエストを送信', style: TextStyle(fontSize: 18,color: GlobalColor.SubCol),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalColor.MainCol,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          onPressed: () {
                            final totalSelectedTimeInMinutes =
                            (selectedHour * 60 + selectedMinute);
                            final totalSelectedDurationInMinutes =
                            (selectedDurationHours * 60 + selectedDurationMinutes);
                            final totalEndTimeInMinutes =
                            (searchResults[index].endTime.hour * 60 +
                                searchResults[index].endTime.minute);

                            if (Summary.isEmpty) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('エラー'),
                                    content: Text('予定名を入力してください。'),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GlobalColor.MainCol,
                                        ),
                                        child: Text(
                                          '閉じる',
                                          style: TextStyle(color: GlobalColor.SubCol),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                              return;
                            }
                            else if (totalSelectedDurationInMinutes == 0) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('エラー'),
                                    content: Text('予定の長さを指定してください。'),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GlobalColor.MainCol,
                                        ),
                                        child: Text(
                                          '閉じる',
                                          style: TextStyle(color: GlobalColor.SubCol),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                            else if (totalSelectedTimeInMinutes +
                                totalSelectedDurationInMinutes >
                                totalEndTimeInMinutes) {
                              exceedTime = 1;
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('エラー'),
                                    content: Text(
                                        '選択した時間は終了時間を超えています。一部ユーザーが参加できなくなる可能性がありますが続行しますか？'),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GlobalColor.MainCol,
                                        ),
                                        child: Text(
                                          '続行',
                                          style: TextStyle(color: GlobalColor.SubCol),
                                        ),
                                        onPressed: () {
                                          for (var request in users) {
                                            SendRequest(
                                                request.uid,
                                                Summary,
                                                DateTime(
                                                    searchResults[index].startTime.year,
                                                    searchResults[index]
                                                        .startTime
                                                        .month,
                                                    searchResults[index].startTime.day,
                                                    selectedHour,
                                                    selectedMinute),
                                                DateTime(
                                                    searchResults[index].startTime.year,
                                                    searchResults[index]
                                                        .startTime
                                                        .month,
                                                    searchResults[index].startTime.day,
                                                    selectedHour +
                                                        selectedDurationHours,
                                                    selectedMinute +
                                                        selectedDurationMinutes));
                                          }
                                          AddSchedule(
                                              Summary,
                                              DateTime(
                                                  searchResults[index].startTime.year,
                                                  searchResults[index].startTime.month,
                                                  searchResults[index].startTime.day,
                                                  selectedHour,
                                                  selectedMinute),
                                              DateTime(
                                                  searchResults[index].startTime.year,
                                                  searchResults[index].startTime.month,
                                                  searchResults[index].startTime.day,
                                                  selectedHour + selectedDurationHours,
                                                  selectedMinute +
                                                      selectedDurationMinutes));

                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: GlobalColor.SnackCol,
                                              content: Text('予定追加リクエストを送信しました', style: TextStyle(color: GlobalColor.SubCol)),
                                            ),
                                          );
                                        },
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GlobalColor.MainCol,
                                        ),
                                        child: Text(
                                          'キャンセル',
                                          style: TextStyle(color: GlobalColor.SubCol),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                            else if (searchResults[index].members.length == 0) {
                              for (var request in users) {
                                SendRequest(
                                    request.uid,
                                    Summary,
                                    DateTime(
                                        searchResults[index].startTime.year,
                                        searchResults[index].startTime.month,
                                        searchResults[index].startTime.day,
                                        selectedHour,
                                        selectedMinute),
                                    DateTime(
                                        searchResults[index].startTime.year,
                                        searchResults[index].startTime.month,
                                        searchResults[index].startTime.day,
                                        selectedHour + selectedDurationHours,
                                        selectedMinute + selectedDurationMinutes));
                              }
                              AddSchedule(
                                  Summary,
                                  DateTime(
                                      searchResults[index].startTime.year,
                                      searchResults[index].startTime.month,
                                      searchResults[index].startTime.day,
                                      selectedHour,
                                      selectedMinute),
                                  DateTime(
                                      searchResults[index].startTime.year,
                                      searchResults[index].startTime.month,
                                      searchResults[index].startTime.day,
                                      selectedHour + selectedDurationHours,
                                      selectedMinute + selectedDurationMinutes));
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: GlobalColor.SnackCol,
                                              content: Text('予定追加リクエストを送信しました', style: TextStyle(color: GlobalColor.SubCol)),
                                            ),
                                          );
                            }
                            else if (searchResults[index].members.length != 0) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('予定追加リクエストの送信先'),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GlobalColor.MainCol,
                                        ),
                                        child: Text(
                                          '参加できる人のみに送信',
                                          style: TextStyle(color: GlobalColor.SubCol),
                                        ),
                                        onPressed: () {
                                          for (var request in users) {
                                            bool canJoin = true;
                                            for (var member
                                            in searchResults[index].members) {
                                              if (request.uid == member.uid) {
                                                canJoin = false;
                                              }
                                            }
                                            if (canJoin) {
                                              SendRequest(
                                                  request.uid,
                                                  Summary,
                                                  DateTime(
                                                      searchResults[index]
                                                          .startTime
                                                          .year,
                                                      searchResults[index]
                                                          .startTime
                                                          .month,
                                                      searchResults[index]
                                                          .startTime
                                                          .day,
                                                      selectedHour,
                                                      selectedMinute),
                                                  DateTime(
                                                      searchResults[index]
                                                          .startTime
                                                          .year,
                                                      searchResults[index]
                                                          .startTime
                                                          .month,
                                                      searchResults[index]
                                                          .startTime
                                                          .day,
                                                      selectedHour +
                                                          selectedDurationHours,
                                                      selectedMinute +
                                                          selectedDurationMinutes));
                                            }
                                          }

                                          AddSchedule(
                                              Summary,
                                              DateTime(
                                                  searchResults[index].startTime.year,
                                                  searchResults[index].startTime.month,
                                                  searchResults[index].startTime.day,
                                                  selectedHour,
                                                  selectedMinute),
                                              DateTime(
                                                  searchResults[index].startTime.year,
                                                  searchResults[index].startTime.month,
                                                  searchResults[index].startTime.day,
                                                  selectedHour + selectedDurationHours,
                                                  selectedMinute +
                                                      selectedDurationMinutes));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: GlobalColor.SnackCol,
                                              content: Text('予定追加リクエストを送信しました', style: TextStyle(color: GlobalColor.SubCol)),
                                            ),
                                          );
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GlobalColor.MainCol,
                                        ),
                                        child: Text(
                                          '参加できない人にも送信',
                                          style: TextStyle(color: GlobalColor.SubCol),
                                        ),
                                        onPressed: () {
                                          for (var request in users) {
                                            SendRequest(
                                                request.uid,
                                                Summary,
                                                DateTime(
                                                    searchResults[index].startTime.year,
                                                    searchResults[index]
                                                        .startTime
                                                        .month,
                                                    searchResults[index].startTime.day,
                                                    selectedHour,
                                                    selectedMinute),
                                                DateTime(
                                                    searchResults[index].startTime.year,
                                                    searchResults[index]
                                                        .startTime
                                                        .month,
                                                    searchResults[index].startTime.day,
                                                    selectedHour +
                                                        selectedDurationHours,
                                                    selectedMinute +
                                                        selectedDurationMinutes));
                                          }

                                          AddSchedule(
                                              Summary,
                                              DateTime(
                                                  searchResults[index].startTime.year,
                                                  searchResults[index].startTime.month,
                                                  searchResults[index].startTime.day,
                                                  selectedHour,
                                                  selectedMinute),
                                              DateTime(
                                                  searchResults[index].startTime.year,
                                                  searchResults[index].startTime.month,
                                                  searchResults[index].startTime.day,
                                                  selectedHour + selectedDurationHours,
                                                  selectedMinute +
                                                      selectedDurationMinutes));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: GlobalColor.SnackCol,
                                              content: Text('予定追加リクエストを送信しました', style: TextStyle(color: GlobalColor.SubCol)),
                                            ),
                                          );
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GlobalColor.MainCol,
                                        ),
                                        child: Text(
                                          'キャンセル',
                                          style: TextStyle(color: GlobalColor.SubCol),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

