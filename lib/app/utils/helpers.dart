String getChatRoomId(String a, String b) {
  final ids = [a, b]..sort();
  return '${ids[0]}_${ids[1]}';
}