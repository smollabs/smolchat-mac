from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock, patch

from PySide6.QtCore import QMimeData, QUrl
from PySide6.QtGui import QColor, QGuiApplication, QImage

from app.backend import Backend
from app.config import AppPaths
from app.model_manager import ModelEntry


def _make_backend(paths: AppPaths, vision: bool = True) -> Backend:
    backend = Backend(paths)
    backend._ready = True
    backend._runtime_ok = True
    if vision:
        entry = ModelEntry(
            id="test-vision-model",
            name="Test Vision Model",
            family="SmolVLM",
            parameters="500M",
            params_b=0.5,
            quality=0.8,
            description="",
            capabilities=("chat", "vision"),
            backend="llama_cpp",
            repo="test/repo",
            revision="main",
            source="huggingface",
            license="apache-2.0",
            quantization="Q4_K_M",
            context_length=2048,
            recommended_ram_gb=4,
            files=(),
        )
        backend._installed = {"test-vision-model": MagicMock(entry=entry)}
    else:
        backend._installed = {}
    return backend


def _set_clipboard_image(image: QImage):
    cb = QGuiApplication.clipboard()
    cb.clear()
    QGuiApplication.processEvents()
    mime = QMimeData()
    mime.setImageData(image)
    cb.setMimeData(mime)
    QGuiApplication.processEvents()


def _set_clipboard_text(text: str):
    cb = QGuiApplication.clipboard()
    cb.clear()
    QGuiApplication.processEvents()
    mime = QMimeData()
    mime.setText(text)
    cb.setMimeData(mime)
    QGuiApplication.processEvents()


def _set_clipboard_urls(urls: list[QUrl]):
    cb = QGuiApplication.clipboard()
    cb.clear()
    QGuiApplication.processEvents()
    mime = QMimeData()
    mime.setUrls(urls)
    cb.setMimeData(mime)
    QGuiApplication.processEvents()


@patch("app.inference.vision_supported", return_value=True)
def test_clipboard_empty(mock_vis, paths: AppPaths, qapp: QGuiApplication):
    cb = QGuiApplication.clipboard()
    cb.clear()
    QGuiApplication.processEvents()

    backend = _make_backend(paths, vision=True)
    res = backend.pasteImageFromClipboard()
    assert res == {"status": "not_image"}


@patch("app.inference.vision_supported", return_value=True)
def test_clipboard_text_only(mock_vis, paths: AppPaths, qapp: QGuiApplication):
    _set_clipboard_text("Just regular text")

    backend = _make_backend(paths, vision=True)
    res = backend.pasteImageFromClipboard()
    assert res == {"status": "not_image"}


@patch("app.inference.vision_supported", return_value=True)
def test_clipboard_valid_image(mock_vis, paths: AppPaths, qapp: QGuiApplication):
    img = QImage(32, 32, QImage.Format.Format_RGB32)
    img.fill(QColor("blue"))
    _set_clipboard_image(img)

    backend = _make_backend(paths, vision=True)
    res = backend.pasteImageFromClipboard(current_count=0)

    assert res.get("status") == "success"
    assert "path" in res
    assert "paths" in res
    assert len(res["paths"]) == 1

    file_url = res["path"]
    local_file = QUrl(file_url).toLocalFile()
    saved_path = Path(local_file)

    assert saved_path.exists()
    assert saved_path.is_relative_to(backend.paths.attachments)
    assert saved_path.suffix.lower() == ".png"

    # Verify saved image is valid
    saved_img = QImage(str(saved_path))
    assert not saved_img.isNull()
    assert saved_img.width() == 32
    assert saved_img.height() == 32


@patch("app.inference.vision_supported", return_value=False)
def test_clipboard_image_without_vision(mock_vis, paths: AppPaths, qapp: QGuiApplication):
    img = QImage(16, 16, QImage.Format.Format_RGB32)
    img.fill(QColor("green"))
    _set_clipboard_image(img)

    backend = _make_backend(paths, vision=False)
    toasts = []
    backend.toast.connect(lambda msg, kind: toasts.append((msg, kind)))

    res = backend.pasteImageFromClipboard(current_count=0)
    assert res == {"status": "rejected", "reason": "no_vision"}
    assert any("vision-capable model" in msg for msg, kind in toasts)
    # Ensure no attachments were saved
    assert list(backend.paths.attachments.glob("*")) == []


@patch("app.inference.vision_supported", return_value=True)
def test_clipboard_image_limit_reached(mock_vis, paths: AppPaths, qapp: QGuiApplication):
    img = QImage(16, 16, QImage.Format.Format_RGB32)
    img.fill(QColor("green"))
    _set_clipboard_image(img)

    backend = _make_backend(paths, vision=True)
    toasts = []
    backend.toast.connect(lambda msg, kind: toasts.append((msg, kind)))

    res = backend.pasteImageFromClipboard(current_count=4)
    assert res == {"status": "rejected", "reason": "limit_reached"}
    assert any("up to 4 images" in msg for msg, kind in toasts)
    assert list(backend.paths.attachments.glob("*")) == []


@patch("app.inference.vision_supported", return_value=True)
def test_clipboard_file_urls_valid_images(
    mock_vis, paths: AppPaths, qapp: QGuiApplication, tmp_path: Path
):
    src1 = tmp_path / "img1.jpg"
    img1 = QImage(20, 20, QImage.Format.Format_RGB32)
    img1.fill(QColor("red"))
    img1.save(str(src1), "JPEG")

    src2 = tmp_path / "img2.png"
    img2 = QImage(20, 20, QImage.Format.Format_RGB32)
    img2.fill(QColor("yellow"))
    img2.save(str(src2), "PNG")

    _set_clipboard_urls([QUrl.fromLocalFile(str(src1)), QUrl.fromLocalFile(str(src2))])

    backend = _make_backend(paths, vision=True)
    res = backend.pasteImageFromClipboard(current_count=1)

    assert res.get("status") == "success"
    assert len(res["paths"]) == 2
    for p in res["paths"]:
        local = Path(QUrl(p).toLocalFile())
        assert local.exists()
        assert local.is_relative_to(backend.paths.attachments)


@patch("app.inference.vision_supported", return_value=True)
def test_clipboard_file_urls_non_images_rejected(
    mock_vis, paths: AppPaths, qapp: QGuiApplication, tmp_path: Path
):
    src = tmp_path / "notes.txt"
    src.write_text("hello", encoding="utf-8")

    _set_clipboard_urls([QUrl.fromLocalFile(str(src))])

    backend = _make_backend(paths, vision=True)
    res = backend.pasteImageFromClipboard(current_count=0)
    assert res == {"status": "not_image"}


@patch("app.inference.vision_supported", return_value=True)
def test_clipboard_file_urls_remote_ignored(mock_vis, paths: AppPaths, qapp: QGuiApplication):
    _set_clipboard_urls([QUrl("https://example.com/pic.png")])

    backend = _make_backend(paths, vision=True)
    res = backend.pasteImageFromClipboard(current_count=0)
    assert res == {"status": "not_image"}


@patch("app.inference.vision_supported", return_value=True)
def test_unique_filenames_prevent_overwrites(mock_vis, paths: AppPaths, qapp: QGuiApplication):
    img = QImage(10, 10, QImage.Format.Format_RGB32)
    img.fill(QColor("cyan"))
    _set_clipboard_image(img)

    backend = _make_backend(paths, vision=True)
    res1 = backend.pasteImageFromClipboard(current_count=0)
    res2 = backend.pasteImageFromClipboard(current_count=1)

    assert res1["path"] != res2["path"]
    p1 = Path(QUrl(res1["path"]).toLocalFile())
    p2 = Path(QUrl(res2["path"]).toLocalFile())
    assert p1.exists() and p2.exists()


@patch("app.inference.vision_supported", return_value=True)
def test_existing_attachment_storage_integration(mock_vis, paths: AppPaths, qapp: QGuiApplication):
    img = QImage(16, 16, QImage.Format.Format_RGB32)
    img.fill(QColor("magenta"))
    _set_clipboard_image(img)

    backend = _make_backend(paths, vision=True)
    res = backend.pasteImageFromClipboard(current_count=0)
    pasted_url = res["path"]

    # Now verify _store_attachments processes this attachment correctly without deleting or re-duplicating
    stored = backend._store_attachments([QUrl(pasted_url).toLocalFile()])
    assert len(stored) == 1
    local_path = Path(stored[0])
    assert local_path.exists()
    assert local_path.is_relative_to(backend.paths.attachments)


@patch("app.inference.vision_supported", return_value=True)
def test_invalid_image_data_rejected(mock_vis, paths: AppPaths, qapp: QGuiApplication):
    cb = QGuiApplication.clipboard()
    mime = QMimeData()
    mime.setImageData(QImage())  # null image
    cb.setMimeData(mime)

    backend = _make_backend(paths, vision=True)
    res = backend.pasteImageFromClipboard(current_count=0)
    assert res == {"status": "not_image"}


@patch("app.inference.vision_supported", return_value=True)
def test_image_save_failure_handled(mock_vis, paths: AppPaths, qapp: QGuiApplication):
    img = QImage(16, 16, QImage.Format.Format_RGB32)
    img.fill(QColor("yellow"))
    _set_clipboard_image(img)

    backend = _make_backend(paths, vision=True)
    toasts = []
    backend.toast.connect(lambda msg, kind: toasts.append((msg, kind)))

    with patch.object(QImage, "save", return_value=False):
        res = backend.pasteImageFromClipboard(current_count=0)
        assert res == {"status": "error", "reason": "save_failed"}
        assert any("Could not save clipboard image" in msg for msg, kind in toasts)


@patch("app.inference.vision_supported", return_value=True)
def test_qml_composer_paste_shortcut(mock_vis, paths: AppPaths, qapp: QGuiApplication):
    from PySide6.QtCore import QEvent, QObject, Qt
    from PySide6.QtGui import QKeyEvent
    from PySide6.QtQml import QQmlApplicationEngine

    backend = _make_backend(paths, vision=True)
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)

    img = QImage(32, 32, QImage.Format.Format_RGB32)
    img.fill(QColor("red"))
    _set_clipboard_image(img)

    qml_snippet = """
    import QtQuick 2.15
    import QtQuick.Controls 2.15

    Item {
        id: composerArea
        property var attachments: []

        TextArea {
            id: composer
            text: "Initial text"
            Keys.onPressed: (event) => {
                if ((event.key === Qt.Key_V) && (event.modifiers === Qt.ControlModifier || event.modifiers === Qt.MetaModifier)) {
                    var res = backend.pasteImageFromClipboard(composerArea.attachments.length)
                    if (res && res.status !== "not_image") {
                        event.accepted = true
                        if (res.status === "success" && res.paths && res.paths.length > 0) {
                            var list = composerArea.attachments.slice()
                            for (var i = 0; i < res.paths.length; i++) {
                                var p = res.paths[i]
                                if (list.indexOf(p) < 0) list.push(p)
                            }
                            composerArea.attachments = list.slice(0, 4)
                        }
                        return
                    }
                }
            }
        }
    }
    """
    engine.loadData(qml_snippet.encode("utf-8"))
    root = engine.rootObjects()[0]
    composer = root.findChild(QObject, "")

    # 1. Pasting image intercepts event and adds attachment
    evt = QKeyEvent(QEvent.Type.KeyPress, Qt.Key.Key_V, Qt.KeyboardModifier.ControlModifier)
    qapp.sendEvent(composer, evt)
    assert evt.isAccepted()
    assert len(root.property("attachments").toVariant()) == 1

    # 2. Pasting text does not intercept event
    _set_clipboard_text(" pasted")
    evt2 = QKeyEvent(QEvent.Type.KeyPress, Qt.Key.Key_V, Qt.KeyboardModifier.ControlModifier)
    qapp.sendEvent(composer, evt2)
    # The event should pass through to TextArea
    assert composer.property("text") != "Initial text"
