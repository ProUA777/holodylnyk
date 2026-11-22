import asyncio

from app.engine.engine import Engine
from app.engine.providers import MockProvider
from app.engine.store import Store
from app.profiles.outfits import OutfitParams, OutfitsProfile
from tests.test_api import client, isolated_db, jpeg_bytes  # noqa: F401  (фікстури)


def _engine(tmp_path, provider):
    eng = Engine(provider, Store(str(tmp_path / "s.sqlite3")), max_upload_mb=10, image_max_side=800, max_tokens_detail=100)
    eng.register(OutfitsProfile())
    return eng


def test_outfits_two_steps(tmp_path):
    calls = []

    class Spy(MockProvider):
        async def generate(self, req, mock_output=None):
            calls.append(req)
            return await super().generate(req, mock_output)

    res = asyncio.run(_engine(tmp_path, Spy()).analyze(
        "outfits", [jpeg_bytes((300, 300))], OutfitParams(occasion="date", weather="rain", style_for="women")))
    scan, looks = calls
    assert scan.mode == "scan" and scan.images_jpeg and "outfits" not in scan.output_schema["properties"]
    assert "фігуру" in scan.system  # не оцінює тіло людини
    assert not looks.images_jpeg and "побачення" in looks.system and "дощ" in looks.system and "жіночі" in looks.system
    assert "бежевий тренч" in looks.user_text and "щось у пакеті" not in looks.user_text and "verdict=null" in looks.user_text
    assert [i.name for i in res.items][-1] == "білі шкіряні кеди" and len(res.items) == 4
    assert res.outfits[0].items and res.palette == ["#F5F5F2", "#1F2A44", "#C8B08C"]


def test_outfits_worn_asks_verdict(tmp_path):
    calls = []

    class Worn(MockProvider):
        async def generate(self, req, mock_output=None):
            calls.append(req)
            if req.mode == "scan":
                return {"clothes_detected": True, "photo_kind": "worn",
                        "items": [{"name": "червона сукня", "kind": "dress", "color": "червоний", "hex": "#zzzzzz"}]}
            return {"clothes_detected": True, "outfits": [{"title": "Вечір", "items": ["червона сукня"]}],
                    "verdict": {"score": 8, "good": ["колір"], "change": ["туфлі"]}}

    res = asyncio.run(_engine(tmp_path, Worn()).analyze("outfits", [jpeg_bytes((300, 300))], OutfitParams()))
    assert "verdict — score" in calls[1].user_text
    assert res.photo_kind.value == "worn" and res.verdict.score == 8 and res.items[0].hex is None


def test_outfits_http(client):
    r = client.post("/v1/outfits/refine", json={
        "items": [{"name": "чорна футболка", "kind": "top"}, {"name": "сірі джинси", "kind": "bottom"}],
        "exclude_titles": ["Класичний кежуал"], "params": {"weather": "cold", "language": "pl"}})
    assert r.status_code == 200 and r.json()["outfits"]
    assert client.post("/v1/outfits/refine", json={"items": []}).status_code == 422
    r = client.post("/v1/outfits/action/ask", json={"question": "Чи пасує тренч до джинсів?"})
    assert r.status_code == 200 and r.json()["answer"]

    class NoClothes(MockProvider):
        async def generate(self, req, mock_output=None):
            return {"clothes_detected": False, "message": "Це суп"}

    client.app.state.engine.provider = NoClothes()
    r = client.post("/v1/outfits/analyze", files={"image": ("a.jpg", jpeg_bytes((300, 300)), "image/jpeg")})
    assert r.status_code == 422 and r.json()["message"] == "Це суп"
