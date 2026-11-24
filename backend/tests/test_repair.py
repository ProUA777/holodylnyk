import asyncio

from app.engine.engine import Engine
from app.engine.providers import MockProvider
from app.engine.store import Store
from app.profiles.repair import RepairParams, RepairProfile
from tests.test_api import client, isolated_db, jpeg_bytes  # noqa: F401  (фікстури)


def _engine(tmp_path, provider):
    eng = Engine(provider, Store(str(tmp_path / "s.sqlite3")), max_upload_mb=10, image_max_side=800, max_tokens_detail=100)
    eng.register(RepairProfile())
    return eng


def test_repair_two_steps(tmp_path):
    calls = []

    class Spy(MockProvider):
        async def generate(self, req, mock_output=None):
            calls.append(req)
            return await super().generate(req, mock_output)

    res = asyncio.run(_engine(tmp_path, Spy()).analyze("repair", [jpeg_bytes((300, 300))] * 2,
                                                       RepairParams(language="pl", skill="beginner")))
    scan, fix = calls
    assert scan.mode == "scan" and len(scan.images_jpeg) == 2 and "causes" not in scan.output_schema["properties"]
    assert not fix.images_jpeg and "підтікає вода з-під ручки" in fix.user_text and "новачок" in fix.system and "zł" in fix.system
    assert res.thing == "змішувач для кухні, одноважільний" and res.category.value == "plumbing"
    assert res.causes[0].title == "Зношений картридж"  # від найімовірнішої
    assert len(res.parts) == 2  # дубль інструмента прибрано
    assert res.signs == ["підтікає вода з-під ручки", "вапняний наліт на основі"]


def test_repair_electrical_never_plain_diy(tmp_path):
    class Elec(MockProvider):
        async def generate(self, req, mock_output=None):
            if req.mode == "scan":
                return {"detected": True, "thing": "розетка", "category": "electrical", "signs": ["оплавлений корпус"]}
            return {"detected": True, "thing": "розетка", "safety": "diy", "causes": [{"title": "Поганий контакт"}]}

    res = asyncio.run(_engine(tmp_path, Elec()).analyze("repair", [jpeg_bytes((300, 300))], RepairParams()))
    assert res.safety.value == "careful"


def test_repair_http(client):
    r = client.post("/v1/repair/refine", json={"thing": "пральна машина", "codes": ["E21"], "params": {"skill": "pro"}})
    assert r.status_code == 200 and r.json()["causes"]
    d = {"thing": "змішувач", "cause": "Зношений картридж"}
    r1 = client.post("/v1/repair/detail", json=d)
    assert r1.status_code == 200 and "## Безпека спочатку" in r1.json()["markdown"]
    assert client.post("/v1/repair/detail", json=d).json().get("cached") is True
    r2 = client.post("/v1/repair/action/ask", json={"thing": "змішувач", "question": "Скільки часу займе?"})
    assert r2.status_code == 200 and r2.json()["answer"]
    assert client.post("/v1/repair/refine", json={"thing": "x"}).status_code == 422

    class Nothing(MockProvider):
        async def generate(self, req, mock_output=None):
            return {"detected": False, "message": "Це кіт"}

    client.app.state.engine.provider = Nothing()
    r = client.post("/v1/repair/analyze", files={"image": ("a.jpg", jpeg_bytes((300, 300)), "image/jpeg")})
    assert r.status_code == 422 and r.json()["message"] == "Це кіт"
