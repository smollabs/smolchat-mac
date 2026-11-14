# SmolChat for macOS

A lightweight Mac AI chat application that runs small language models directly on the user's machine. Part of **SmolWorks**.

**Download once, run locally, chat offline.** SmolChat ships with no model weights. You pick models from the built-in Model Library, they download from Hugging Face into your Library folder, and from then on every conversation runs on your Mac with no network, no cloud APIs and no telemetry.

Built with Python, PySide6 and QML, with inference through llama.cpp (Metal on Apple Silicon).

**Contents:** [Why SmolChat](#why-smolchat) · [Tech stack](#tech-stack) · [Features](#features) · [Getting started](#getting-started) · [Contributing](#contributing) · [Architecture](#architecture) · [Tests](#tests)

## Why SmolChat

Most AI chat apps send every prompt to a server. That costs money, needs a connection, and means your conversations leave your machine. Large local models avoid that, but they need a powerful computer and a lot of setup.

SmolChat sits in between. The [Smol models](https://huggingface.co/HuggingFaceTB) from Hugging Face are small enough (135M to 3B parameters) to run on an everyday Mac, including 8 GB machines. SmolChat makes them easy to use:

- **Private by design**: chats, prompts and images never leave the Mac, and there is no telemetry.
- **Works offline**: after a model is downloaded, no network is needed.
- **No setup knowledge needed**: the app checks your hardware, recommends a model that will run well, and refuses ones that would slow your Mac down.
- **Free to run**: no API keys, accounts or usage limits.

It is also a readable, tested reference for building a native desktop app around local LLM inference.

## Tech stack

| Layer | Technology |
|---|---|
| Language | Python 3.10–3.12 |
| Desktop UI | [PySide6](https://doc.qt.io/qtforpython-6/) (Qt 6) with QML / Qt Quick |
| Inference | [llama.cpp](https://github.com/ggml-org/llama.cpp) through [llama-cpp-python](https://github.com/abetlen/llama-cpp-python), Metal GPU on Apple Silicon |
| Vision | llama.cpp's libmtmd multimodal library (SmolVLM / SmolVLM2) |
| Models | GGUF files from Hugging Face, pinned in `resources/models.json` |
| Storage | SQLite (chat history) and JSON (settings) |
| Tests | pytest |
| Packaging | PyInstaller, `codesign`, `notarytool` |

## Features

- Splash screen, then a ChatGPT-style window: sidebar with date-grouped history, search, rename and delete; markdown messages; highlighted code blocks with copy; regenerate; streaming with a stop button.
- **Model Library**: 16 Smol models across text, vision, documents and retrieval, with size, quantization, RAM estimate, licence and source. Downloads are resumable, cancellable, SHA-256-verified, and pinned to exact Hugging Face commits.
- **Device-aware recommendations**: SmolChat checks your macOS version, chip, memory and free storage, then rates each model as *Runs well*, *Runs, may be slower* or *Not recommended*. It marks the best model for your Mac and **refuses to download** a model that would slow the Mac down (heavy memory swapping, CPU-only on a large model) or fill the disk.
- **Clear download progress**: each row shows the download size, plus MB downloaded, percentage, speed and time remaining while downloading.
- **Dynamic loading**: a model is usable as soon as its download finishes, and you can switch models mid-session without restarting. Only one model is in memory at a time, and it can be unloaded on demand.
- **Automatic model selection**: each message goes to the best *installed* model, based on task (text or image), request complexity, model size, free memory, which model is already loaded, and your Speed/Balanced/Quality preference. Nothing is ever downloaded automatically.
- **Manual selection** per conversation. It is saved with the chat, and you can switch back to Auto at any time.
- **Vision**: SmolVLM and SmolVLM2 models answer questions about attached images (paperclip button or drag and drop).
- Native full-height macOS window with smooth animations. Dark (default), Light or **System** theme (follows macOS appearance), six accent colours, and a crossfade whenever the theme changes. There's a quick sun/moon toggle in the sidebar.
- Local SQLite history and JSON settings.

## Supported models

| Family | Sizes | Runs in SmolChat | Source of GGUF |
|---|---|---|---|
| SmolLM (v0.2 instruct) | 135M, 360M, 1.7B | ✅ chat | Official `HuggingFaceTB/smollm-*-instruct-v0.2-Q8_0-GGUF` |
| SmolLM2 Instruct | 135M, 360M, 1.7B | ✅ chat | Official for 360M/1.7B; 135M from `bartowski/SmolLM2-135M-Instruct-GGUF` (no official GGUF exists) |
| SmolLM3 | 3B | ✅ chat (optional thinking mode) | `ggml-org/SmolLM3-3B-GGUF` |
| SmolVLM Instruct | 256M, 500M, 2.2B | ✅ chat + images | `ggml-org/SmolVLM-*-GGUF` (+ `mmproj`) |
| SmolVLM2 Instruct | 256M, 500M, 2.2B | ✅ chat + still images (no video) | `ggml-org/SmolVLM2-*-GGUF` (+ `mmproj`) |
| SmolDocling | 256M | ❌ listed, not runnable | — |
| ColSmol | 256M, 500M | ❌ listed, not runnable | — |

The repositories, revisions, file sizes and SHA-256 hashes in `resources/models.json` were read from the Hugging Face API. Re-check them with `python scripts/verify_registry.py`.

### Known limitations

- **SmolDocling** has no official GGUF with a vision projector, and its DocTags output needs the `docling` toolkit to become Markdown. It appears in the library as *Not yet supported*. Document-style image questions are answered by an installed SmolVLM model instead, and the app says so.
- **ColSmol** is a ColPali-style multi-vector retriever, not a chat model, and llama.cpp cannot run it. It needs a PyTorch/`colpali-engine` runtime, which a future `smol-runtime` engine could provide.
- SmolVLM2's video understanding is not exposed. llama.cpp's multimodal library handles still images only.
- Conversation titles come from the first message rather than a model-written summary. Small models write unreliable titles.

## Getting started

Requirements: macOS 13 or later, Apple Silicon recommended (Intel works on CPU), Python 3.10–3.12, and Xcode Command Line Tools to build llama.cpp.

```bash
# 1. Get the code
git clone https://github.com/smollabs/smolchat-mac.git
cd smolchat-mac

# 2. Create a virtual environment
python3.12 -m venv .venv
source .venv/bin/activate

# 3. Install dependencies
pip install PySide6-Essentials pytest
CMAKE_ARGS="-DGGML_METAL=on" pip install llama-cpp-python   # compiles llama.cpp with Metal

# 4. Run the app
python main.py
```

On first launch no models are installed. Click **Download** on the recommended model, or open the **Model Library** (⌘⇧M), then start chatting. SmolLM2 360M Instruct (about 386 MB) is a quick first download.

To keep development data separate from a real install, run with `SMOLCHAT_HOME="$PWD/.smolchat-dev" python main.py`.

### Keyboard shortcuts

| | |
|---|---|
| ⌘N | New chat |
| ⌘K | Search chats |
| ⌘⇧M | Model Library |
| ⌘, | Settings |
| ⌘\ | Toggle sidebar |
| ⇧⌘L | Switch light / dark |
| ⌘. | Stop generating |
| ↩ / ⇧↩ | Send / new line |

## Where data lives

| What | Location |
|---|---|
| Model weights | `~/Library/Application Support/SmolWorks/SmolChat/models/<model-id>/` |
| Install manifests | `~/Library/Application Support/SmolWorks/SmolChat/metadata/` |
| Settings | `~/Library/Application Support/SmolWorks/SmolChat/settings.json` |
| Conversations | `~/Library/Application Support/SmolWorks/SmolChat/chats.sqlite3` |
| Image attachments | `~/Library/Application Support/SmolWorks/SmolChat/attachments/` |
| Partial downloads | `~/Library/Caches/SmolWorks/SmolChat/downloads/` |
| Logs | `~/Library/Logs/SmolWorks/SmolChat/smolchat.log` |

Set `SMOLCHAT_HOME=/some/dir` to put all of these under a single directory, which is useful for development.

## Contributing

Contributions are welcome, whether it's your first open-source pull request or your fiftieth.

### Where to start

1. Read [CONTRIBUTING.md](CONTRIBUTING.md) for the ground rules (no new network calls, nothing downloaded automatically, the UI never blocks), code style and the pull request checklist.
2. Set up the project with the steps in [Getting started](#getting-started) and make sure `pytest` passes.
3. Skim the [Architecture](#architecture) section. Most logic lives in Qt-free modules in `app/`, which are easy to read and test without running the UI.
4. Pick an issue, comment that you'd like to work on it, then open a pull request that references it (for example `Fixes #12`).

Good first places to look in the code:

| If you like… | Look at |
|---|---|
| Python logic and tests | `app/model_router.py`, `app/formatting.py`, `app/database.py`, `tests/` |
| Desktop UI | `ui/*.qml` and `ui/styles/theme.qml` |
| Inference and performance | `app/inference.py`, `app/backend.py` |
| Downloads and the model registry | `app/model_manager.py`, `resources/models.json` |

### Finding an issue

All open work is tracked in [GitHub Issues](https://github.com/smollabs/smolchat-mac/issues). Issues are labelled by difficulty:

| Label | Meaning |
|---|---|
| [`good first issue`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) | Small and well scoped, a good way to get to know the codebase |
| [`level 1`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3A%22level+1%22) | Beginner: a focused fix or a set of tests |
| [`level 2`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3A%22level+2%22) | Intermediate: touches several functions or needs some design |
| [`level 3`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3A%22level+3%22) | Advanced: larger changes across Python and QML |

Issues for the WOCS program carry the [`wocs`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3Awocs) label. You can also filter by area, for example [`bug`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3Abug), [`testing`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3Atesting), [`performance`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3Aperformance) or [`component:desktop`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3Acomponent%3Adesktop).

Found a bug or have an idea that isn't listed? [Open a new issue](https://github.com/smollabs/smolchat-mac/issues/new) with your macOS version, chip, memory, the model in use and steps to reproduce.

## Architecture

```
main.py               entry point: Qt app, QML engine, splash → main window
app/config.py         paths, JSON settings, hardware + free-memory detection
app/database.py       SQLite conversations/messages
app/model_manager.py  registry, installed-model store, resumable SHA-256-verified downloader (Qt-free)
app/model_router.py   pure-function automatic model selection
app/inference.py      InferenceEngine interface, llama.cpp engine, RuntimeManager (lifecycle + locking)
app/formatting.py     markdown/code/<think> segmentation + code highlighting
app/backend.py        the only Qt↔Python bridge: list models, slots, signals, worker threads
ui/*.qml              QML interface (main, splash, sidebar, chat, model_library, settings, components, styles/theme)
resources/models.json verified model registry
resources/assets/logo brand artwork: logo tiles (157–1254 px, app/Dock icon, sidebar) and the
                      transparent mascot shown in 3D on the splash and home screen
scripts/prepare_brand_assets.py  derives UI-ready assets (e.g. smollabs_mascot_clean.png) from the originals
```

- The UI never blocks. Startup scanning, downloads, model loading and generation run on worker threads and report back through Qt signals, which are delivered on the UI thread. Tokens are batched about every 40 ms.
- `RuntimeManager` keeps one model in memory. Loading another unloads the current one first, and a single lock serialises load, generate and unload, so a model can't be swapped or deleted mid-response.
- Each GGUF's embedded chat template is used as-is, which keeps each model's own tokenizer and prompt format. SmolVLM gets a dedicated libmtmd handler that mirrors its Hugging Face template.
- **Plugging in `smol-runtime`**: implement `app.inference.InferenceEngine` (`load`, `unload`, `generate`, `loaded_model_id`) and call `register_engine("<backend>", Factory)`. Registry entries pick their engine through the `backend` field, so the UI and backend need no changes.

## Tests

```bash
pytest
```

The suites cover the database, registry integrity (pinned revisions, checksums, no false capability claims), downloads (resume, cancel, checksum failure, offline errors) against a fake Hub, store scanning and deletion, routing decisions, and message formatting.

To run the real llama.cpp smoke test, point `SMOLCHAT_TEST_GGUF` at a downloaded GGUF file (for example SmolLM2-135M-Instruct) and run `pytest`.

To try the compatibility rules on other hardware, set `SMOLCHAT_SIMULATE_RAM_GB=4` or `SMOLCHAT_SIMULATE_FREE_GB=1.5`.

Development aids: `SMOLCHAT_SCREENSHOT=out.png` saves a capture of the window and quits. Optional extras:
- `SMOLCHAT_SCREENSHOT_DELAY=<ms>` sets when the capture happens;
- `SMOLCHAT_SCREENSHOT_PANEL=library|settings` opens a panel first;
- `SMOLCHAT_SCREENSHOT_PROMPT="…"` sends a message first.

## Packaging

```bash
scripts/build_macos.sh      # → dist/SmolChat.app (arm64), weights are not bundled
```

The script builds the `.icns` app icon from `resources/assets/logo/logo-1254.png`, then runs PyInstaller with `packaging/SmolChat.spec`. For distribution, sign it with a Developer ID (`codesign --options runtime`) and notarize it with `xcrun notarytool`.

## Privacy

SmolChat makes network requests only to `huggingface.co` (and its CDN) when you download a model. Chats, prompts and attachments never leave the Mac. There is no telemetry.

## License

SmolChat is licensed under the [Apache License 2.0](LICENSE). Each model has its own licence, which is shown in the Model Library.
