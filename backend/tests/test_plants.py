import asyncio
import json

from app.engine.engine import Engine
from app.engine.providers import MockProvider
from app.engine.store import Store
from app.profiles.plants import PlantParams, PlantsProfile
from tests.test_api import client, isolated_db, jpeg_bytes  # noqa: F401  (фікстури)


def _engine(tmp_path, provider):
    eng = Engine(provider, Store(str(tmp_path / "s.sqlite3")), max_upload_mb=10, image_max_side=800, max_tokens_detail=100)
    eng.register(PlantsProfile())
    return eng


def test_plants_listed(client):
    ids = [p["id"] for p in client.get("/v1/profiles").json()]
    assert "plants" in ids and "recipes" in ids


def test_plants_analyze_two_steps(tmp_path):
    calls = []

    class Spy(MockProvider):
        async def generate(self, req, mock_output=None):
            calls.append(req)
            return await super().generate(req, mock_output)

    res = asyncio.run(_engine(tmp_path, Spy()).analyze("plants", [jpeg_bytes((300, 300))] * 2,
                                                       PlantParams(language="pl", pets=True)))
    scan, care = calls
    assert scan.mode == "scan" and len(scan.images_jpeg) == 2 and "2 фото ОДНІЄЇ рослини" in scan.user_text
    assert "po polsku" in scan.system and "problems" not in scan.output_schema["properties"]
    assert care.mode == "analyze" and not care.images_jpeg
    assert "жовтіють 2 нижні листки" in care.user_text and "коти чи собаки" in care.system
    # вид і впевненість — з кроку «зір»; проблеми відсортовані від найважливішої
    assert res.name == "монстера" and res.confidence == 0.93 and res.alternatives[0].name == "філодендрон"
    assert [p.severity.value for p in res.problems] == ["high", "low"]
    assert res.symptoms[0] == "жовтіють 2 нижні листки"
    assert res.health.value == "needs_attention" and res.care.water_every_days == 7 and res.toxicity.pets is True


def test_plants_not_a_plant(client):
    class NoPlant(MockProvider):
        async def generate(self, req, mock_output=None):
            return {"plant_detected": False, "message": "Це кіт, а не рослина"}

    client.app.state.engine.provider = NoPlant()
    r = client.post("/v1/plants/analyze", files={"image": ("a.jpg", jpeg_bytes((300, 300)), "image/jpeg")})
    assert r.status_code == 422 and r.json()["code"] == "nothing_recognized" and "кіт" in r.json()["message"]


def test_plants_refine_detail_ask(client):
    r = client.post("/v1/plants/refine", json={"name": "фікус", "symptoms": ["опадає листя"], "params": {"language": "uk"}})
    assert r.status_code == 200 and r.json()["problems"]
    d = {"name": "монстера", "problem": "Перелив", "signs": "жовті листки", "params": {"language": "uk"}}
    r1 = client.post("/v1/plants/detail", json=d)
    assert r1.status_code == 200 and "## Що відбувається" in r1.json()["markdown"]
    r2 = client.post("/v1/plants/detail", json=d)
    assert r2.json().get("cached") is True
    r3 = client.post("/v1/plants/action/ask", json={"name": "монстера", "question": "Чи можна пересадити зараз?"})
    assert r3.status_code == 200 and r3.json()["answer"]


def test_plants_bad_input(client):
    r = client.post("/v1/plants/action/ask", json={"name": "монстера", "question": "?"})
    assert r.status_code == 422
    r = client.post("/v1/plants/refine", json={"name": ""})
    assert r.status_code == 422


def test_plants_progress_check_one_call(tmp_path):
    calls = []

    class Prog(MockProvider):
        async def generate(self, req, mock_output=None):
            calls.append(req)
            return {"plant_detected": True, "name": "монстера", "health": "needs_attention", "symptoms": ["2 старі плями"],
                    "progress": {"trend": "better", "note": "Нових плям немає", "still": ["старі плями"], "next_step": "Продовжуй"}}

    res = asyncio.run(_engine(tmp_path, Prog()).analyze(
        "plants", [jpeg_bytes((300, 300))],
        PlantParams(progress_for="Монстера", progress_problems=["Перелив", "Павутинний кліщ"], progress_days=10)))
    assert len(calls) == 1 and "перевірка лікування" in calls[0].user_text and "Павутинний кліщ" in calls[0].user_text
    assert res.progress.trend.value == "better" and res.name == "Монстера" and not res.problems


def test_plants_remedies_and_winter(client):
    r = client.post("/v1/plants/refine", json={"name": "монстера", "symptoms": ["жовтіють листки"]}).json()
    assert r["care"]["winter_water_every_days"] == 14
    assert any(p["remedies"] for p in r["problems"])
