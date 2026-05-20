import os
from PIL import Image

INPUT_FILE = r"D:\flutter\pure_live\assets\icons\icon.png"

TV_SIZES = {
    "drawable-mdpi": (160, 90),
    "drawable-hdpi": (240, 135),
    "drawable-xhdpi": (320, 180),
    "drawable-xxhdpi": (480, 270),
    "drawable-xxxhdpi": (640, 360),
}


# 🎨 背景颜色（可以改成品牌色）
BACKGROUND_COLOR = (20, 20, 20)  # 深灰

# 📦 logo 占画面比例（核心）
LOGO_SCALE = 0.5   # 不要超过 60%，否则会像贴图


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")


def create_banner(img, size):
    w, h = size

    # 1️⃣ 创建背景（不会变形的关键）
    canvas = Image.new("RGB", (w, h), BACKGROUND_COLOR)

    # 2️⃣ 计算 logo 最大尺寸（关键：不拉伸）
    max_logo_w = int(w * LOGO_SCALE)
    max_logo_h = int(h * LOGO_SCALE)

    logo = img.convert("RGBA").copy()
    logo.thumbnail((max_logo_w, max_logo_h), Image.LANCZOS)

    # 3️⃣ 居中
    x = (w - logo.width) // 2
    y = (h - logo.height) // 2

    # 4️⃣ 正确 alpha 粘贴（防毛边）
    canvas.paste(logo, (x, y), logo)

    return canvas


def main():
    img = Image.open(INPUT_FILE)

    print("\n📺 生成 TV Banner（背景模式）...")

    for folder, size in TV_SIZES.items():
        banner = create_banner(img, size)

        path = f"{folder}/ic_launcher_foreground.png"
        save(banner, path)

        print(f"✔ {path} ({size[0]}x{size[1]})")

    print("\n🎉 完成（无拉伸版本）")


if __name__ == "__main__":
    main()