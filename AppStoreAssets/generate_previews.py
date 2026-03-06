#!/usr/bin/env python3
"""Generate premium App Store preview images for Sticky Markdown."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

# --- Config ---
OUTPUT_W, OUTPUT_H = 1284, 2778
SCREENSHOT_DIR = os.path.expanduser("~/Desktop")
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# Dark gradient background colors
BG_TOP = (20, 20, 35)
BG_BOTTOM = (8, 8, 18)

# Screenshots and their marketing copy
PREVIEWS = [
    {
        "file": "Simulator Screenshot - iPhone 17 Pro - 2026-03-06 at 23.41.12.png",
        "headline": "All Your Notes,",
        "subline": "Beautifully Organized",
        "caption": "Color-coded notes with search and filtering",
        "output": "preview_1_grid.png",
    },
    {
        "file": "Simulator Screenshot - iPhone 17 Pro - 2026-03-06 at 23.41.24.png",
        "headline": "Write in Markdown,",
        "subline": "See It Styled Live",
        "caption": "Bold, italic, headings, lists — all rendered as you type",
        "output": "preview_2_editor.png",
    },
    {
        "file": "Simulator Screenshot - iPhone 17 Pro - 2026-03-06 at 23.41.16.png",
        "headline": "Rich Formatting,",
        "subline": "Zero Complexity",
        "caption": "Markdown syntax with instant visual feedback",
        "output": "preview_3_recipe.png",
    },
    {
        "file": "Simulator Screenshot - iPhone 17 Pro - 2026-03-06 at 23.41.28.png",
        "headline": "6 Premium Colors",
        "subline": "to Match Your Style",
        "caption": "Silver, Space Gray, Gold, Rose Gold, Blue, and Purple",
        "output": "preview_4_colors.png",
    },
]


def make_gradient(w, h, top_color, bottom_color):
    """Create a vertical gradient image."""
    img = Image.new("RGB", (w, h))
    pixels = img.load()
    for y in range(h):
        t = y / h
        r = int(top_color[0] * (1 - t) + bottom_color[0] * t)
        g = int(top_color[1] * (1 - t) + bottom_color[1] * t)
        b = int(top_color[2] * (1 - t) + bottom_color[2] * t)
        for x in range(w):
            pixels[x, y] = (r, g, b)
    return img


def load_font(size, bold=False):
    """Try to load a good system font."""
    if bold:
        candidates = [
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
            "/System/Library/Fonts/SFNS.ttf",
        ]
    else:
        candidates = [
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
            "/System/Library/Fonts/SFNS.ttf",
        ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def draw_centered_text(draw, text, y, font, fill):
    """Draw text centered horizontally on the canvas."""
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    x = (OUTPUT_W - text_w) // 2
    draw.text((x, y), text, fill=fill, font=font)
    return bbox[3] - bbox[1]  # return text height


def round_corners(img, radius):
    """Apply rounded corners to an image."""
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (img.width - 1, img.height - 1)], radius=radius, fill=255)
    img.putalpha(mask)
    return img


def create_preview(config):
    """Create a single App Store preview image."""
    # Create gradient background
    canvas = make_gradient(OUTPUT_W, OUTPUT_H, BG_TOP, BG_BOTTOM).convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    # Load fonts
    font_headline = load_font(88, bold=True)
    font_caption = load_font(40)

    # --- Text area at the top ---
    # Headline (white)
    y = 180
    h = draw_centered_text(draw, config["headline"], y, font_headline, (255, 255, 255, 255))
    y += h + 16

    # Subline (warm gold)
    h = draw_centered_text(draw, config["subline"], y, font_headline, (245, 214, 186, 255))
    text_bottom = y + h

    # --- Load and place screenshot ---
    screenshot_path = os.path.join(SCREENSHOT_DIR, config["file"])
    if not os.path.exists(screenshot_path):
        print(f"  WARNING: {config['file']} not found, skipping")
        return

    screenshot = Image.open(screenshot_path).convert("RGBA")

    # Screenshot placement: below text with padding, leave room for caption
    ss_top = text_bottom + 80
    caption_area = 180
    available_h = OUTPUT_H - ss_top - caption_area

    # Scale to fit width (82% of canvas width) or available height
    target_w = int(OUTPUT_W * 0.82)
    scale_w = target_w / screenshot.width
    scale_h = available_h / screenshot.height
    scale = min(scale_w, scale_h)

    target_w = int(screenshot.width * scale)
    target_h = int(screenshot.height * scale)

    screenshot = screenshot.resize((target_w, target_h), Image.LANCZOS)

    # Round corners
    screenshot = round_corners(screenshot, 48)

    # Center screenshot
    ss_x = (OUTPUT_W - target_w) // 2
    ss_y = ss_top

    # Draw shadow behind screenshot
    shadow_offset = 20
    shadow_blur = 40
    shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_rect = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 90))
    shadow_rect = round_corners(shadow_rect, 48)
    shadow_layer.paste(shadow_rect, (ss_x, ss_y + shadow_offset), shadow_rect)
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=shadow_blur))
    canvas = Image.alpha_composite(canvas, shadow_layer)

    # Paste screenshot
    ss_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ss_layer.paste(screenshot, (ss_x, ss_y), screenshot)
    canvas = Image.alpha_composite(canvas, ss_layer)

    # --- Caption at bottom ---
    draw = ImageDraw.Draw(canvas)
    caption_y = OUTPUT_H - 120
    draw_centered_text(draw, config["caption"], caption_y, font_caption, (160, 160, 175, 255))

    # --- Thin decorative line above caption ---
    line_y = caption_y - 30
    line_w = 120
    line_x = (OUTPUT_W - line_w) // 2
    draw.line([(line_x, line_y), (line_x + line_w, line_y)], fill=(245, 214, 186, 60), width=2)

    # --- Save ---
    output_path = os.path.join(OUTPUT_DIR, config["output"])
    canvas.convert("RGB").save(output_path, "PNG", quality=95)
    print(f"  Created: {config['output']} ({OUTPUT_W}x{OUTPUT_H})")


def main():
    print("Generating App Store previews...")
    for config in PREVIEWS:
        print(f"  Processing: {config['headline']} {config['subline']}")
        create_preview(config)
    print(f"\nAll previews saved to: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
