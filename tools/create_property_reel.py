#!/usr/bin/env python3
"""توليد رييل سينمائي من صور العقارات (Ken Burns + تنقلات ناعمة).

يُدمج الصور في فيديو واحد بتقريب بطيء (Ken Burns) وانتقالات fade سلسة،
مع دعم اختياري لتأثير صوتي لكل صورة.
"""
from __future__ import annotations

import os
from pathlib import Path

import imageio_ffmpeg

IMAGE_MS = 3000      # مدة عرض كل صورة بالمللي ثانية
FADE_MS = 500        # مدة الانتقال
W, H, FPS = 1280, 720, 24


def _ffmpeg() -> str:
    return imageio_ffmpeg.get_ffmpeg_exe()


def create_property_reel(
    image_paths: list[str],
    audio_effects_paths: list[str] | None = None,
    output_filename: str = "assets/videos/property_reel.mp4",
) -> str:
    """دالة لدمج صور العقارات مع تأثيرات صوتية مخصصة لكل صورة."""
    audio_effects_paths = audio_effects_paths or []
    images = [p for p in image_paths if os.path.exists(p)]
    if not images:
        raise FileNotFoundError("لا توجد صور للإدخال.")

    n = len(images)
    dur = IMAGE_MS / 1000.0
    fade = FADE_MS / 1000.0
    frames = int(dur * FPS)

    parts: list[str] = []
    for i, img in enumerate(images):
        # Ken Burns: تكبير/تصغير بطيء من مركز الصورة
        if i % 2 == 0:
            z = "1+0.15*on/{0}".format(frames)
        else:
            z = "1.18-0.15*on/{0}".format(frames)
        parts.append(
            "[{0}:v]scale={1}:{2}:force_original_aspect_ratio=increase,"
            "crop={1}:{2},setsar=1,zoompan=z='{3}':d={4}:x='iw/2-(iw/zoom/2)':"
            "y='ih/2-(ih/zoom/2)':s={1}x{2}:fps={5}[v{0}]".format(
                i, W, H, z, frames, FPS
            )
        )

    # تنقلات fade ناعمة بين المقاطع
    prev = "v0"
    for i in range(1, n):
        offset = i * (dur - fade)
        out = "x{}".format(i)
        parts.append(
            "[{0}][v{1}]xfade=transition=fade:duration={2}:offset={3:.3f}[{4}]".format(
                prev, i, fade, offset, out
            )
        )
        prev = out

    graph = ";".join(parts)
    cmd = [
        _ffmpeg(), "-y",
    ]
    for img in images:
        cmd += ["-i", img]
    cmd += [
        "-filter_complex", graph,
        "-map", "[{}]".format(prev),
        "-c:v", "libx264", "-crf", "26", "-preset", "medium",
        "-pix_fmt", "yuv420p", "-movflags", "+faststart",
    ]

    # دمج الملفات الصوتية (إن وُجدت) بترتيبها في سياق الفيديو
    audio_ok = [p for p in audio_effects_paths if os.path.exists(p)]
    if audio_ok:
        cmd += [
            "-i", audio_ok[0],
            "-c:a", "aac", "-shortest",
        ]
    cmd.append(output_filename)

    Path(output_filename).parent.mkdir(parents=True, exist_ok=True)
    import subprocess
    subprocess.run(cmd, check=True)
    print(f"تم تصدير الفيديو بنجاح: {output_filename}")
    return output_filename


if __name__ == "__main__":
    images = sorted(str(p) for p in Path("assets/images").glob("*.jpg"))
    sounds = []
    create_property_reel(images, sounds)
