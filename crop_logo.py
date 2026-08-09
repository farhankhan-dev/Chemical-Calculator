import sys
import subprocess

# Try to install Pillow if it's not installed
try:
    from PIL import Image
except ImportError:
    print("Pillow not installed. Installing Pillow now...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image

try:
    img = Image.open('assets/icons/logo.png')
    img = img.convert('RGBA')
    
    # Get bounding box of non-white pixels
    # First, convert to grayscale to find white pixels easily
    gray = img.convert('L')
    # Anything below 250 is considered non-white
    bw = gray.point(lambda x: 0 if x > 250 else 255, '1')
    bbox = bw.getbbox()
    
    if bbox:
        img = img.crop(bbox)
        img.save('assets/icons/logo.png')
        print('Logo cropped successfully! The white outline has been removed.')
    else:
        print('Could not find non-white pixels. Image might be completely white or already cropped.')
except Exception as e:
    print(f"An error occurred: {e}")
