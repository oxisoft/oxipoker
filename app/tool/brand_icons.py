#!/usr/bin/env python3
"""Oxi Poker app icon: writes the SVG masters and renders every platform icon.

The chip below is the one master drawing (1024 x 1024 units, colours from
lib/ui/appearance.dart). Run from app/: python3 tool/brand_icons.py
Needs ImageMagick 7 (magick) with the rsvg delegate.
"""
import pathlib
import subprocess
import tempfile

APP = pathlib.Path(__file__).resolve().parent.parent
BRAND = APP / "assets" / "brand"
BG = "#06070C"

CHIP = """<circle cx="512" cy="512" r="400" fill="#2F6BFF"/>
<circle cx="512" cy="512" r="360" fill="none" stroke="#DDE1EC" stroke-width="80" stroke-dasharray="110 172.74" stroke-dashoffset="55"/>
<circle cx="512" cy="512" r="292" fill="#0D0F18" stroke="#06070C" stroke-width="14"/>
<path transform="translate(312 304) scale(4)" fill="#FF2BD6" d="M50 5 C50 5 10 40 10 62 C10 78 26 86 40 78 C44 76 47 72 48 70 C47 80 42 90 34 95 L66 95 C58 90 53 80 52 70 C53 72 56 76 60 78 C74 86 90 78 90 62 C90 40 50 5 50 5 Z"/>"""


def svg(background: str, scale: float) -> str:
    off = 512 * (1 - scale)
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">\n'
        f"{background}"
        f'<g transform="translate({off:g} {off:g}) scale({scale:g})">\n{CHIP}\n</g>\n</svg>\n'
    )


MASTERS = {
    # Rounded square: web, favicon, desktop, F-Droid.
    "icon.svg": svg(f'<rect width="1024" height="1024" rx="224" fill="{BG}"/>\n', 0.94),
    # Full bleed, chip inside the 80% safe circle: web maskable icons.
    "icon-maskable.svg": svg(f'<rect width="1024" height="1024" fill="{BG}"/>\n', 0.76),
    # Transparent, chip inside the 66/108 safe zone: Android adaptive foreground.
    "icon-foreground.svg": svg("", 0.74),
    # Full bleed square for Android legacy icons (launchers round or square them).
    "icon-square.svg": svg(f'<rect width="1024" height="1024" fill="{BG}"/>\n', 0.9),
}


def render(master: str, size: int, out: pathlib.Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["magick", "-background", "none", "-density", "384", str(BRAND / master),
         "-resize", f"{size}x{size}", "-strip", f"PNG32:{out}"],
        check=True,
    )


def main() -> None:
    BRAND.mkdir(parents=True, exist_ok=True)
    for name, text in MASTERS.items():
        (BRAND / name).write_text(text)

    web = APP / "web"
    render("icon.svg", 32, web / "favicon.png")
    render("icon.svg", 192, web / "icons" / "Icon-192.png")
    render("icon.svg", 512, web / "icons" / "Icon-512.png")
    render("icon-maskable.svg", 192, web / "icons" / "Icon-maskable-192.png")
    render("icon-maskable.svg", 512, web / "icons" / "Icon-maskable-512.png")

    res = APP / "android" / "app" / "src" / "main" / "res"
    for density, dp48 in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        render("icon-square.svg", dp48, res / f"mipmap-{density}" / "ic_launcher.png")
        render("icon-foreground.svg", dp48 * 108 // 48, res / f"mipmap-{density}" / "ic_launcher_foreground.png")

    mac = APP / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for size in (16, 32, 64, 128, 256, 512, 1024):
        render("icon.svg", size, mac / f"app_icon_{size}.png")

    with tempfile.TemporaryDirectory() as tmp:
        parts = []
        for size in (16, 24, 32, 48, 64, 128, 256):
            p = pathlib.Path(tmp) / f"{size}.png"
            render("icon.svg", size, p)
            parts.append(str(p))
        subprocess.run(["magick", *parts, str(APP / "windows" / "runner" / "resources" / "app_icon.ico")], check=True)

    render("icon.svg", 512, APP / "linux" / "runner" / "resources" / "app_icon.png")
    render("icon.svg", 512, BRAND / "icon-512.png")


if __name__ == "__main__":
    main()
