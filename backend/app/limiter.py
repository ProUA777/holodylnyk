"""Daily scan limit per device, stored in SQLite so it survives restarts."""
import sqlite3
import threading
import time
from pathlib import Path


class DailyLimiter:
    def __init__(self, path: str):
        Path(path).parent.mkdir(parents=True, exist_ok=True) if path != ":memory:" else None
        self._db = sqlite3.connect(path, check_same_thread=False)
        self._lock = threading.Lock()
        with self._lock:
            self._db.execute("CREATE TABLE IF NOT EXISTS hits (client TEXT, day TEXT, n INTEGER, PRIMARY KEY (client, day))")
            self._db.commit()

    @staticmethod
    def _day() -> str:
        return time.strftime("%Y-%m-%d", time.gmtime())

    def used(self, client: str) -> int:
        with self._lock:
            row = self._db.execute("SELECT n FROM hits WHERE client=? AND day=?", (client, self._day())).fetchone()
        return row[0] if row else 0

    def add(self, client: str) -> int:
        day = self._day()
        with self._lock:
            self._db.execute(
                "INSERT INTO hits (client, day, n) VALUES (?, ?, 1) ON CONFLICT(client, day) DO UPDATE SET n = n + 1",
                (client, day),
            )
            # keep the table small: forget anything older than 3 days
            self._db.execute("DELETE FROM hits WHERE day < date(?, '-3 day')", (day,))
            self._db.commit()
            return self._db.execute("SELECT n FROM hits WHERE client=? AND day=?", (client, day)).fetchone()[0]


class ReportStore:
    """User reports about AI answers (Google Play AI-generated content policy). No photos are stored."""

    def __init__(self, db: DailyLimiter):
        self._db, self._lock = db._db, db._lock
        with self._lock:
            self._db.execute("CREATE TABLE IF NOT EXISTS reports (ts INTEGER, profile TEXT, lang TEXT, reason TEXT, content TEXT)")
            self._db.commit()

    def add(self, profile: str, lang: str, reason: str, content: str) -> None:
        with self._lock:
            self._db.execute("INSERT INTO reports VALUES (?, ?, ?, ?, ?)", (int(time.time()), profile, lang, reason, content))
            self._db.commit()

    def count(self) -> int:
        with self._lock:
            return self._db.execute("SELECT COUNT(*) FROM reports").fetchone()[0]
