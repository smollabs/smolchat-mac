"""Start-up failure handling (issue #13).

Covers:
- Corrupt ``chats.sqlite3`` is moved aside and replaced; healthy/locked files are not.
- ``Backend`` launches with a corrupt database and tells the user.
- ``Backend._on_init_done`` copes with any combination of missing results.
- A registry / hardware / scan failure is reported persistently, not as an empty library.
"""

from __future__ import annotations

import itertools
import sqlite3

import pytest

from app import backend as backend_mod
from app.backend import Backend
from app.config import HardwareInfo
from app.database import ChatDatabase, open_database, quarantine_database
from app.model_manager import ModelRegistry, ModelStore


# ----------------------------------------------------------------- database


def _write_garbage(path):
    path.write_bytes(b"this is definitely not an sqlite database " * 200)


def test_open_database_healthy_returns_no_backup(paths):
    d = ChatDatabase(paths.database)
    conv = d.create_conversation("keep me")
    d.close()
    db, backup = open_database(paths.database)
    assert backup is None
    assert db.get_conversation(conv.id).title == "keep me"
    db.close()


def test_corrupt_database_is_moved_aside_and_replaced(paths):
    _write_garbage(paths.database)
    original = paths.database.read_bytes()

    # Sanity check: this is the failure from the issue.
    with pytest.raises(sqlite3.DatabaseError, match="not a database"):
        ChatDatabase(paths.database)

    db, backup = open_database(paths.database)
    try:
        assert backup is not None
        assert backup.parent == paths.database.parent
        assert backup.name.startswith("chats.sqlite3.corrupt-")
        assert backup.read_bytes() == original  # evidence preserved untouched
        assert db.list_conversations() == []  # fresh, empty and usable
        db.create_conversation("after recovery")
        assert len(db.list_conversations()) == 1
    finally:
        db.close()


def test_quarantine_moves_wal_and_shm_sidecars_too(paths):
    _write_garbage(paths.database)
    for suffix, data in (("-wal", b"wal"), ("-shm", b"shm")):
        paths.database.with_name("chats.sqlite3" + suffix).write_bytes(data)
    backup = quarantine_database(paths.database)
    assert backup.exists()
    assert backup.with_name(backup.name + "-wal").read_bytes() == b"wal"
    assert backup.with_name(backup.name + "-shm").read_bytes() == b"shm"
    assert all(".corrupt-" in p.name for p in paths.data.glob("chats.sqlite3*"))


def test_damaged_pages_detected_by_integrity_check(paths):
    d = ChatDatabase(paths.database)
    conv = d.create_conversation("big")
    for i in range(400):
        d.add_message(conv.id, "user", f"message {i} " + "x" * 200)
    d._conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    d.close()
    raw = bytearray(paths.database.read_bytes())
    assert len(raw) > 4096 * 6
    raw[4096 * 2: 4096 * 5] = b"\xff" * (4096 * 3)  # keep the header, wreck the b-trees
    paths.database.write_bytes(bytes(raw))

    db, backup = open_database(paths.database)
    db.close()
    assert backup is not None and backup.exists()


def test_repeated_corruption_never_overwrites_an_earlier_backup(paths):
    _write_garbage(paths.database)
    first = quarantine_database(paths.database)
    _write_garbage(paths.database)
    second = quarantine_database(paths.database, now=None)
    assert first != second and first.exists() and second.exists()


def test_environmental_errors_do_not_quarantine(tmp_path):
    # A directory where the file should be -> "unable to open database file"
    # (OperationalError). That's not corruption, so nothing may be moved aside.
    bad = tmp_path / "chats.sqlite3"
    bad.mkdir()
    with pytest.raises(sqlite3.OperationalError):
        open_database(bad)
    assert [p.name for p in tmp_path.iterdir()] == ["chats.sqlite3"]


def test_failed_open_releases_the_file_handle(paths):
    _write_garbage(paths.database)
    with pytest.raises(sqlite3.DatabaseError):
        ChatDatabase(paths.database)
    paths.database.unlink()
    assert not paths.database.exists()


# ------------------------------------------------------------------ backend


def test_backend_launches_with_corrupt_database_and_explains(paths):
    _write_garbage(paths.database)
    b = Backend(paths)
    try:
        backups = list(paths.data.glob("chats.sqlite3.corrupt-*"))
        assert len(backups) == 1
        assert backups[0].name in b.startupNotice
        assert "empty" in b.startupNotice
        assert b.startupError == ""
        b.db.create_conversation("works")
        b.dismissStartupNotice()
        assert b.startupNotice == ""
    finally:
        b.db.close()


def test_backend_with_healthy_database_has_no_notice(paths):
    b = Backend(paths)
    try:
        assert b.startupNotice == "" and b.startupError == ""
    finally:
        b.db.close()


@pytest.fixture
def backend(paths):
    b = Backend(paths)
    yield b
    b.db.close()


def _good_pieces(paths):
    registry = ModelRegistry.load(paths.registry_file)
    return {
        "registry": registry,
        "hardware": HardwareInfo.detect(),
        "store": ModelStore(paths, registry),
        "installed": {},
        "runtime": (False, "not installed"),
    }


_KEYS = ["registry", "hardware", "store", "installed", "runtime"]


@pytest.mark.parametrize(
    "present",
    [c for n in range(len(_KEYS) + 1) for c in itertools.combinations(_KEYS, n)],
)
@pytest.mark.parametrize("error", [None, "boom"])
def test_on_init_done_handles_any_combination_of_results(paths, backend, present, error):
    pieces = _good_pieces(paths)
    result = {k: pieces[k] for k in present}
    result["done"] = True
    if error:
        result["error"] = error
    backend._on_init_done(result)  # must not raise (it runs inside a Qt slot)
    assert backend.ready is True


def test_on_init_done_ignores_status_updates(backend):
    backend._on_init_done({"status": "Detecting hardware…"})
    assert backend.ready is False
    assert backend.initStatus == "Detecting hardware…"


def test_registry_failure_is_a_persistent_visible_error(backend):
    backend._on_init_done({"done": True, "errors": {"registry": "Expecting value: line 1"}})
    assert backend.ready is True
    assert "model catalogue" in backend.startupError
    assert "Expecting value" in backend.startupError
    assert backend.library.count == 0
    assert backend.initStatus == "Started with errors"


def test_legacy_error_only_result_is_still_reported(backend):
    backend._on_init_done({"done": True, "error": "something broke"})
    assert backend.ready is True
    assert "something broke" in backend.startupError


def test_hardware_failure_after_registry_loaded_does_not_raise(paths, backend):
    pieces = _good_pieces(paths)
    backend._on_init_done({
        "done": True,
        "registry": pieces["registry"],
        "errors": {"hardware": "sysctl failed"},
        "error": "sysctl failed",
    })
    assert backend.ready is True
    assert backend.hardware is not None  # conservative fallback profile
    assert "sysctl failed" in backend.startupNotice
    assert backend.startupError == ""  # not fatal
    assert backend.library.count == 0  # no store yet, but nothing crashed


def test_init_worker_isolates_failures(paths, backend, monkeypatch):
    def bad_registry(path):
        raise ValueError("models.json is broken")

    def bad_detect():
        raise OSError("no sysctl")

    monkeypatch.setattr(ModelRegistry, "load", staticmethod(bad_registry))
    monkeypatch.setattr(HardwareInfo, "detect", staticmethod(bad_detect))
    monkeypatch.setattr(backend_mod, "llama_cpp_available", lambda: (True, "9.9"))

    backend._init_worker()  # same thread -> signal is delivered directly

    assert backend.ready is True
    assert "models.json is broken" in backend.startupError
    assert backend.hardware is not None
    assert backend.device_profile() is not None  # no repeated detect() failure
    assert backend._runtime_ok is True  # independent step still ran
    assert backend.library.count == 0


def test_init_worker_happy_path_has_no_errors(backend, monkeypatch):
    monkeypatch.setattr(backend_mod, "llama_cpp_available", lambda: (True, "9.9"))
    backend._init_worker()
    assert backend.ready is True
    assert backend.startupError == ""
    assert backend.initStatus == "Ready"
    assert backend.library.count > 0
