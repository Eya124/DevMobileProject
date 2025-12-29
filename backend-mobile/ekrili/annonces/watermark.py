from PIL import Image, ImageDraw, ImageFont
from io import BytesIO
from django.core.files.base import ContentFile

def add_watermark(image_file, text="EKRI"):
    image = Image.open(image_file)

    if image.mode != 'RGB':
        image = image.convert('RGB')

    draw = ImageDraw.Draw(image)

    # Ubuntu default font path
    font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

    # Adjust size dynamically based on image height (e.g., 5% of height)
    font_size = int(image.height * 0.05)
    font = ImageFont.truetype(font_path, font_size)

    # Calculate text size
    bbox = draw.textbbox((0, 0), text, font=font)
    textwidth = bbox[2] - bbox[0]
    textheight = bbox[3] - bbox[1]

    # Bottom-right position
    x = image.width - textwidth - 20
    y = image.height - textheight - 20

    # Add shadow for visibility
    draw.text((x+2, y+2), text, font=font, fill="black")  # Shadow
    draw.text((x, y), text, font=font, fill="white")      # Main text

    buffer = BytesIO()
    image.save(buffer, format='JPEG')
    return ContentFile(buffer.getvalue(), name=image_file.name)


from django.core.files.uploadedfile import SimpleUploadedFile
# Load an image from disk
with open("/home/heni/ekrili/media/143/bb.png", "rb") as f:
    image_file = SimpleUploadedFile("/home/heni/ekrili/media/143/bb.png", f.read(), content_type="image/jpeg")

# Add watermark
watermarked = add_watermark(image_file)

# Save to disk for visual confirmation
with open("/home/heni/ekrili/media/143/test_image_watermarked1.jpg", "wb") as f:
    f.write(watermarked.read())