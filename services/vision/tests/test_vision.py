import pytest
from fastapi.testclient import TestClient

from vision.analyzer import mock_analyze, parse_model_output
from vision.main import app
from vision.models import AnalyzeRequest


def test_healthz_reports_mock_mode():
    with TestClient(app) as c:
        r = c.get("/healthz")
    assert r.status_code == 200
    assert r.json()["mock"] is True


def test_mock_is_deterministic_and_privacy_free():
    req = AnalyzeRequest(image_url="https://example.com/a.jpg")
    a, b = mock_analyze(req), mock_analyze(req)
    assert a == b
    assert a.mock is True
    assert not {"people_visible", "licence_plate_visible"} & set(a.tags)


def test_analyze_endpoint_mock():
    with TestClient(app) as c:
        r = c.post("/v1/photos/analyze", json={"image_url": "https://example.com/b.jpg"})
    assert r.status_code == 200
    assert r.json()["model"] == "mock"


def test_analyze_rejects_bad_url():
    with TestClient(app) as c:
        r = c.post("/v1/photos/analyze", json={"image_url": "not a url"})
    assert r.status_code == 422


def test_parse_model_output_clamps_vocabulary():
    text = 'Sure! {"room_type": "kitchen", "tags": ["dishwasher", "spaceship", "people_visible"], "caption": "Kuchyň"}'
    out = parse_model_output(text, "terra-vision")
    assert out.room_type == "kitchen"
    assert out.tags == ["dishwasher", "people_visible"]
    assert out.needs_privacy_review is True


def test_parse_model_output_unknown_room_and_no_json():
    assert parse_model_output('{"room_type": "garage"}', "m").room_type == "other"
    with pytest.raises(ValueError):
        parse_model_output("no json here", "m")


def _jpeg(w: int = 200, h: int = 100) -> bytes:
    import io

    from PIL import Image

    img = Image.new("RGB", (w, h), (255, 255, 255))
    for x in range(w):
        img.putpixel((x, x % h), (0, 0, 0))
    out = io.BytesIO()
    img.save(out, format="JPEG")
    return out.getvalue()


def test_parse_model_output_regions():
    text = (
        '{"room_type": "exterior", "tags": ["licence_plate_visible"], "caption": "Dům", '
        '"privacy_regions": [{"label": "licence_plate", "box": [0.2, 0.6, 0.4, 0.7]}, '
        '{"label": "face", "box": [1, 1, 0, 0]}]}'
    )
    out = parse_model_output(text, "m")
    assert out.needs_privacy_review is True
    assert [r.label for r in out.regions] == ["licence_plate"]


def test_redact_blurs_only_regions():
    import io

    from PIL import Image

    from vision.images import redact
    from vision.models import Region

    src = _jpeg()
    out = Image.open(io.BytesIO(redact(src, [Region(label="face", box=(0.0, 0.0, 0.5, 1.0))])))
    orig = Image.open(io.BytesIO(src)).convert("RGB")
    assert out.size == orig.size
    # Right half untouched (JPEG noise aside), left half changed.
    assert abs(sum(out.getpixel((150, 50))) - sum(orig.getpixel((150, 50)))) < 60
    assert out.getpixel((10, 10)) != orig.getpixel((10, 10))


def test_redact_endpoint(monkeypatch):
    import vision.main as main

    async def fake_fetch(url, client, timeout):
        return _jpeg()

    monkeypatch.setattr(main, "fetch", fake_fetch)
    with TestClient(app) as c:
        r = c.post("/v1/photos/redact", json={"image_url": "https://example.com/p.jpg", "regions": []})
    assert r.status_code == 200
    assert r.headers["content-type"] == "image/jpeg"
    assert r.content[:3] == b"\xff\xd8\xff"
