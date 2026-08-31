void main() {
  String text = "CuSO4.5H2O now gives 260.402";
  for (int i = 0; i < text.length; i++) {
    print('${text[i]} : ${text.codeUnitAt(i)}');
  }
}
