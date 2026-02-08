import 'package:flutter/material.dart';

const Color kBgColor = Color(0xFFD4E6F4);
const Color kThemeColor = Color(0xFF5D99C6);
const Color kDarkTextColor = Color(0xFF2C4C66);

const List<Color> kGoogleColors = [
  Color(0xFF7986CB),
  Color(0xFF33B679),
  Color(0xFF8E24AA),
  Color(0xFFE67C73),
  Color(0xFFF6BF26),
  Color(0xFFF4511E),
  Color(0xFF039BE5),
  Color(0xFF616161),
  Color(0xFF0B8043),
  Color(0xFFD50000),
  Color(0xFF3F51B5),
  Color(0xFF5D99C6),
];

const List<String> kCategoryNames = [
  '買い物',
  '食事',
  '遊び',
  '仕事',
  '休み',
  '学校',
  '交通',
  '旅行',
  '趣味',
  'その他',
];

const Map<String, IconData> kCategoryIcons = {
  '買い物': Icons.shopping_cart,
  '食事': Icons.restaurant,
  '遊び': Icons.sports_esports,
  '仕事': Icons.work,
  '休み': Icons.calendar_today,
  '学校': Icons.school,
  '交通': Icons.train,
  '旅行': Icons.flight,
  '趣味': Icons.favorite,
  'その他': Icons.more_horiz,
};

const Map<String, String> kCategoryListName = {
  '買い物': '買い物リスト',
  '食事': 'メニューリスト',
  '遊び': 'やることリスト',
  '仕事': 'タスクリスト',
  '休み': '予定リスト',
  '学校': '課題リスト',
  '交通': '乗換リスト',
  '旅行': '持ち物リスト',
  '趣味': 'やりたいリスト',
  'その他': 'チェックリスト',
};

const List<String> kWeekDays = ['日', '月', '火', '水', '木', '金', '土'];

/// Build a category icon widget. For '休み', renders a calendar icon
/// with the character '休' overlaid in the center.
Widget buildCategoryIcon(String category, {required double size, required Color color}) {
  if (category == '休み') {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.calendar_today, size: size, color: color),
          Padding(
            padding: EdgeInsets.only(top: size * 0.15),
            child: Text(
              '休',
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
  return Icon(
    kCategoryIcons[category] ?? Icons.circle,
    size: size,
    color: color,
  );
}
