"""Підготовка фото: перевірка, поворот за EXIF, зменшення, JPEG без метаданих."""
import io

from PIL import Image, ImageOps, UnidentifiedImageError

from .errors import BadImageError, ImageTooLargeError

Image.MAX_IMAGE_PIXELS = 60_000_000  # захист від «бомб» розпакування


def prepare_image(raw: bytes, max_upload_mb: float, max_side: int) -> bytes:
    if not raw:
        raise BadImageError("Порожній файл")
    if len(raw) > max_upload_mb * 1024 * 1024:
        raise ImageTooLargeError(f"Фото більше за {max_upload_mb:g} МБ")
    try:
        img = Image.open(io.BytesIO(raw))
        img.load()
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as e:
        raise BadImageError("Не вдалося прочитати фото") from e

    img = ImageOps.exif_transpose(img)  # телефони часто пишуть поворот лише в EXIF
    if img.mode not in ("RGB", "L"):
        img = img.convert("RGB")
    img.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)

    out = io.BytesIO()
    img.save(out, format="JPEG", quality=85, optimize=True)  # EXIF (і GPS) не зберігаємо
    return out.getvalue()
