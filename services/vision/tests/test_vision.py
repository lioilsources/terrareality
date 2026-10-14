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
