"""Generate PharmaLoka platform icons from the checked-in SVG masters."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets/branding/app_icon.svg"
MASKABLE = ROOT / "assets/branding/app_icon_maskable.svg"
RESAMPLING = Image.Resampling.LANCZOS


def find_browser() -> Path:
    candidates = [
        Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
        Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    for name in ("chrome", "msedge", "chromium"):
        resolved = shutil.which(name)
        if resolved:
            return Path(resolved)
    raise RuntimeError("Chrome, Edge, or Chromium is required to render SVG assets")


def render_svg(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    command = [
        str(find_browser()),
        "--headless",
        "--disable-gpu",
        "--hide-scrollbars",
        "--no-first-run",
        "--run-all-compositor-stages-before-draw",
        "--window-size=1024,1024",
        "--force-device-scale-factor=1",
        "--default-background-color=00000000",
        f"--screenshot={destination}",
        source.resolve().as_uri(),
    ]
    subprocess.run(command, check=True, capture_output=True)
    with Image.open(destination) as rendered:
        rendered.convert("RGBA").crop((0, 0, 1024, 1024)).save(destination)


def save_png(source: Image.Image, relative_path: str, size: int) -> None:
    destination = ROOT / relative_path
    destination.parent.mkdir(parents=True, exist_ok=True)
    source.resize((size, size), RESAMPLING).save(destination, optimize=True)


def build_review_sheet(icon: Image.Image) -> None:
    width, height = 1600, 900
    sheet = Image.new("RGB", (width, height), "#F4F7FB")
    draw = ImageDraw.Draw(sheet)
    title_font = ImageFont.truetype("arialbd.ttf", 48)
    body_font = ImageFont.truetype("arial.ttf", 24)
    small_font = ImageFont.truetype("arial.ttf", 18)
    draw.text((72, 54), "PharmaLoka - Loka Bloom", fill="#081A33", font=title_font)
    draw.text((74, 118), "Final vector export proof - Option A", fill="#46627F", font=body_font)

    large = icon.resize((560, 560), RESAMPLING)
    sheet.paste(large, (72, 210), large)
    draw.text((278, 790), "1024 master", fill="#46627F", font=small_font)

    panels = [("Light surface", "#FFFFFF"), ("Dark surface", "#08111F")]
    for column, (label, color) in enumerate(panels):
        left = 720 + column * 420
        draw.rounded_rectangle((left, 210, left + 360, 770), 28, fill=color)
        label_color = "#081A33" if column == 0 else "#E6F6FF"
        draw.text((left + 32, 242), label, fill=label_color, font=body_font)
        y = 330
        for size in (128, 64, 32, 16):
            rendered = icon.resize((size, size), RESAMPLING)
            sheet.paste(rendered, (left + 42, y), rendered)
            draw.text((left + 204, y + max(0, size // 2 - 12)), f"{size} px", fill=label_color, font=small_font)
            y += max(size, 58) + 30

    output = ROOT / "docs/superpowers/evidence/2026-08-13-pharmaloka-icon-review.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, optimize=True)


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="pharmaloka-brand-") as temporary:
        standard_png = Path(temporary) / "standard.png"
        maskable_png = Path(temporary) / "maskable.png"
        render_svg(MASTER, standard_png)
        render_svg(MASKABLE, maskable_png)
        with Image.open(standard_png) as standard_file, Image.open(maskable_png) as maskable_file:
            standard = standard_file.convert("RGBA")
            maskable = maskable_file.convert("RGBA")

            for path, size in {
                "assets/branding/app_icon.png": 1024,
                "assets/branding/app_icon_source.png": 1024,
                "web/favicon.png": 32,
                "web/icons/Icon-192.png": 192,
                "web/icons/Icon-512.png": 512,
                "docs_site/assets/images/favicon.png": 32,
                "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": 48,
                "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": 72,
                "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": 96,
                "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": 144,
                "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": 192,
            }.items():
                save_png(standard, path, size)
            save_png(maskable, "assets/branding/play_store_icon.png", 512)
            save_png(maskable, "web/icons/Icon-maskable-192.png", 192)
            save_png(maskable, "web/icons/Icon-maskable-512.png", 512)

            ico = ROOT / "windows/runner/resources/app_icon.ico"
            standard.save(ico, sizes=[(size, size) for size in (16, 24, 32, 48, 64, 128, 256)])
            build_review_sheet(standard)

    shutil.copy2(MASTER, ROOT / "docs_site/assets/images/pharmaloka-icon.svg")
    print("Generated PharmaLoka brand assets.")


if __name__ == "__main__":
    main()
