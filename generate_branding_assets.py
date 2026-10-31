import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_netpulse_icon(size=512):
    # High-res canvas
    scale = 2
    actual_size = size * scale
    img = Image.new("RGBA", (actual_size, actual_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Base rounded shield / squircle background
    padding = int(actual_size * 0.06)
    radius = int(actual_size * 0.22)
    box = [padding, padding, actual_size - padding, actual_size - padding]

    # Gradient background: Deep navy (#0B101E) to Midnight Blue (#0F1B38)
    bg_img = Image.new("RGBA", (actual_size, actual_size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg_img)
    bg_draw.rounded_rectangle(box, radius=radius, fill=(11, 16, 30, 255))
    
    # Outer glow / border: Electric Cyan (#00E5FF) to Neon Purple (#7C4DFF)
    border_width = int(actual_size * 0.02)
    bg_draw.rounded_rectangle(box, radius=radius, outline=(0, 229, 255, 180), width=border_width)

    img = Image.alpha_composite(img, bg_img)
    draw = ImageDraw.Draw(img)

    # 2. Glowing Pulse Wave (representing "NetPulse")
    center_y = int(actual_size * 0.52)
    points = [
        (padding + int(actual_size * 0.12), center_y),
        (padding + int(actual_size * 0.24), center_y),
        (padding + int(actual_size * 0.32), center_y - int(actual_size * 0.12)),
        (padding + int(actual_size * 0.40), center_y + int(actual_size * 0.14)),
        (padding + int(actual_size * 0.48), center_y - int(actual_size * 0.20)),
        (padding + int(actual_size * 0.56), center_y + int(actual_size * 0.16)),
        (padding + int(actual_size * 0.64), center_y - int(actual_size * 0.08)),
        (padding + int(actual_size * 0.72), center_y),
        (padding + int(actual_size * 0.82), center_y),
    ]

    # Glow layer for pulse wave
    glow_layer = Image.new("RGBA", (actual_size, actual_size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    wave_width = int(actual_size * 0.035)
    for i in range(len(points) - 1):
        glow_draw.line([points[i], points[i+1]], fill=(124, 77, 255, 120), width=wave_width + int(actual_size * 0.03))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(int(actual_size * 0.02)))
    img = Image.alpha_composite(img, glow_layer)
    draw = ImageDraw.Draw(img)

    # Crisp pulse wave line
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=(0, 229, 255, 255), width=wave_width)

    # 3. Download Arrow / Speed Chevron
    arrow_center_x = actual_size // 2
    arrow_top_y = int(actual_size * 0.24)
    arrow_shaft_bottom_y = int(actual_size * 0.58)
    arrow_tip_y = int(actual_size * 0.76)
    arrow_wing_span = int(actual_size * 0.22)
    arrow_width = int(actual_size * 0.055)

    # Arrow glow
    arrow_glow = Image.new("RGBA", (actual_size, actual_size), (0, 0, 0, 0))
    arrow_glow_draw = ImageDraw.Draw(arrow_glow)
    
    # Downward chevron
    chevron_points = [
        (arrow_center_x - arrow_wing_span, int(actual_size * 0.54)),
        (arrow_center_x, arrow_tip_y),
        (arrow_center_x + arrow_wing_span, int(actual_size * 0.54)),
        (arrow_center_x + arrow_wing_span - arrow_width, int(actual_size * 0.50)),
        (arrow_center_x, arrow_tip_y - arrow_width),
        (arrow_center_x - arrow_wing_span + arrow_width, int(actual_size * 0.50)),
    ]
    arrow_glow_draw.polygon(chevron_points, fill=(0, 229, 255, 140))
    arrow_glow = arrow_glow.filter(ImageFilter.GaussianBlur(int(actual_size * 0.015)))
    img = Image.alpha_composite(img, arrow_glow)
    draw = ImageDraw.Draw(img)

    # Downward chevron sharp
    draw.polygon(chevron_points, fill=(255, 255, 255, 240), outline=(0, 229, 255, 255))

    # Center vertical high-speed beam
    beam_width = int(actual_size * 0.04)
    beam_top = arrow_top_y
    beam_bottom = arrow_tip_y - int(actual_size * 0.08)
    draw.rounded_rectangle([arrow_center_x - beam_width // 2, beam_top, arrow_center_x + beam_width // 2, beam_bottom], 
                           radius=beam_width // 2, fill=(255, 255, 255, 255))

    # Center speed dot
    dot_r = int(actual_size * 0.035)
    dot_y = int(actual_size * 0.81)
    draw.ellipse([arrow_center_x - dot_r, dot_y - dot_r, arrow_center_x + dot_r, dot_y + dot_r], fill=(0, 229, 255, 255))

    # Resize to target
    return img.resize((size, size), Image.Resampling.LANCZOS)

def main():
    os.makedirs("assets/icons", exist_ok=True)
    os.makedirs("windows/runner/resources", exist_ok=True)
    os.makedirs("browser_extension/chrome/icons", exist_ok=True)
    os.makedirs("browser_extension/firefox/icons", exist_ok=True)

    # 1. 512x512 logo
    icon_512 = create_netpulse_icon(512)
    icon_512.save("assets/icons/logo.png", format="PNG")
    icon_512.save("assets/icons/splash_logo.png", format="PNG")
    print("Created assets/icons/logo.png (512x512)")

    # 2. Windows app_icon.ico and tray_icon.ico
    sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    icon_imgs = [create_netpulse_icon(s[0]) for s in sizes]
    
    icon_imgs[0].save("windows/runner/resources/app_icon.ico", format="ICO", sizes=sizes)
    icon_imgs[0].save("assets/icons/tray_icon.ico", format="ICO", sizes=sizes)
    print("Created windows/runner/resources/app_icon.ico & assets/icons/tray_icon.ico")

    # 3. Extension icons
    for sz in [16, 32, 48, 128]:
        ico = create_netpulse_icon(sz)
        ico.save(f"browser_extension/chrome/icons/icon{sz}.png", format="PNG")
        ico.save(f"browser_extension/firefox/icons/icon{sz}.png", format="PNG")
        ico.save(f"assets/icons/icon{sz}.png", format="PNG")
    print("Created browser extension icons (16, 32, 48, 128)")

if __name__ == "__main__":
    main()

