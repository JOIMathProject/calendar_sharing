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
  DateTime now = DateTime.now();
  int startYear = DateTime.now().year;
  int endYear = DateTime.now().year;
  int startDateMonth = DateTime.now().month;
  int endDateMonth = DateTime.now().month + 1;
  int startDateDay = DateTime.now().day;
  int endDateDay = DateTime.now().day;
  int startTime = 8;
  int endTime = 20;
  int minHours = 1;
  int minMinutes = 0;
  int minParticipants = 1;
  int GroupSize = 6;

  bool considerWeather = false;
  String? selectedRegion;
  String? selectedCity;
  bool isSunny = false;
  bool isCloudy = false;
  bool isRainy = false;
  bool isSnowy = false;

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
  List<int> getAvailableDays(int year, int month) {
    int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    DateTime selectedDate = DateTime(year, month, 1);
    int startDayLimit =
    (selectedDate.isAfter(now) || selectedDate.isAtSameMomentAs(now))
        ? 1
        : now.day + 1;

    if (year == startYear && month == startDateMonth) {
      startDayLimit = startDateDay;
    }

    // Ensure today's date is not included in the available days
    if (year == now.year && month == now.month) {
      if (startDayLimit <= now.day) {
        startDayLimit = now.day + 1;
      }
    }

    return List.generate(
        lastDayOfMonth - startDayLimit + 1, (index) => startDayLimit + index);
  }

  String? primaryCalendar;
  Future<void> getPrimaryCalendar() async {
    primaryCalendar = await GetGroupPrimaryCalendar().getGroupPrimaryCalendar(widget.groupId,Provider.of<UserData>(context, listen: false).uid);
  }
  Future<void> _getGroupUsers() async {
    users = await GetUserInGroup().getUserInGroup(widget.groupId!);
    users.remove(users.firstWhere((element) => element.uid == Provider.of<UserData>(context, listen: false).uid));
  }

  List<int> getAvailableDaysStart(int year, int month) {
    int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    int startDayLimit = 1;

    if (year == startYear && month == DateTime.now().month) {
      startDayLimit = DateTime.now().day;
    }
    return List.generate(
        lastDayOfMonth - startDayLimit + 1, (index) => startDayLimit + index);
  }

  List<int> getAvailableMonths(int year) {
    int startMonthLimit = (year == now.year) ? now.month : 1;

    if (year == startYear) {
      startMonthLimit = startDateMonth;
    }
    return List.generate(
        12 - startMonthLimit + 1, (index) => startMonthLimit + index);
  }

  List<int> getAvailableMonthsStart(int year) {
    int startMonthLimit = (year == now.year) ? now.month : 1;

    if (year == startYear) {
      startMonthLimit = DateTime.now().month;
    }
    return List.generate(
        12 - startMonthLimit + 1, (index) => startMonthLimit + index);
  }

  List<int> getAvailableYears() {
    return years.where((year) {
      DateTime startDate = DateTime(startYear, startDateMonth, startDateDay);
      DateTime endDate = DateTime(year, endDateMonth, endDateDay);
      return endDate.isAfter(now) &&
          endDate.isBefore(
              startDate.add(Duration(days: 182))); // Limit to 6 months
    }).toList();
  }

  void _adjustEndDate() {
    DateTime startDate = DateTime(startYear, startDateMonth, startDateDay);
    DateTime endDate = DateTime(endYear, endDateMonth, endDateDay);

    if (startDate.isAfter(endDate)) {
      setState(() {
        endYear = startYear;
        endDateMonth = startDateMonth;
        endDateDay = startDateDay;
      });
    }
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

  Future<void> _searchSchedule() async {
    expansionTileController.collapse();
    try {
      if (considerWeather) {
        String formatWithLeadingZero(int value) {
          return value.toString().padLeft(2, '0');
        }

        String formattedStartDateMonth = formatWithLeadingZero(startDateMonth);
        String formattedEndDateMonth = formatWithLeadingZero(endDateMonth);
        String formattedStartDateDay = formatWithLeadingZero(startDateDay);
        String formattedEndDateDay = formatWithLeadingZero(endDateDay);
        String formattedStartTime = formatWithLeadingZero(startTime);
        String formattedEndTime = formatWithLeadingZero(endTime);

        searchResults = await SearchContentScheduleWeather().searchContentScheduleWeather(
          widget.groupId.toString(),
          '$startYear-$formattedStartDateMonth-$formattedStartDateDay',
          '$endYear-$formattedEndDateMonth-$formattedEndDateDay',
          formattedStartTime,
          '00',
          formattedEndTime,
          '00',
          '${minHours * 60}',
          '${GroupSize - minParticipants}',
          getAreaCode(selectedRegion!, selectedCity!),
          isSunny ? '1' : '0',
          isCloudy ? '1' : '0',
          isRainy ? '1' : '0',
          isSnowy ? '1' : '0',
        );

        searchResults.removeWhere((result) =>
            result.members.any((member) => member.uid == Provider.of<UserData>(context, listen: false).uid)
        );
      } else {
        String formatWithLeadingZero(int value) {
          return value.toString().padLeft(2, '0');
        }

        String formattedStartDateMonth = formatWithLeadingZero(startDateMonth);
        String formattedEndDateMonth = formatWithLeadingZero(endDateMonth);
        String formattedStartDateDay = formatWithLeadingZero(startDateDay);
        String formattedEndDateDay = formatWithLeadingZero(endDateDay);
        String formattedStartTime = formatWithLeadingZero(startTime);
        String formattedEndTime = formatWithLeadingZero(endTime);

        searchResults = await SearchContentSchedule().searchContentSchedule(
          widget.groupId,
          '$startYear-$formattedStartDateMonth-$formattedStartDateDay',
          '$endYear-$formattedEndDateMonth-$formattedEndDateDay',
          formattedStartTime,
          '00',
          formattedEndTime,
          '00',
          '${minHours * 60}',
          '${GroupSize - minParticipants}',
        );

        searchResults.removeWhere((result) =>
            result.members.any((member) => member.uid == Provider.of<UserData>(context, listen: false).uid)
        );
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
    String monthDay = DateFormat('M月d日').format(dateTime);

    // Format hour
    String hour = DateFormat('H時').format(dateTime);

    // Combine them
    return '$monthDay$hour';
  }

  SortOrder _sortOrder = SortOrder.time; // Default sorting order

  void _sortList() {
    setState(() {
      searchResults.removeWhere((result) =>
          result.members.any((member) => member.uid == Provider.of<UserData>(context, listen: false).uid)
      );
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


  @override
  Widget build(BuildContext context) {
    if (!hours.contains(startTime)) {
      startTime = hours.first;
    }

    if (!hours.where((hour) => hour >= startTime).contains(endTime)) {
      endTime = hours.where((hour) => hour >= startTime).first;
    }

    if (!getAvailableDays(startYear, startDateMonth).contains(startDateDay)) {
      startDateDay = getAvailableDaysStart(startYear, startDateMonth).first;
    }

    if (!getAvailableDays(endYear, endDateMonth).contains(endDateDay)) {
      endDateDay = getAvailableDays(endYear, endDateMonth).first;
    }
    List<int> availableStartDays =
        getAvailableDaysStart(startYear, startDateMonth);
    if (!availableStartDays.contains(startDateDay)) {
      startDateDay =
          availableStartDays.isNotEmpty ? availableStartDays.first : 1;
    }

    List<int> availableEndDays = getAvailableDays(endYear, endDateMonth);
    if (!availableEndDays.contains(endDateDay)) {
      endDateDay = availableEndDays.isNotEmpty ? availableEndDays.first : 1;
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.SubCol,
        flexibleSpace: Container(
          color: GlobalColor.SubCol,
        ),
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
                    '${startYear}/${startDateMonth}/${startDateDay}~${endYear}/${endDateMonth}/${endDateDay}の${startTime}時から${endTime}時\n'
                        '最低${minHours}時間以上/${minParticipants}人以上が参加可能\n'
                        '${(selectedRegion != null && considerWeather == true) ? selectedRegion : ''} '
                        '${(selectedCity != null && considerWeather == true) ? selectedCity : ''} '
                        '${[if (isSunny) '晴れ', if (isCloudy) '曇り', if (isRainy) '雨', if (isSnowy) '雪'].where((condition) => condition.isNotEmpty).join('/')}'),
                dense: true,
                children: [
                  SizedBox(height: 16.0),
                  Row(
                    children: [
                      _buildDropdown(getAvailableYears(), startYear,
                          (newValue) {
                        setState(() {
                          startYear = newValue!;
                          if (startYear == endYear &&
                              startDateMonth > endDateMonth) {
                            endDateMonth = startDateMonth;
                          }
                          _adjustEndDate();
                        });
                      }),
                      Text('年'),
                      SizedBox(width: 8.0),
                      _buildDropdown(
                          getAvailableMonthsStart(startYear), startDateMonth,
                          (newValue) {
                        setState(() {
                          startDateMonth = newValue!;
                          if (!getAvailableDaysStart(startYear, startDateMonth)
                              .contains(startDateDay)) {
                            startDateDay =
                                getAvailableDaysStart(startYear, startDateMonth)
                                    .first;
                          }
                          _adjustEndDate();
                        });
                      }),
                      Text('月'),
                      SizedBox(width: 8.0),
                      _buildDropdown(
                          getAvailableDaysStart(startYear, startDateMonth),
                          startDateDay, (newValue) {
                        setState(() {
                          startDateDay = newValue!;
                          _adjustEndDate();
                        });
                      }),
                      Text('日 から '),
                      Spacer(flex: 2),
                    ],
                  ),
                  Row(
                    children: [
                      Spacer(flex: 1),
                      _buildDropdown(getAvailableYears(), endYear, (newValue) {
                        setState(() {
                          endYear = newValue!;
                          _adjustEndDate();
                        });
                      }),
                      Text('年'),
                      SizedBox(width: 8.0),
                      _buildDropdown(getAvailableMonths(endYear), endDateMonth,
                          (newValue) {
                        setState(() {
                          endDateMonth = newValue!;
                          _adjustEndDate();
                        });
                      }),
                      Text('月'),
                      SizedBox(width: 8.0),
                      _buildDropdown(
                          getAvailableDays(endYear, endDateMonth), endDateDay,
                          (newValue) {
                        setState(() {
                          endDateDay = newValue!;
                          if (!getAvailableDays(endYear, endDateMonth)
                              .contains(endDateDay)) {
                            endDateDay =
                                getAvailableDaysStart(endYear, endDateMonth)
                                    .first;
                          }
                          _adjustEndDate();
                        });
                      }),
                      Text('日まで'),
                      Spacer(flex: 1),
                    ],
                  ),
                  Row(
                    children: [
                      _buildDropdown(hours, startTime, (newValue) {
                        setState(() {
                          startTime = newValue!;
                          if (startTime > endTime) {
                            endTime = startTime;
                          }
                        });
                      }),
                      Text('時 から '),
                      SizedBox(width: 8.0),
                      _buildDropdown(
                          hours.where((hour) => hour >= startTime).toList(),
                          endTime, (newValue) {
                        setState(() {
                          endTime = newValue!;
                        });
                      }),
                      Text('時まで'),
                      Spacer(flex: 5),
                    ],
                  ),
                  Row(
                    children: [
                      Text('最低'),
                      SizedBox(width: 8.0),
                      _buildDropdown(minHoursOptions, minHours, (newValue) {
                        setState(() {
                          minHours = newValue!;
                        });
                      }),
                      Text('時間'),
                      Spacer(flex: 10),
                    ],
                  ),
                  Row(
                    children: [
                      Text('最低'),
                      SizedBox(width: 8.0),
                      _buildDropdown(
                          List.generate(GroupSize, (index) => index + 1),
                          minParticipants, (newValue) {
                        setState(() {
                          minParticipants = newValue!;
                        });
                      }),
                      Text('人参加可能'),
                      Spacer(flex: 10),
                    ],
                  ),
                  SizedBox(height: 16.0),
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
                              selectedCity = cities.first;
                            }
                          });
                        },
                        activeColor: GlobalColor.MainCol, // color of the toggle
                        inactiveTrackColor:
                            GlobalColor.SubCol, // color of the background
                        inactiveThumbColor: GlobalColor
                            .Unselected, // color of the thumb when the switch is off
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
                    Row(
                      children: [
                        Checkbox(
                          value: isSunny,
                          onChanged: (bool? value) {
                            setState(() {
                              isSunny = value!;
                            });
                          },
                          activeColor: GlobalColor
                              .SubCol, // color of the checkbox when selected
                          checkColor:
                              GlobalColor.MainCol, // color of the checkmark
                        ),
                        Text('晴れ'),
                        Checkbox(
                          value: isCloudy,
                          onChanged: (bool? value) {
                            setState(() {
                              isCloudy = value!;
                            });
                          },
                          activeColor: GlobalColor
                              .SubCol, // color of the checkbox when selected
                          checkColor:
                              GlobalColor.MainCol, // color of the checkmark
                        ),
                        Text('曇り'),
                        Checkbox(
                          value: isRainy,
                          onChanged: (bool? value) {
                            setState(() {
                              isRainy = value!;
                            });
                          },
                          activeColor: GlobalColor
                              .SubCol, // color of the checkbox when selected
                          checkColor:
                              GlobalColor.MainCol, // color of the checkmark
                        ),
                        Text('雨'),
                        Checkbox(
                          value: isSnowy,
                          onChanged: (bool? value) {
                            setState(() {
                              isSnowy = value!;
                            });
                          },
                          activeColor: GlobalColor
                              .SubCol, // color of the checkbox when selected
                          checkColor:
                              GlobalColor.MainCol, // color of the checkmark
                        ),
                        Text('雪'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.0),
          Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Add padding for a better appearance
                  child:considerWeather? Text(
                    '出典：気象庁ＨＰ',
                    style: TextStyle(
                      fontSize: 10, // Smaller font size
                      color: Colors.black87, // Light font color
                    ),
                  ):Container(),
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _searchSchedule,
                      child: Text('検索',
                          style: TextStyle(fontSize: 20, color: GlobalColor.SubCol)),
                    ),
                    SizedBox(width: 20), // Spacing between button and dropdown
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
          ),


          SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  // Determine the weather icon based on the weather code
                  IconData weatherIcon;
                  switch (searchResults[index].weather) {
                    case -1:
                      weatherIcon = Icons.help_outline; // '?' icon for -1
                      break;
                    case 0:
                      weatherIcon = Icons.wb_sunny; // 'sun' icon for 0
                      break;
                    case 1:
                      weatherIcon = Icons.cloud; // 'cloud' icon for 1
                      break;
                    case 2:
                      weatherIcon = Icons.beach_access; // 'rain' icon for 2
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
                      '${formatDateTime(searchResults[index].startTime)} ~ ${formatDateTime(searchResults[index].endTime)}',
                    ),
                    subtitle: searchResults[index].count != 0
                        ? Text('${searchResults[index].count}人参加できません')
                        : Text('全員参加可能'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        searchResults[index].members.length != 0
                            ? IconButton(
                                icon: Icon(Icons.warning, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('参加不可のユーザー'),
                                        content: Container(
                                          width: double.maxFinite,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: searchResults[index]
                                                .members
                                                .length,
                                            itemBuilder: (context, i) {
                                              return Row(
                                                children: [
                                                  CircleAvatar(
                                                    backgroundImage: NetworkImage(
                                                        'https://calendar-files.woody1227.com/user_icon/${searchResults[index].members[i].uicon}'),
                                                    radius: 20,
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          10), // Space between image and text
                                                  Text(
                                                      '${searchResults[index].members[i].uname}'),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        actions: <Widget>[
                                          ElevatedButton(
                                            child: Text('Close'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              )
                            : Container(),
                        considerWeather ? Icon(weatherIcon) : Container(),
                        SizedBox(width: 8.0),
                        considerWeather
                            ? Text(
                                searchResults[index].reliability?.isNotEmpty ==
                                        true
                                    ? searchResults[index].reliability
                                    : '--')
                            : Container(),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            _showScheduleDialog(context, index);
                          },
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
  Future<void> SendRequest(String uid2, String Summary, DateTime startTime, DateTime endTime)
  async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    print('uid: $uid uid2: $uid2 Summary: $Summary startTime: $startTime endTime: $endTime');
    await SendEventRequest().sendEventRequest(
        uid, uid2, widget.groupId, Summary, startTime, endTime);
  }
  Future<void> AddSchedule(String Summary, DateTime startTime, DateTime endTime)async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    AddEventToTheCalendar().addEventToTheCalendar(uid, primaryCalendar, Summary, '', startTime, endTime);
  }
  void _showScheduleDialog(BuildContext context, int index) {
    // Initialize selected values
    int selectedHour = searchResults[index].startTime.hour;
    int selectedMinute = searchResults[index].startTime.minute;
    int selectedDurationHours = 0;
    int selectedDurationMinutes = 0;

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('予定を追加'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Input field for the summary
                  TextField(
                    controller: SummaryEditor,
                    decoration: InputDecoration(
                      labelText: '予定名',
                      contentPadding: EdgeInsets.symmetric(vertical: 10), // Reduce vertical padding
                    ),
                    onChanged: (String value) {
                      setState(() {
                        Summary = value;
                      });
                    },
                  ),
                  SizedBox(height: 10), // Reduce spacing between widgets
                  Text('予定開始時刻'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 100, // Reduce height
                        width: 45,   // Adjust width if necessary
                        child: CupertinoPicker(
                          itemExtent: 28.0, // Reduce item height
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              selectedHour = startHour + index;
                              if (selectedHour == startHour) {
                                if (selectedMinute < startMinute) {
                                  selectedMinute = startMinute;
                                }
                              }
                              if (selectedHour == endHour) {
                                if (selectedMinute > endMinute) {
                                  selectedMinute = endMinute;
                                }
                              }
                            });
                          },
                          children: List.generate(
                            endHour - startHour + 1,
                                (int index) => Text('${startHour + index}時'),
                          ),
                        ),
                      ),
                      SizedBox(width: 8), // Reduce width
                      Container(
                        height: 100, // Reduce height
                        width: 45,   // Adjust width if necessary
                        child: CupertinoPicker(
                          itemExtent: 28.0, // Reduce item height
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
                              return Text('$formattedMinute分');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20), // Reduce vertical space
                  // Duration Picker
                  Text('予定長さ'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 80,  // Reduce height
                        width: 45,   // Adjust width if necessary
                        child: CupertinoPicker(
                          itemExtent: 28.0, // Reduce item height
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              selectedDurationHours = index;
                            });
                          },
                          children: List.generate(
                            24,
                                (int index) => Text('$index h'),
                          ),
                        ),
                      ),
                      SizedBox(width: 8), // Reduce width
                      Container(
                        height: 80,  // Reduce height
                        width: 45,   // Adjust width if necessary
                        child: CupertinoPicker(
                          itemExtent: 28.0, // Reduce item height
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              selectedDurationMinutes = index * 5; // 5 minute intervals
                            });
                          },
                          children: List.generate(
                            12,
                                (int index) => Text('${index * 5} m'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              actions: <Widget>[
                ElevatedButton(
                  child: Text('予定追加リクエストの送信',style: TextStyle(color: GlobalColor.SubCol),),
                  onPressed: () {
                    exceedTime = 0;
                    final totalSelectedTimeInMinutes =
                        (selectedHour * 60 + selectedMinute);
                    final totalSelectedDurationInMinutes =
                        (selectedDurationHours * 60 + selectedDurationMinutes);
                    final totalEndTimeInMinutes =
                        (searchResults[index].endTime.hour * 60 +
                            searchResults[index].endTime.minute);

                    if (totalSelectedTimeInMinutes +
                            totalSelectedDurationInMinutes >
                        totalEndTimeInMinutes) {
                      exceedTime = 1;
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('エラー'),
                            content: Text(
                                '選択した時間は終了時間を超えています。一部ユーザーが参加不可能になる可能性がありますが続行しますか？'),
                            actions: <Widget>[
                              ElevatedButton(
                                child: Text('続行',style: TextStyle(color: GlobalColor.SubCol),),
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
                                  AddSchedule(Summary, DateTime(
                                      searchResults[index].startTime.year,
                                      searchResults[index]
                                          .startTime
                                          .month,
                                      searchResults[index].startTime.day,
                                      selectedHour,
                                      selectedMinute), DateTime(
                                      searchResults[index].startTime.year,
                                      searchResults[index]
                                          .startTime
                                          .month,
                                      searchResults[index].startTime.day,
                                      selectedHour +
                                          selectedDurationHours,
                                      selectedMinute +
                                          selectedDurationMinutes));
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  print('done');
                                },
                              ),
                              ElevatedButton(
                                child: Text('キャンセル',style: TextStyle(color: GlobalColor.SubCol),),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (exceedTime == 1) return;
                    if (totalSelectedDurationInMinutes == 0) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('エラー'),
                            content: Text('予定の長さを指定してください。'),
                            actions: <Widget>[
                              ElevatedButton(
                                child: Text('閉じる',style: TextStyle(color: GlobalColor.SubCol),),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else if (searchResults[index].members.length == 0 ||
                        exceedTime == 2) {
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
                      AddSchedule(Summary, DateTime(
                          searchResults[index].startTime.year,
                          searchResults[index]
                              .startTime
                              .month,
                          searchResults[index].startTime.day,
                          selectedHour,
                          selectedMinute), DateTime(
                          searchResults[index].startTime.year,
                          searchResults[index]
                              .startTime
                              .month,
                          searchResults[index].startTime.day,
                          selectedHour +
                              selectedDurationHours,
                          selectedMinute +
                              selectedDurationMinutes));
                      Navigator.of(context).pop();
                    } else if (searchResults[index].members.length != 0) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('予定追加リクエストの送信先'),
                            actions: <Widget>[
                              ElevatedButton(
                                child: Text('参加できる人のみに送信',style: TextStyle(color: GlobalColor.SubCol),),
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
                                  }

                                  AddSchedule(Summary, DateTime(
                                      searchResults[index].startTime.year,
                                      searchResults[index]
                                          .startTime
                                          .month,
                                      searchResults[index].startTime.day,
                                      selectedHour,
                                      selectedMinute), DateTime(
                                      searchResults[index].startTime.year,
                                      searchResults[index]
                                          .startTime
                                          .month,
                                      searchResults[index].startTime.day,
                                      selectedHour +
                                          selectedDurationHours,
                                      selectedMinute +
                                          selectedDurationMinutes));
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                },
                              ),
                              ElevatedButton(
                                child: Text('参加できない人にも送信',style: TextStyle(color: GlobalColor.SubCol),),
                                onPressed: () {
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

                                  AddSchedule(Summary, DateTime(
                                      searchResults[index].startTime.year,
                                      searchResults[index]
                                          .startTime
                                          .month,
                                      searchResults[index].startTime.day,
                                      selectedHour,
                                      selectedMinute), DateTime(
                                      searchResults[index].startTime.year,
                                      searchResults[index]
                                          .startTime
                                          .month,
                                      searchResults[index].startTime.day,
                                      selectedHour +
                                          selectedDurationHours,
                                      selectedMinute +
                                          selectedDurationMinutes));
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                },
                              ),
                              ElevatedButton(
                                child: Text('キャンセル',style: TextStyle(color: GlobalColor.SubCol),),
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
                ElevatedButton(
                  child: Text('キャンセル',style: TextStyle(color: GlobalColor.SubCol),),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
