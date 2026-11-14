# Contributing to SmolChat

Thanks for helping improve SmolChat! This guide walks you through everything from finding an issue to getting your pull request merged. If this is your first open-source contribution, you're in the right place: follow the steps in order and you'll be fine. If you get stuck at any point, ask in a comment on your issue.

**Contents**

1. [How contributing works](#1-how-contributing-works)
2. [Requirements](#2-requirements)
3. [Setting up the project](#3-setting-up-the-project)
4. [Finding and claiming an issue](#4-finding-and-claiming-an-issue)
5. [Making your changes](#5-making-your-changes)
6. [Opening a pull request](#6-opening-a-pull-request)
7. [Code style and conventions](#7-code-style-and-conventions)
8. [Project rules](#8-project-rules)
9. [Labels and WOCS points](#9-labels-and-wocs-points)
10. [Reporting bugs and suggesting features](#10-reporting-bugs-and-suggesting-features)
11. [Advanced topics](#11-advanced-topics)

## 1. How contributing works

```
Find an issue → Comment to claim it → Get assigned → Fork & clone → Create a branch
→ Make changes + tests → Run pytest → Push → Open a pull request → Review → Merged 🎉
```

In short:

1. **Pick an issue** from the [issue list](https://github.com/smollabs/smolchat-mac/issues) and ask to work on it.
2. **Wait to be assigned** before you start, so two people don't work on the same thing.
3. **Fork the repository**, make your change on a new branch, and test it.
4. **Open a pull request** (PR) that links to the issue.
5. **A maintainer reviews it.** You may be asked for changes. That's normal and part of the process.
6. Once approved, a maintainer **merges** it.

## 2. Requirements

| What | Version | Why |
|---|---|---|
| macOS | 13 (Ventura) or later | SmolChat is a native Mac app |
| Mac | Apple Silicon (M1 or later) recommended | Intel Macs work, but run models on the CPU only |
| Python | 3.10, 3.11 or 3.12 | The versions the project is tested with |
| Xcode Command Line Tools | latest | Needed to compile llama.cpp. Install with `xcode-select --install` |
| Git | any recent version | To clone and push your changes |
| GitHub account | — | To fork the repository and open pull requests |
| Free disk space | ~2 GB | For dependencies and one small model |

Python dependencies (installed in the next step):

| Package | Used for |
|---|---|
| `PySide6-Essentials` ≥ 6.8 | Qt 6 / QML desktop interface |
| `llama-cpp-python` ≥ 0.3.16 | Running models with llama.cpp (Metal GPU on Apple Silicon) |
| `pytest` ≥ 8 | Running the test suite |
| `pyinstaller` ≥ 6.10 (optional) | Only needed to build the `.app` |

## 3. Setting up the project

### Step 1: Fork and clone

1. Click **Fork** at the top right of [the repository page](https://github.com/smollabs/smolchat-mac). This creates your own copy under your GitHub account.
2. Clone your fork and add the original repository as `upstream`:

```bash
git clone https://github.com/<your-username>/smolchat-mac.git
cd smolchat-mac
git remote add upstream https://github.com/smollabs/smolchat-mac.git
```

### Step 2: Create a virtual environment and install dependencies

```bash
python3.12 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
CMAKE_ARGS="-DGGML_METAL=on" pip install --force-reinstall --no-cache-dir llama-cpp-python
```

The last command compiles llama.cpp and can take several minutes. On an Intel Mac, leave out `CMAKE_ARGS="-DGGML_METAL=on"`.

> **Tip:** run `source .venv/bin/activate` every time you open a new terminal to work on SmolChat.

### Step 3: Keep your development data separate

So your experiments don't touch a real SmolChat install, store everything in a local folder:

```bash
export SMOLCHAT_HOME="$PWD/.smolchat-dev"
```

### Step 4: Run the app and the tests

```bash
python main.py   # opens the app
pytest           # runs the test suite; everything should pass
```

On first launch no models are installed. Download a small one (for example SmolLM2 360M Instruct, about 386 MB) from the Model Library (⌘⇧M) to try chatting.

If `pytest` passes and the app opens, your setup is done.

### Useful environment variables

| Variable | Purpose |
|---|---|
| `SMOLCHAT_HOME` | Put models, settings, chats, caches and logs under one directory |
| `SMOLCHAT_SIMULATE_RAM_GB` | Pretend the Mac has this much memory (test compatibility ratings) |
| `SMOLCHAT_SIMULATE_FREE_GB` | Pretend this much disk space is free |
| `SMOLCHAT_TEST_GGUF` | Path to a real GGUF to enable the llama.cpp smoke test |
| `SMOLCHAT_SCREENSHOT` | Save a window capture to this path and quit (see the README for options) |
| `SMOLCHAT_LOG_LEVEL` | Logging level, e.g. `DEBUG` |

Logs are written to `~/Library/Logs/SmolWorks/SmolChat/smolchat.log` (or under `SMOLCHAT_HOME`).

### Common setup problems

| Problem | Fix |
|---|---|
| `llama-cpp-python` fails to build | Run `xcode-select --install`, then retry the install command |
| App says the llama.cpp runtime failed to load | Reinstall with the `--force-reinstall --no-cache-dir` command above |
| `ModuleNotFoundError: PySide6` | Your virtual environment isn't active: run `source .venv/bin/activate` |
| Wrong Python version | Check with `python --version` and recreate `.venv` with `python3.12` |

## 4. Finding and claiming an issue

### Finding one

Browse the [open issues](https://github.com/smollabs/smolchat-mac/issues). Difficulty labels help you choose:

| Label | Good for |
|---|---|
| [`good first issue`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) | First-time contributors |
| [`level 1`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3A%22level+1%22) | Beginner: a focused fix or a set of tests |
| [`level 2`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3A%22level+2%22) | Intermediate: several functions, some design |
| [`level 3`](https://github.com/smollabs/smolchat-mac/issues?q=is%3Aissue+is%3Aopen+label%3A%22level+3%22) | Advanced: larger changes across Python and QML |

Start with a `level 1` or `good first issue` if you're new to the project.

### Claiming one

1. **Check that nobody is assigned.** Look at the *Assignees* box on the right of the issue.
2. **Comment on the issue**, for example:
   > Hi! I'd like to work on this. My plan is to … (one or two sentences).
3. **Wait for a maintainer to assign you** before starting. This prevents duplicate work.
4. **Work on one issue at a time.** Finish or release your current issue before claiming another.

### Staying assigned

- Post a short update if your PR isn't ready within **7 days** of being assigned. Issues with no activity for 7 days may be reassigned to someone else.
- If you can't continue, comment so the issue can be given to someone else. That's completely fine.
- Want to work on something that has no issue yet? [Open an issue](#10-reporting-bugs-and-suggesting-features) first and wait for a maintainer to confirm it before starting.

## 5. Making your changes

### Step 1: Update your fork and create a branch

Always start from the latest `main`:

```bash
git checkout main
git pull upstream main
git checkout -b fix/12-short-description
```

Name branches `<type>/<issue-number>-<short-description>`, for example:

| Type | Use for | Example |
|---|---|---|
| `fix/` | Bug fixes | `fix/2-clamp-max-tokens` |
| `feat/` | New features | `feat/10-voiceover-labels` |
| `test/` | Adding tests | `test/7-formatting-tests` |
| `docs/` | Documentation only | `docs/readme-setup-steps` |
| `refactor/` | Restructuring without behaviour changes | `refactor/6-db-migrations` |

### Step 2: Make the change

- Keep the change focused on the issue. Unrelated cleanups belong in a separate PR.
- Add or update tests for any behaviour change (see [Tests](#tests)).
- For UI changes, run the app and check the affected screens in **both Light and Dark** themes.

### Step 3: Test

```bash
pytest
```

Everything must pass before you open a PR.

### Step 4: Commit

Write commit messages that say **what** changed and **why**. Use the imperative mood ("Add", "Fix", not "Added", "Fixes"):

```
Clamp max_tokens to the loaded model's context window

Models with a 2048-token context failed when the response length
setting was 2K or 4K. Fixes #2.
```

```bash
git add <files you changed>
git commit
```

Small, logical commits are easier to review than one giant commit.

### Step 5: Push to your fork

```bash
git push origin fix/12-short-description
```

## 6. Opening a pull request

1. Go to your fork on GitHub. You'll see a **Compare & pull request** button. Click it.
2. Make sure the base is **`smollabs/smolchat-mac` → `main`** and the compare branch is yours.
3. Give the PR a clear title, e.g. `Clamp max_tokens to the model's context window`.
4. Fill in the description using this template:

```markdown
## What does this PR do?
Short summary of the change.

Fixes #<issue-number>

## How was it tested?
- [ ] `pytest` passes
- [ ] Ran the app and checked … (for UI changes: both Light and Dark themes)

## Screenshots
(Required for UI changes. `SMOLCHAT_SCREENSHOT=out.png python main.py` helps.)

## Notes
Any effect on privacy, memory use or download size, or anything reviewers should know.
```

5. Click **Create pull request**.

`Fixes #<number>` makes GitHub close the issue automatically when the PR is merged.

### After you open it

- **A maintainer will review your PR.** They may leave comments or ask for changes. This is normal, and every contributor gets review feedback.
- **To make changes**, edit your files on the same branch, commit and push again. The PR updates automatically. Don't open a new PR.
- **Reply to each review comment** or mark it resolved once handled.
- **If `main` has moved on** and your PR has conflicts, update your branch:
  ```bash
  git fetch upstream
  git rebase upstream/main
  git push --force-with-lease
  ```
- Be patient and polite. Reviews may take a few days.

### PR checklist

- [ ] The PR is linked to an issue you were assigned (`Fixes #…`)
- [ ] The change is focused on that one issue
- [ ] `pytest` passes
- [ ] Tests are added or updated for behaviour changes
- [ ] UI changes are checked in Light and Dark, with screenshots attached
- [ ] No model weights, build output or personal data are committed
- [ ] The project rules below are respected

## 7. Code style and conventions

### Python

- Follow PEP 8 with a **100-character line limit** (configured for `ruff` in `pyproject.toml`).
- Use type hints and start each module with `from __future__ import annotations`, like the existing modules.
- Match the surrounding code: naming, comment density and structure.
- Keep `model_manager.py`, `model_router.py`, `database.py`, `formatting.py` and `inference.py` **Qt-free**. Only `app/backend.py` talks to Qt.
- Long-running work (downloads, loading, generation) runs on worker threads and reports back through Qt signals.
- Show errors to users as clear, plain-language messages, not raw exceptions.

### QML

- Take colours, spacing, radii and fonts from `ui/styles/theme.qml` (`Theme.*`). Don't hard-code values.
- Reuse the shared building blocks in `ui/components.qml` (`C.Icon`, `C.IconButton`, `C.Button`, …) before creating new ones.
- Check every change in both Light and Dark themes.

### Project layout

| Path | What lives there |
|---|---|
| `app/` | The Python core (see the [Architecture](README.md#architecture) section of the README) |
| `ui/` | The QML interface |
| `resources/models.json` | The model registry |
| `resources/icons/`, `resources/assets/` | SVG icons, logos and artwork |
| `scripts/` | Build, packaging and maintenance scripts |
| `tests/` | The pytest suite |

### Tests

```bash
pytest
```

- Add or update tests for any behaviour change, especially in downloads, routing, compatibility rules, the database and formatting.
- **Tests must not touch the network.** Use the `FakeHub` opener in `tests/test_model_manager.py`.
- Use the `paths` fixture in `tests/conftest.py` so tests write to a temporary directory, never to `~/Library`.

## 8. Project rules

SmolChat's promise is **download once, run locally, chat offline**. Every change has to keep that promise. PRs that break these rules won't be merged:

- **No new network calls.** The only network traffic allowed is model downloads from `huggingface.co` (and its CDN), started by the user. No telemetry, analytics, crash reporting or update checks.
- **Nothing is downloaded automatically.** The router may only choose among models that are already installed.
- **Chats, prompts and attachments never leave the Mac.**
- **The UI never blocks.** Downloads, loading, scanning and generation run on worker threads.
- **No false claims.** If a model can't actually do something in SmolChat, the registry and UI must not say it can.
- **Never commit** model weights (`*.gguf`), build output (`build/`, `dist/`), virtual environments or local data directories like `.smolchat-dev/`.
- **No new dependencies** without discussing it in the issue first.
- **Remove private information** (names, paths, chat content) from logs and screenshots before posting.
- Be respectful and constructive in issues, PRs and reviews.

## 9. Labels and WOCS points

SmolChat takes part in **WOCS**. Points are calculated from PR labels, so they must be exact.

Every eligible PR needs **`wocs`** and **exactly one** of **`level 1`**, **`level 2`** or **`level 3`**:

| ✅ Correct | ❌ Incorrect |
|---|---|
| `wocs` | `WOCS`, `Wocs` |
| `level 1` | `LEVEL 1`, `Level1`, `level1` |
| `level 2` | `Level 2` with extra or double spaces |
| `level 3` | |

- The level normally matches the level of the issue you worked on.
- **Maintainers add the labels.** If your PR is missing them, mention it in a comment.
- **Labels must be added before the PR is merged.** If a PR is merged without the correct labels, points may not be awarded or tracked.

Other labels (`bug`, `enhancement`, `testing`, `performance`, `component:*`, `area:*`, …) describe the kind of work and the part of the app it touches.

## 10. Reporting bugs and suggesting features

Check the [existing issues](https://github.com/smollabs/smolchat-mac/issues) first to avoid duplicates. Then [open a new issue](https://github.com/smollabs/smolchat-mac/issues/new).

**For bugs, include:**

- macOS version, chip and memory (shown in Settings)
- the model in use, if relevant
- steps to reproduce, what happened, and what you expected instead
- the relevant part of `smolchat.log`

**For features, include:**

- the problem you're trying to solve
- your proposed solution
- how it fits the project rules (offline, private, non-blocking)

Remove anything private from logs and screenshots before posting.

## 11. Advanced topics

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

### Building the app

```bash
pip install -e ".[package]"
scripts/build_macos.sh   # → dist/SmolChat.app
scripts/make_dmg.sh      # → dist/SmolChat-<version>.dmg
```

## License

SmolChat is licensed under Apache-2.0. By contributing, you agree that your contributions are licensed under the same terms.
