import asyncio

from app.engine.engine import Engine
from app.engine.providers import MockProvider
from app.engine.store import Store
from app.profiles.homework import HomeworkParams, HomeworkProfile
from tests.test_api import client, isolated_db, jpeg_bytes  # noqa: F401  (фікстури)


def _run(tmp_path, params):
    calls = []

    class Spy(MockProvider):
        async def generate(self, req, mock_output=None):
            calls.append(req)
            return await super().generate(req, mock_output)

    eng = Engine(Spy(), Store(str(tmp_path / "s.sqlite3")), max_upload_mb=10, image_max_side=800, max_tokens_detail=100)
    eng.register(HomeworkProfile())
    res = asyncio.run(eng.analyze("homework", [jpeg_bytes((300, 300))], params))
    return calls, res


def test_learn_mode(tmp_path):
    (scan, solve), res = _run(tmp_path, HomeworkParams(grade=3))
    assert scan.mode == "scan" and "Нічого не розв'язуй" in scan.system and "student_work" not in scan.user_text.split("tasks —")[0]
    assert not solve.images_jpeg and "2x + 3 = 11" in solve.user_text and "молодша школа" in solve.system
    assert "<student_work" not in solve.user_text and "РЕЖИМ ПЕРЕВІРКИ" not in solve.system
    s = res.solutions[0]
    assert len(s.hints) == 3 and len(s.steps) == 2  # зайва підказка й порожній крок прибрані
    assert s.student_correct is None and not s.mistakes  # у режимі навчання — без оцінки учня
    assert res.subject.value == "algebra"


def test_check_mode(tmp_path):
    (scan, solve), res = _run(tmp_path, HomeworkParams(mode="check", grade=12))
    assert "перепиши в student_work" in scan.user_text
    assert "<student_work n=\"№ 246\">" in solve.user_text and "РЕЖИМ ПЕРЕВІРКИ" in solve.system and "студент" in solve.system
    assert res.solutions[1].student_correct is False and res.solutions[1].mistakes[0].where == "у першому рядку"


def test_homework_http(client):
    r = client.post("/v1/homework/refine", json={"tasks": [{"text": "Знайди площу квадрата зі стороною 4 см"}],
                                                "params": {"grade": 5, "language": "pl"}})
    assert r.status_code == 200 and r.json()["solutions"]
    assert client.post("/v1/homework/refine", json={"tasks": []}).status_code == 422
    assert client.post("/v1/homework/refine", json={"tasks": [{"text": "x"}], "params": {"grade": 20}}).status_code == 422
    d = {"topic": "Лінійні рівняння", "subject": "algebra"}
    r1 = client.post("/v1/homework/detail", json=d)
    assert r1.status_code == 200 and "## Коротко" in r1.json()["markdown"]
    assert client.post("/v1/homework/detail", json=d).json().get("cached") is True
    r2 = client.post("/v1/homework/action/ask", json={"task": "2x + 3 = 11", "question": "Чому знак міняється?"})
    assert r2.status_code == 200 and r2.json()["answer"]

    class Blank(MockProvider):
        async def generate(self, req, mock_output=None):
            return {"detected": False, "message": "Це селфі"}

    client.app.state.engine.provider = Blank()
    r = client.post("/v1/homework/analyze", files={"image": ("a.jpg", jpeg_bytes((300, 300)), "image/jpeg")})
    assert r.status_code == 422 and r.json()["message"] == "Це селфі"
