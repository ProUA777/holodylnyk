"""SQLite-сховище: денні ліміти й кеш детальних рецептів. Без зовнішніх сервісів."""
from __future__ import annotations

import sqlite3
import threading
import time
from datetime import datetime, timezone
from pathlib import Path

from .errors import EngineError


class DailyLimitError(EngineError):
    status_code = 429
    code = "daily_limit"


class Store:
    def __init__(self, path: str):
        if path != ":memory:":
            Path(path).parent.mkdir(parents=True, exist_ok=True)
        self._db = sqlite3.connect(path, check_same_thread=False, isolation_level=None)
        self._lock = threading.Lock()
        self._cleaned_day = ""
        with self._lock:
            self._db.execute("PRAGMA journal_mode=WAL")
            self._db.execute("""CREATE TABLE IF NOT EXISTS quota(
                day TEXT, key TEXT, kind TEXT, count INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY(day, key, kind))""")
            self._db.execute("""CREATE TABLE IF NOT EXISTS detail_cache(
                key TEXT PRIMARY KEY, profile TEXT, markdown TEXT, created REAL)""")

    @staticmethod
    def _today() -> str:
        return datetime.now(timezone.utc).strftime("%Y-%m-%d")

    # --- ліміти ---------------------------------------------------------------
    def take(self, keys: list[tuple[str, int]], kind: str) -> int:
        """Списує 1 запит з кожного ключа (пристрій, IP). Повертає залишок для першого ключа.

        keys: [(ключ, ліміт)], ліміт 0 = без обмеження.
        """
        day = self._today()
        if day != self._cleaned_day:  # раз на добу чистимо старі лічильники (обіцяно в /privacy: до 3 днів)
            self.cleanup()
            self._cleaned_day = day
        with self._lock:
            counts = []
            for key, limit in keys:
                row = self._db.execute("SELECT count FROM quota WHERE day=? AND key=? AND kind=?",
                                       (day, key, kind)).fetchone()
                used = row[0] if row else 0
                if limit and used >= limit:
                    raise DailyLimitError(LIMIT_MESSAGES.get(kind, LIMIT_MESSAGES["refine"]).format(limit=keys[0][1]))
                counts.append(used)
            for key, _ in keys:
                self._db.execute("""INSERT INTO quota(day, key, kind, count) VALUES(?,?,?,1)
                    ON CONFLICT(day, key, kind) DO UPDATE SET count = count + 1""", (day, key, kind))
            first_limit = keys[0][1]
            return max(first_limit - counts[0] - 1, 0) if first_limit else -1

    def refund(self, keys: list[str], kind: str) -> None:
        """Повертає запит, якщо AI не відповів — користувач не платить за наші помилки."""
        day = self._today()
        with self._lock:
            for key in keys:
                self._db.execute("UPDATE quota SET count = MAX(count - 1, 0) WHERE day=? AND key=? AND kind=?",
                                 (day, key, kind))

    def cleanup(self, keep_days: int = 3) -> None:
        cutoff = datetime.fromtimestamp(time.time() - keep_days * 86400, timezone.utc).strftime("%Y-%m-%d")
        with self._lock:
            self._db.execute("DELETE FROM quota WHERE day < ?", (cutoff,))

    # --- кеш детальних рецептів -------------------------------------------------
    def get_detail(self, key: str) -> str | None:
        with self._lock:
            row = self._db.execute("SELECT markdown FROM detail_cache WHERE key=?", (key,)).fetchone()
        return row[0] if row else None

    def put_detail(self, key: str, profile: str, markdown: str) -> None:
        with self._lock:
            self._db.execute("INSERT OR REPLACE INTO detail_cache(key, profile, markdown, created) VALUES(?,?,?,?)",
                             (key, profile, markdown, time.time()))


LIMIT_MESSAGES = {
    "analyze": "На сьогодні вичерпано {limit} фото. Спробуй завтра або впиши продукти вручну.",
    "refine": "На сьогодні вичерпано {limit} підборів рецептів. Спробуй завтра.",
    "detail": "На сьогодні вичерпано {limit} детальних рецептів. Збережені рецепти доступні як і раніше.",
    "plan": "На сьогодні вичерпано {limit} меню на тиждень. Спробуй завтра.",
}
