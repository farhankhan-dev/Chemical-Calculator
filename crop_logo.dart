import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/icons/logo.png');
  if (!file.existsSync()) {
    print('assets/icons/logo.png not found');
    return;
  }
  
  final bytes = file.readAsBytesSync();
  var image = img.decodeImage(bytes);
  
  if (image == null) {
    print('Failed to decode image');
    return;
  }
  
  // Ensure the image has an alpha channel
  if (image.numChannels != 4) {
    // Note: in image v4, we can just use the image directly, but setting alpha on a 3-channel image might not stick.
    // We can convert it to 4 channels.
    image = image.convert(numChannels: 4);
  }
  
  // Find bounding box to crop empty white/transparent space
  int minX = image.width;
  int minY = image.height;
  int maxX = 0;
  int maxY = 0;
  
  for (final pixel in image) {
    final r = pixel.r;
    final g = pixel.g;
    final b = pixel.b;
    
    // If it's a white pixel, make it transparent
    if (r >= 240 && g >= 240 && b >= 240) {
      pixel.a = 0;
    } else if (pixel.a > 0) {
      // It's a non-white, non-transparent pixel
      if (pixel.x < minX) minX = pixel.x.toInt();
      if (pixel.y < minY) minY = pixel.y.toInt();
      if (pixel.x > maxX) maxX = pixel.x.toInt();
      if (pixel.y > maxY) maxY = pixel.y.toInt();
    }
  }
  
  if (minX <= maxX && minY <= maxY) {
    // Crop the image to the bounding box
    final cropped = img.copyCrop(image, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
    file.writeAsBytesSync(img.encodePng(cropped));
    print('Logo successfully cropped and white background removed!');
  } else {
    // If we didn't find any non-white pixels, just save the transparent image
    file.writeAsBytesSync(img.encodePng(image));
    print('Made white pixels transparent, but did not crop (image is mostly white).');
  }
}
