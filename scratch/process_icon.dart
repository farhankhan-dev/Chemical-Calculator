// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final inputPath = r'C:\Users\Admin\.gemini\antigravity-ide\brain\768c7ca3-daa5-4b63-a9ff-431718c13e34\periodic_table_icon_gen_1786625133964.png';
  final outputPath = r'C:\chemi_calc\assets\icons\periodic_table_icon.png';
  
  final file = File(inputPath);
  if (!file.existsSync()) {
    print('Generated image not found');
    return;
  }
  
  final bytes = file.readAsBytesSync();
  var image = img.decodeImage(bytes);
  
  if (image == null) {
    print('Failed to decode image');
    return;
  }
  
  if (image.numChannels != 4) {
    image = image.convert(numChannels: 4);
  }
  
  for (final pixel in image) {
    // Calculate brightness (0 to 255)
    final r = pixel.r;
    final g = pixel.g;
    final b = pixel.b;
    
    // Use luminance
    final brightness = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
    
    // We want black lines (brightness 0) to be opaque (alpha 255)
    // White background (brightness 255) to be transparent (alpha 0)
    final alpha = (255 - brightness).clamp(0, 255);
    
    // Set color to pure white, but with the calculated alpha
    // (So it's a white mask icon)
    pixel.r = 255;
    pixel.g = 255;
    pixel.b = 255;
    pixel.a = alpha;
  }
  
  File(outputPath).writeAsBytesSync(img.encodePng(image));
  print('Icon successfully processed and saved to $outputPath');
}
