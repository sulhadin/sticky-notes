#!/usr/bin/env python3
"""Generate premium App Store preview images for Sticky Markdown (Mac)."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

# --- Config ---
OUTPUT_W, OUTPUT_H = 2880, 1800
SCREENSHOT_DIR = os.path.expanduser("~/Desktop")
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

BG_TOP = (20, 20, 35)
BG_BOTTOM = (8, 8, 18)

PREVIEWS = [
    {
        "file": "Screenshot 2026-03-06 at 22.19.05.png",
        "headline": "Sticky Notes That Live on Your Desktop",
        "subline": "Write in Markdown, see it styled live",
        "output": "mac_preview_1_desktop.png",
    },
    {
        "file": "Screenshot 2026-03-06 at 22.20.58.png",
        "headline": "Notes Manager + Floating Stickies",
        "subline": "Organize and access everything in one place",
        "output": "mac_preview_2_manager.png",
    },
    {
        "file": "Screenshot 2026-03-06 at 22.21.09.png",
        "headline": "All Your Notes, Beautifully Organized",
        "subline": "Color-coded cards with search and filtering",
        "output": "mac_preview_3_grid.png",
    },
    {
        "file": "Screenshot 2026-03-06 at 22.19.27.png",
        "headline": "Quick Access from the Menu Bar",
        "subline": "Create, browse, and manage notes instantly",
        "output": "mac_preview_4_menubar.png",
    },
    {
        "file": "Screenshot 2026-03-06 at 22.19.59.png",
        "headline": "Every Note, One Click Away",
        "subline": "Jump to any note right from the menu bar",
        "output": "mac_preview_5_menubar2.png",
    },
]


def make_gradient(w, h, top_color, bottom_color):
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


def draw_centered_text(draw, text, y, font, fill, canvas_w):
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    x = (canvas_w - text_w) // 2
    draw.text((x, y), text, fill=fill, font=font)
    return bbox[3] - bbox[1]


def round_corners(img, radius):
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (img.width - 1, img.height - 1)], radius=radius, fill=255)
    img.putalpha(mask)
    return img


def create_preview(config):
    canvas = make_gradient(OUTPUT_W, OUTPUT_H, BG_TOP, BG_BOTTOM).convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    font_headline = load_font(80, bold=True)
    font_subline = load_font(48)

    # --- Text at the top ---
    y = 100
    h = draw_centered_text(draw, config["headline"], y, font_headline, (255, 255, 255, 255), OUTPUT_W)
    y += h + 16
    h = draw_centered_text(draw, config["subline"], y, font_subline, (245, 214, 186, 220), OUTPUT_W)
    text_bottom = y + h

    # --- Load screenshot ---
    screenshot_path = os.path.join(SCREENSHOT_DIR, config["file"])
    if not os.path.exists(screenshot_path):
        print(f"  WARNING: {config['file']} not found, skipping")
        return

    screenshot = Image.open(screenshot_path).convert("RGBA")

    # Scale to fit: 90% width, leave room for text
    ss_top = text_bottom + 60
    available_h = OUTPUT_H - ss_top - 60  # 60px bottom padding
    available_w = int(OUTPUT_W * 0.90)

    scale_w = available_w / screenshot.width
    scale_h = available_h / screenshot.height
    scale = min(scale_w, scale_h)

    target_w = int(screenshot.width * scale)
    target_h = int(screenshot.height * scale)

    screenshot = screenshot.resize((target_w, target_h), Image.LANCZOS)
    screenshot = round_corners(screenshot, 28)

    ss_x = (OUTPUT_W - target_w) // 2
    ss_y = ss_top

    # Shadow
    shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_rect = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 80))
    shadow_rect = round_corners(shadow_rect, 28)
    shadow_layer.paste(shadow_rect, (ss_x, ss_y + 16), shadow_rect)
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=30))
    canvas = Image.alpha_composite(canvas, shadow_layer)

    # Screenshot
    ss_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ss_layer.paste(screenshot, (ss_x, ss_y), screenshot)
    canvas = Image.alpha_composite(canvas, ss_layer)

    # Save
    output_path = os.path.join(OUTPUT_DIR, config["output"])
    canvas.convert("RGB").save(output_path, "PNG", quality=95)
    print(f"  Created: {config['output']} ({OUTPUT_W}x{OUTPUT_H})")


def main():
    print("Generating Mac App Store previews...")
    for config in PREVIEWS:
        print(f"  Processing: {config['headline']}")
        create_preview(config)
    print(f"\nAll Mac previews saved to: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
