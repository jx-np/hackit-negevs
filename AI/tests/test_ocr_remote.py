import httpx
import pytest

from app.config import Settings
from pii.ocr import OcrEngine
from pii.ocr_remote import OcrBadImageError, OcrUnavailableError, RemoteOcrEngine, build_ocr_engine


@pytest.mark.asyncio
async def test_success_and_auth_headers():
    seen = []
    def handler(req):
        seen.append(req.headers.get("authorization"))
        return httpx.Response(200, json={"boxes": [{"box": [[1, 2]], "text": "x", "score": "0.8"}], "total_box_count": 1})
    engine = RemoteOcrEngine("http://ocr/", "secret", transport=httpx.MockTransport(handler))
    assert await engine.aextract(b"img", "image/png") == [{"box": [[1.0, 2.0]], "text": "x", "score": 0.8}]
    await engine.aclose()
    assert seen == ["Bearer secret"]

    engine = RemoteOcrEngine("http://ocr", transport=httpx.MockTransport(handler))
    await engine.aextract(b"img", "image/png")
    await engine.aclose()
    assert seen[-1] is None


@pytest.mark.asyncio
@pytest.mark.parametrize("status", [500, 503])
async def test_server_errors_unavailable(status):
    engine = RemoteOcrEngine("http://ocr", transport=httpx.MockTransport(lambda req: httpx.Response(status)))
    with pytest.raises(OcrUnavailableError):
        await engine.aextract(b"i", "image/png")
    await engine.aclose()


@pytest.mark.asyncio
async def test_bad_image():
    engine = RemoteOcrEngine("http://ocr", transport=httpx.MockTransport(lambda req: httpx.Response(400)))
    with pytest.raises(OcrBadImageError):
        await engine.aextract(b"i", "image/png")
    await engine.aclose()


@pytest.mark.asyncio
@pytest.mark.parametrize("exc", [httpx.TimeoutException("timeout"), httpx.ConnectError("down")])
async def test_transport_errors_unavailable(exc):
    engine = RemoteOcrEngine("http://ocr", transport=httpx.MockTransport(lambda req: (_ for _ in ()).throw(exc)))
    with pytest.raises(OcrUnavailableError):
        await engine.aextract(b"i", "image/png")
    await engine.aclose()


@pytest.mark.asyncio
async def test_malformed_response():
    engine = RemoteOcrEngine("http://ocr", transport=httpx.MockTransport(lambda req: httpx.Response(200, text="not json")))
    with pytest.raises(OcrUnavailableError):
        await engine.aextract(b"i", "image/png")
    await engine.aclose()


def test_factory_modes():
    local = build_ocr_engine(Settings(ocr_service_url=""))
    remote = build_ocr_engine(Settings(ocr_service_url="http://ocr"))
    assert isinstance(local, OcrEngine)
    assert isinstance(remote, RemoteOcrEngine)
