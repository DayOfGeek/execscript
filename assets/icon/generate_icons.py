#!/usr/bin/env python3
"""
Generate ExecScript app icons in the CyberTerm aesthetic.
# script/hash symbol in phosphor green on deep black.
Uses DejaVu Sans Mono (available on most Linux systems).

Symbol choice: # (hash/pound)
- Classic shell comment indicator
- Instantly recognizable as "script" in terminal context
- Pairs with ExecPrompt's >_ (prompt) symbol
- Simple, bold, and clear at small sizes
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Brand colors - matching ExecPrompt
BG_COLOR = (10, 15, 10)  # #0A0F0A deep black-green
FG_COLOR = (51, 255, 51)  # #33FF33 phosphor green
GLOW_COLOR = (26, 138, 26)  # #1A8A1A dimmed green for subtle glow

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def find_mono_font():
    """Find a monospace font on the system."""
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/ubuntu/UbuntuMono-B.ttf",
        "/usr/share/fonts/truetype/msttcorefonts/courbd.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return path
    return None


def generate_icon(size, filename, is_foreground=False):
    """Generate a single icon at the given size."""
    if is_foreground:
        # Adaptive icon foreground: transparent background, symbol centered
        # Android adaptive icons use 108dp with 72dp safe zone (66% of canvas)
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    else:
        img = Image.new("RGBA", (size, size), BG_COLOR + (255,))

    draw = ImageDraw.Draw(img)

    font_path = find_mono_font()
    if not font_path:
        print("ERROR: No monospace font found!")
        return

    # Calculate font size - the "#" should be prominent
    # For full icon: use ~50% of canvas (single char is bolder)
    # For foreground: use ~40% of canvas (safe zone constraint)
    if is_foreground:
        font_size = int(size * 0.35)
    else:
        font_size = int(size * 0.50)

    font = ImageFont.truetype(font_path, font_size)

    # The # symbol - classic script/shell comment indicator
    text = "#"

    # Get text bounding box for centering
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    x = (size - text_width) / 2 - bbox[0]
    y = (size - text_height) / 2 - bbox[1]

    # Draw subtle glow layer (slightly larger, dimmed)
    if not is_foreground or size >= 256:
        for dx in [-2, -1, 0, 1, 2]:
            for dy in [-2, -1, 0, 1, 2]:
                if dx == 0 and dy == 0:
                    continue
                draw.text((x + dx, y + dy), text, font=font, fill=GLOW_COLOR + (60,))

    # Draw main text
    draw.text((x, y), text, font=font, fill=FG_COLOR + (255,))

    # Add a subtle scanline effect for larger icons
    if size >= 192 and not is_foreground:
        for sy in range(0, size, 4):
            draw.line([(0, sy), (size, sy)], fill=(0, 0, 0, 25), width=1)

    # Add thin border for non-foreground icons
    if not is_foreground and size >= 96:
        border_color = (26, 58, 26, 180)  # #1A3A1A with alpha
        draw.rectangle(
            [(2, 2), (size - 3, size - 3)],
            outline=border_color,
            width=1,
        )

    filepath = os.path.join(SCRIPT_DIR, filename)
    img.save(filepath, "PNG")
    print(f"  Generated: {filename} ({size}x{size})")


def generate_android_mipmaps():
    """Generate Android mipmap icons to project location."""
    android_base = "/home/zervin/projects/dofg/execscript/android/app/src/main/res"

    mipmap_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }

    print("  Android mipmap icons:")
    for folder, size in mipmap_sizes.items():
        # Generate in temp location first, then copy
        filename = f"ic_launcher_{size}.png"
        generate_icon(size, filename)

        # Copy to Android location
        src = os.path.join(SCRIPT_DIR, filename)
        dst_dir = os.path.join(android_base, folder)
        os.makedirs(dst_dir, exist_ok=True)
        dst = os.path.join(dst_dir, "ic_launcher.png")

        # Read and write the file
        img = Image.open(src)
        img.save(dst, "PNG")
        print(f"    -> {folder}/ic_launcher.png ({size}x{size})")
        os.remove(src)  # Clean up temp file


def generate_android_adaptive_foreground():
    """Generate Android adaptive icon foreground (432x432)."""
    android_base = (
        "/home/zervin/projects/dofg/execscript/android/app/src/main/res/mipmap-xxxhdpi"
    )

    filename = "execscript_icon_foreground.png"
    generate_icon(432, filename, is_foreground=True)

    src = os.path.join(SCRIPT_DIR, filename)
    os.makedirs(android_base, exist_ok=True)
    dst = os.path.join(android_base, "ic_launcher_foreground.png")

    img = Image.open(src)
    img.save(dst, "PNG")
    print(f"    -> mipmap-xxxhdpi/ic_launcher_foreground.png (432x432)")
    os.remove(src)


def generate_ios_icons():
    """Generate iOS app icons to project location."""
    ios_base = "/home/zervin/projects/dofg/execscript/ios/Runner/Assets.xcassets/AppIcon.appiconset"

    # iOS icon sizes based on Contents.json
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }

    print("  iOS app icons:")
    for filename, size in ios_sizes.items():
        temp_name = f"ios_{filename}"
        generate_icon(size, temp_name)

        src = os.path.join(SCRIPT_DIR, temp_name)
        dst = os.path.join(ios_base, filename)

        img = Image.open(src)
        img.save(dst, "PNG")
        print(f"    -> {filename} ({size}x{size})")
        os.remove(src)


def generate_macos_icons():
    """Generate macOS app icons to project location."""
    macos_base = "/home/zervin/projects/dofg/execscript/macos/Runner/Assets.xcassets/AppIcon.appiconset"

    macos_sizes = {
        "app_icon_16.png": 16,
        "app_icon_32.png": 32,
        "app_icon_64.png": 64,
        "app_icon_128.png": 128,
        "app_icon_256.png": 256,
        "app_icon_512.png": 512,
        "app_icon_1024.png": 1024,
    }

    print("  macOS app icons:")
    for filename, size in macos_sizes.items():
        temp_name = f"macos_{filename}"
        generate_icon(size, temp_name)

        src = os.path.join(SCRIPT_DIR, temp_name)
        dst = os.path.join(macos_base, filename)

        img = Image.open(src)
        img.save(dst, "PNG")
        print(f"    -> {filename} ({size}x{size})")
        os.remove(src)  # Remove temp file with full path


def generate_web_icons():
    """Generate web favicon and manifest icons."""
    web_base = "/home/zervin/projects/dofg/execscript/web"

    # Favicon (32x32)
    generate_icon(32, "favicon_temp.png")
    src = os.path.join(SCRIPT_DIR, "favicon_temp.png")
    dst = os.path.join(web_base, "favicon.png")
    img = Image.open(src)
    img.save(dst, "PNG")
    print("    -> web/favicon.png (32x32)")
    os.remove(src)


def main():
    print("=" * 60)
    print("# GENERATING EXECSCRIPT ICONS...")
    print("# Symbol: # (hash/shell comment)")
    print("# Style: Cyberpunk terminal aesthetic")
    print("=" * 60)
    print()

    # 1. Base icon (1024x1024) - master source
    print("1. Master icon:")
    generate_icon(1024, "execscript_icon.png")

    # 2. Adaptive foreground (432x432)
    print("\n2. Android adaptive icon foreground:")
    generate_icon(432, "execscript_icon_foreground.png", is_foreground=True)

    # 3. Android mipmap icons
    print("\n3. Android mipmap icons:")
    generate_android_mipmaps()
    generate_android_adaptive_foreground()

    # 4. iOS icons
    print("\n4. iOS icons:")
    generate_ios_icons()

    # 5. macOS icons
    print("\n5. macOS icons:")
    generate_macos_icons()

    # 6. Web icons
    print("\n6. Web icons:")
    generate_web_icons()

    # 7. Play Store / App Store high-res
    print("\n7. Store icons:")
    generate_icon(512, "execscript_playstore_512.png")
    generate_icon(1024, "execscript_appstore_1024.png")

    print()
    print("=" * 60)
    print("# ICON GENERATION COMPLETE")
    print(f"# Output directory: {SCRIPT_DIR}")
    print("=" * 60)


if __name__ == "__main__":
    main()
