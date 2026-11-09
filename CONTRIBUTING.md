# Contributing to SmolChat

Thanks for helping improve SmolChat. This guide covers how to set up a development environment, the project's ground rules, and what a good pull request looks like.

## Ground rules

SmolChat's promise is **download once, run locally, chat offline**. Every change has to keep that promise:

- **No new network calls.** The only network traffic allowed is model downloads from `huggingface.co` (and its CDN), started by the user. No telemetry, analytics, crash reporting or update checks.
- **Nothing is downloaded automatically.** The router may only choose among models that are already installed.
- **Chats, prompts and attachments never leave the Mac.**
- **The UI never blocks.** Downloads, loading, scanning and generation run on worker threads and report back through Qt signals.
- **No false claims.** If a model can't actually do something in SmolChat, the registry and UI must not say it can.

## Development setup

Requirements: macOS 13 or later (Apple Silicon recommended), Python 3.10–3.12, and Xcode Command Line Tools.

```bash
python3.12 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
CMAKE_ARGS="-DGGML_METAL=on" pip install --force-reinstall --no-cache-dir llama-cpp-python
python main.py
```

Keep your development data separate from a real install:

```bash
export SMOLCHAT_HOME="$PWD/.smolchat-dev"
```

Useful environment variables:

| Variable | Purpose |
|---|---|
| `SMOLCHAT_HOME` | Put models, settings, chats, caches and logs under one directory |
| `SMOLCHAT_SIMULATE_RAM_GB` | Pretend the Mac has this much memory (test compatibility ratings) |
| `SMOLCHAT_SIMULATE_FREE_GB` | Pretend this much disk space is free |
| `SMOLCHAT_TEST_GGUF` | Path to a real GGUF to enable the llama.cpp smoke test |
| `SMOLCHAT_SCREENSHOT` | Save a window capture to this path and quit (see README for options) |

Logs are written to `~/Library/Logs/SmolWorks/SmolChat/smolchat.log` (or under `SMOLCHAT_HOME`).

## Project layout

See the [Architecture](README.md#architecture) section of the README. In short:

- `app/` is the Python core. Only `app/backend.py` talks to Qt. Keep `model_manager.py`, `model_router.py`, `database.py` and `formatting.py` Qt-free so they stay easy to test.
- `ui/` holds the QML interface. Colours, spacing and fonts come from `ui/styles/theme.qml`, so use theme tokens rather than hard-coded values, and check both Light and Dark themes.
- `resources/models.json` is the model registry.
- `scripts/` holds build, packaging and maintenance scripts.

## Making changes

### Code style

- Python follows PEP 8 with a 100-character line limit (configured for `ruff` in `pyproject.toml`). Use type hints and `from __future__ import annotations` like the existing modules.
- Match the surrounding code: naming, comment density and structure.
- Keep changes focused. Unrelated refactors belong in their own pull request.

### Tests

Run the suite before opening a pull request:

```bash
pytest
```

Add or update tests for any behaviour change, especially in downloads, routing, compatibility rules, the database and formatting. Tests must not touch the network; use the `FakeHub` opener in `tests/test_model_manager.py`.

For UI changes, run the app and check the affected screens in both themes. Attach screenshots to the pull request (`SMOLCHAT_SCREENSHOT=out.png python main.py` helps).

### Adding or updating a model

Registry entries in `resources/models.json` must be exact and verifiable:

1. Pin the Hugging Face repository to a full commit `revision`, never a branch.
2. Read every file's `size` and `sha256` from the Hugging Face API, not from a local download you made.
3. Only list `capabilities` the model really has in SmolChat. Mark models the runtime can't run as unsupported instead of leaving them out silently.
4. Fill in `license`, `source`, `quantization`, `context_length` and `recommended_ram_gb`.
5. Run `python scripts/verify_registry.py` (needs network) and `pytest`, and bump the `updated` date.
6. Update the *Supported models* table in the README.

### Adding an inference engine

Implement `app.inference.InferenceEngine` (`load`, `unload`, `generate`, `loaded_model_id`), register it with `register_engine("<backend>", Factory)`, and set `backend` on the registry entries that use it. The UI and backend shouldn't need changes; if they do, explain why in the pull request.

## Building

```bash
scripts/build_macos.sh   # → dist/SmolChat.app
scripts/make_dmg.sh      # → dist/SmolChat-<version>.dmg
```

Never commit model weights, build output (`build/`, `dist/`) or local data directories.

## Pull requests

1. Branch from `main`.
2. Write clear commit messages that say what changed and why.
3. Make sure `pytest` passes.
4. In the pull request, describe the change, how you tested it, and include screenshots for UI work.
5. Note any effect on privacy, memory use or download size.

## Reporting bugs

Open an issue with:

- macOS version, chip and memory (shown in Settings)
- the model in use, if relevant
- steps to reproduce, and what you expected instead
- the relevant part of `smolchat.log`

Remove anything private from logs and screenshots before posting.

## License

SmolChat is licensed under Apache-2.0. By contributing, you agree that your contributions are licensed under the same terms.
