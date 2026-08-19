// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('C:\\chemi_calc\\assets\\icons\\logo.png');
  final bytes = file.readAsBytesSync();
  final image = img.decodePng(bytes)!;
  final w = image.width;
  final h = image.height;
  
  // Create backup if not exists
  final backup = File('C:\\chemi_calc\\assets\\icons\\logo_backup.png');
  if (!backup.existsSync()) {
    backup.writeAsBytesSync(bytes);
  }
  
  // We want to turn the dark blue symbols (+, -, x) to white.
  // They are located in the bounding boxes:
  // Top-left (+): x in [0.35w, 0.5w], y in [0.55h, 0.68h]
  // Top-right (-): x in [0.5w, 0.65w], y in [0.55h, 0.68h]
  // Bottom-left (x): x in [0.35w, 0.5w], y in [0.68h, 0.8h]
  
  for (int y = (0.55 * h).floor(); y < (0.8 * h).floor(); y++) {
    for (int x = (0.35 * w).floor(); x < (0.65 * w).floor(); x++) {
      // Skip the bottom-right square (=)
      if (x > 0.5 * w && y > 0.68 * h) continue;
      
      final p = image.getPixel(x, y);
      
      // If it's a dark blue pixel (part of the symbols)
      if (p.b > 140 && p.r < 120 && p.g < 140) {
        image.setPixelRgba(x, y, 255, 255, 255, p.a);
      }
    }
  }
  
  // Save the modified image
  file.writeAsBytesSync(img.encodePng(image));
  print('Image modified and saved successfully.');
}
