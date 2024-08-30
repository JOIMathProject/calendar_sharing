import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;
import 'package:googleapis/chat/v1.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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
  int endDateMonth = DateTime.now().month+1;
  int startDateDay = DateTime.now().day;
  int endDateDay = DateTime.now().day;
  int startTime = 8;
  int endTime = 20;
  int minHours = 1;
  int minMinutes = 0;
  int minParticipants = 1;
  int GroupSize = 6;

  void initState() {
    super.initState();
    _getGroupSize();
  }

  List<int> years = List.generate(10, (index) => DateTime.now().year + index);
  List<int> months = List.generate(12, (index) => index + 1);
  List<int> days = List.generate(31, (index) => index + 1);
  List<int> hours = List.generate(24, (index) => index);
  List<int> minHoursOptions = List.generate(8, (index) => index);

  List<Appointment> searchResults = [];

  List<int> getAvailableDays(int year, int month) {
    int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    DateTime selectedDate = DateTime(year, month, 1);
    int startDayLimit = (selectedDate.isAfter(now) || selectedDate.isAtSameMomentAs(now)) ? 1 : now.day;

    if (year == startYear && month == startDateMonth) {
      startDayLimit = startDateDay;
    }
    return List.generate(lastDayOfMonth - startDayLimit + 1, (index) => startDayLimit + index);
  }
  List<int> getAvailableDaysStart(int year, int month) {
    int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    int startDayLimit = 1;

    if (year == startYear && month == DateTime.now().month) {
      startDayLimit = DateTime.now().day;
    }
    return List.generate(lastDayOfMonth - startDayLimit + 1, (index) => startDayLimit + index);
  }

  List<int> getAvailableMonths(int year) {
    int startMonthLimit = (year == now.year) ? now.month : 1;

    if (year == startYear) {
      startMonthLimit = startDateMonth;
    }
    return List.generate(12 - startMonthLimit + 1, (index) => startMonthLimit + index);
  }

  List<int> getAvailableMonthsStart(int year) {
    int startMonthLimit = (year == now.year) ? now.month : 1;

    if (year == startYear) {
      startMonthLimit = DateTime.now().month;
    }
    return List.generate(12 - startMonthLimit + 1, (index) => startMonthLimit + index);
  }
  List<int> getAvailableYears() {
    return years.where((year) {
      DateTime startDate = DateTime(startYear, startDateMonth, startDateDay);
      DateTime endDate = DateTime(year, endDateMonth, endDateDay);
      return endDate.isAfter(now) &&
          endDate.isBefore(startDate.add(Duration(days: 182))); // Limit to 6 months
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
  Future<void> _getGroupSize() async{
    var group = await GetUserInGroup().getUserInGroup(widget.groupId);
    GroupSize = group.length;
    setState(() {});
  }
  Future<void> _searchSchedule() async {
    String formatWithLeadingZero(int value) {
      return value.toString().padLeft(2, '0');
    }

    String formattedStartDateMonth = formatWithLeadingZero(startDateMonth);
    String formattedEndDateMonth = formatWithLeadingZero(endDateMonth);
    String formattedStartDateDay = formatWithLeadingZero(startDateDay);
    String formattedEndDateDay = formatWithLeadingZero(endDateDay);
    String formattedStartTime = formatWithLeadingZero(startTime);
    String formattedEndTime = formatWithLeadingZero(endTime);
    print(widget.groupId);
    print('$startYear-$formattedStartDateMonth-$formattedStartDateDay');
    print('$endYear-$formattedEndDateMonth-$formattedEndDateDay');
    print(formattedStartTime);
    print(formattedEndTime);
    print(GroupSize-minParticipants);
    searchResults = await SearchContentSchedule().searchContentSchedule(
      widget.groupId,
      '$startYear-$formattedStartDateMonth-$formattedStartDateDay',
      '$endYear-$formattedEndDateMonth-$formattedEndDateDay',
      formattedStartTime,
      '00',
      formattedEndTime,
      '00',
      '${minHours * 60}',
      '${GroupSize-minParticipants}',
    );

    setState(() {});
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
      startDateDay = getAvailableDays(startYear, startDateMonth).first;
    }

    if (!getAvailableDays(endYear, endDateMonth).contains(endDateDay)) {
      endDateDay = getAvailableDays(endYear, endDateMonth).first;
    }
    List<int> availableStartDays = getAvailableDaysStart(startYear, startDateMonth);
    if (!availableStartDays.contains(startDateDay)) {
      startDateDay = availableStartDays.isNotEmpty ? availableStartDays.first : 1;
    }

    List<int> availableEndDays = getAvailableDays(endYear, endDateMonth);
    if (!availableEndDays.contains(endDateDay)) {
      endDateDay = availableEndDays.isNotEmpty ? availableEndDays.first : 1;
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.SubCol,
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
            SizedBox(height: 16.0),
            Row(
              children: [
                _buildDropdown(getAvailableYears(), startYear, (newValue) {
                  setState(() {
                    startYear = newValue!;
                    if (startYear == endYear && startDateMonth > endDateMonth) {
                      endDateMonth = startDateMonth;
                    }
                    _adjustEndDate();
                  });
                }),
                Text('年'),
                SizedBox(width: 8.0),
                _buildDropdown(getAvailableMonthsStart(startYear), startDateMonth, (newValue) {
                  setState(() {
                    startDateMonth = newValue!;
                    if (!getAvailableDaysStart(startYear, startDateMonth).contains(startDateDay)) {
                      startDateDay = getAvailableDaysStart(startYear, startDateMonth).first;
                    }
                    _adjustEndDate();
                  });
                }),
                Text('月'),
                SizedBox(width: 8.0),
                _buildDropdown(getAvailableDaysStart(startYear, startDateMonth), startDateDay, (newValue) {
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
                Spacer(flex: 2),
                _buildDropdown(getAvailableYears(), endYear, (newValue) {
                  setState(() {
                    endYear = newValue!;
                    _adjustEndDate();
                  });
                }),
                Text('年'),
                SizedBox(width: 8.0),
                _buildDropdown(getAvailableMonths(endYear), endDateMonth, (newValue) {
                  setState(() {
                    endDateMonth = newValue!;
                    _adjustEndDate();
                  });
                }),
                Text('月'),
                SizedBox(width: 8.0),
                _buildDropdown(getAvailableDays(endYear, endDateMonth), endDateDay, (newValue) {
                  setState(() {
                    endDateDay = newValue!;
                    if (!getAvailableDays(endYear, endDateMonth).contains(endDateDay)) {
                      endDateDay = getAvailableDaysStart(endYear, endDateMonth).first;
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
                _buildDropdown(hours.where((hour) => hour >= startTime).toList(), endTime, (newValue) {
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
                _buildDropdown(List.generate(GroupSize, (index) => index + 1), minParticipants, (newValue) {
                  setState(() {
                    minParticipants = newValue!;
                  });
                }),
                Text('人参加可能'),
                Spacer(flex: 10),
              ],
            ),
            SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: _searchSchedule,
                child: Text('検索'),
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(searchResults[index].startTime.toString() +
                        ' - ' +
                        searchResults[index].endTime.toString()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(List<int> options, int value, ValueChanged<int?> onChanged) {
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
}
