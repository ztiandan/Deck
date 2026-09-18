import os
import subprocess
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

PADDING = 100
RADIUS = 185

# 1. 浅色质感底座 (Light Ceramic Arctic White Gradient)
gradient = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
g_draw = ImageDraw.Draw(gradient)

# 优雅浅色冷白至丝滑浅银渐变: #FFFFFF -> #E9EEF4
for y in range(PADDING, SIZE - PADDING):
    progress = (y - PADDING) / (SIZE - 2 * PADDING)
    r = int(255 - (255 - 233) * progress)
    g = int(255 - (255 - 238) * progress)
    b = int(255 - (255 - 244) * progress)
    g_draw.line([(PADDING, y), (SIZE - PADDING, y)], fill=(r, g, b, 255))

mask = Image.new("L", (SIZE, SIZE), 0)
m_draw = ImageDraw.Draw(mask)
m_draw.rounded_rectangle([PADDING, PADDING, SIZE - PADDING, SIZE - PADDING], radius=RADIUS, fill=255)

# 柔和漫反射环境阴影
shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
s_draw = ImageDraw.Draw(shadow)
s_draw.rounded_rectangle([PADDING, PADDING + 16, SIZE - PADDING, SIZE - PADDING + 16], radius=RADIUS, fill=(40, 50, 70, 75))
shadow = shadow.filter(ImageFilter.GaussianBlur(32))

img.alpha_composite(shadow)
img.paste(gradient, (0, 0), mask)

# 2. 浅色金属微边框与高光
border = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
b_draw = ImageDraw.Draw(border)
b_draw.rounded_rectangle([PADDING, PADDING, SIZE - PADDING, SIZE - PADDING], radius=RADIUS, outline=(210, 218, 230, 180), width=3)
# 顶部纯净白光微弧
b_draw.arc([PADDING + 3, PADDING + 3, SIZE - PADDING - 3, PADDING + RADIUS * 2], start=190, end=350, fill=(255, 255, 255, 230), width=3)
img.alpha_composite(border)

# 3. 绘制浅色背景上高反差现代几何「Deck 专属 D 符号」
glyph_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gl_draw = ImageDraw.Draw(glyph_layer)

cx, cy = SIZE // 2, SIZE // 2

BAR_W = 68
BAR_H = 430
left_x = cx - 140
R = 24

# 左垂直立柱 (深邃钛黑/钴灰渐变立柱 #181C26)
top_y = cy - BAR_H // 2
bot_y = cy + BAR_H // 2
gl_draw.rounded_rectangle([left_x, top_y, left_x + BAR_W, bot_y], radius=R, fill=(24, 28, 38, 255))

# 右侧半环（极速流光天青与电光蓝）: 外径 430
arc_box_outer = [left_x - 30, top_y, left_x + BAR_H - 10, bot_y]
gl_draw.arc(arc_box_outer, start=270, end=90, fill=(0, 140, 255, 255), width=BAR_W)

# 浅色底座上的微弱柔光
glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gw_draw = ImageDraw.Draw(glow)
gw_draw.rounded_rectangle([left_x - 10, top_y - 10, left_x + BAR_H, bot_y + 10], radius=R+10, fill=(0, 140, 255, 30))
glow = glow.filter(ImageFilter.GaussianBlur(24))

img.alpha_composite(glow)
img.alpha_composite(glyph_layer)

# 4. 生成多分辨率规格并打包为 AppIcon.icns 与 AppIcon.png
ICONSET_DIR = "AppIcon.iconset"
os.makedirs(ICONSET_DIR, exist_ok=True)

sizes = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

for base_size, scale in sizes:
    actual_size = base_size * scale
    suffix = f"@{scale}x" if scale > 1 else ""
    filename = f"{ICONSET_DIR}/icon_{base_size}x{base_size}{suffix}.png"
    resized = img.resize((actual_size, actual_size), Image.Resampling.LANCZOS)
    resized.save(filename, "PNG")

os.makedirs("Resources", exist_ok=True)
img.resize((512, 512), Image.Resampling.LANCZOS).save("Resources/AppIcon.png", "PNG")
subprocess.run(["iconutil", "-c", "icns", ICONSET_DIR, "-o", "Resources/AppIcon.icns"], check=True)
subprocess.run(["rm", "-rf", ICONSET_DIR], check=True)
print("==> Successfully generated modern light-themed Deck AppIcon.icns and AppIcon.png!")
