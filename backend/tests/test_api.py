import io
import os
import tempfile

os.environ.setdefault("DB_PATH", os.path.join(tempfile.mkdtemp(), "limits.db"))

from fastapi.testclient import TestClient  # noqa: E402
from PIL import Image  # noqa: E402

from app.ai import extract_json  # noqa: E402
from app.main import PROFILES, app, limiter  # noqa: E402
from app.limiter import DailyLimiter  # noqa: E402

client = TestClient(app)
HEADERS = {"X-App-Key": "dev-key-bricks", "X-Device-Id": "test-device"}


def _jpeg(size=(3000, 2000)) -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", size, "white").save(buf, format="JPEG")
    return buf.getvalue()


def _post(profile="brick_builder", headers=HEADERS, body=None, lang="uk"):
    return client.post(f"/v1/analyze/{profile}", headers=headers,
                       files={"image": ("a.jpg", body if body is not None else _jpeg(), "image/jpeg")}, data={"lang": lang})


def test_health_lists_profiles():
    assert {"food_label", "brick_builder"} <= set(client.get("/health").json()["profiles"])


def test_privacy_page():
    r = client.get("/privacy")
    assert r.status_code == 200 and "text/html" in r.headers["content-type"]
    assert "Політика конфіденційності" in r.text and "Privacy policy" in r.text and "Polityka prywatności" in r.text


def test_analyze_returns_catalog_matches_only():
    r = _post()
    assert r.status_code == 200
    res = r.json()["result"]
    ids = [m["id"] for m in res["matches"]]
    assert ids[0] == "dragon" and "made-up-id" not in ids and len(ids) <= 6
    assert res["source"] in ("pile", "instructions", "built", "other")


def test_prompt_contains_catalog():
    from app.ai import _catalog_text, catalog_ids
    p = PROFILES["brick_builder"]
    assert "dragon | Dragon" in _catalog_text(p)
    assert len(catalog_ids(p)) >= 100


def test_bad_key():
    assert _post(headers={"X-App-Key": "nope"}).status_code == 401


def test_not_an_image():
    assert _post(body=b"hello").status_code == 400


def test_unknown_profile():
    assert _post(profile="nope").status_code == 404


def test_too_big(monkeypatch):
    from app.config import settings
    monkeypatch.setattr(settings, "max_image_mb", 0)
    assert _post().status_code == 413


def test_daily_limit(monkeypatch):
    from app.config import settings
    monkeypatch.setattr(settings, "daily_limit", 2)
    h = {**HEADERS, "X-Device-Id": "limit-device"}
    codes = [_post(headers=h).status_code for _ in range(3)]
    assert codes == [200, 200, 429]
    assert limiter.used("limit-device") == 2


def test_limiter_persists_between_instances(tmp_path):
    path = str(tmp_path / "l.db")
    DailyLimiter(path).add("dev")
    DailyLimiter(path).add("dev")
    assert DailyLimiter(path).used("dev") == 2


def test_failed_scan_does_not_count(monkeypatch):
    import app.main as main
    from app.ai import AIError

    async def boom(*a, **k):
        raise AIError("down")

    monkeypatch.setattr(main, "analyze", boom)
    h = {**HEADERS, "X-Device-Id": "fail-device"}
    assert _post(headers=h).status_code == 502
    assert limiter.used("fail-device") == 0


def test_profiles_are_valid():
    for p in PROFILES.values():
        assert {"id", "title", "system", "instruction"} <= p.keys()
        assert "{lang}" in p["instruction"]
        assert set(p["title"]) == {"uk", "pl", "en"}


def test_extract_json_strips_fences():
    assert extract_json('```json\n{"a": 1}\n```') == {"a": 1}
    assert extract_json('Here you go: {"a": [1, 2]} hope it helps') == {"a": [1, 2]}


def test_report_ai_answer():
    from app.main import reports
    before = reports.count()
    r = client.post("/v1/report", headers=HEADERS, json={"profile": "brick_builder", "lang": "uk", "reason": "offensive", "content": "Idea: X"})
    assert r.status_code == 200 and reports.count() == before + 1
    assert client.post("/v1/report", headers={"X-App-Key": "bad"}, json={"profile": "p", "reason": "x"}).status_code == 401
