import os
from pathlib import Path

import pytest

from app.inference import (
    SMOLVLM_CHAT_FORMAT,
    ChatMessage,
    GenerationParams,
    InferenceEngine,
    InferenceError,
    LoadSpec,
    RuntimeManager,
)


class FakeEngine(InferenceEngine):
    """Records lifecycle calls; used to test RuntimeManager in isolation."""

    log: list[str] = []

    def __init__(self):
        self._id = None

    @property
    def loaded_model_id(self):
        return self._id

    def load(self, spec):
        if spec.model_id == "broken":
            raise InferenceError("cannot load")
        FakeEngine.log.append(f"load:{spec.model_id}")
        self._id = spec.model_id

    def unload(self):
        FakeEngine.log.append(f"unload:{self._id}")
        self._id = None

    def generate(self, messages, params, on_token, should_stop):
        from app.inference import GenerationResult

        out = []
        for word in ["Hello", " from", " ", self._id]:
            if should_stop():
                return GenerationResult("".join(out), len(out), 0.01, stopped=True)
            on_token(word)
            out.append(word)
        return GenerationResult("".join(out), len(out), 0.01)


def spec(model_id):
    return LoadSpec(model_id=model_id, model_path=Path("/dev/null"))


@pytest.fixture
def runtime():
    FakeEngine.log = []
    return RuntimeManager(lambda backend: FakeEngine())


def test_only_one_model_resident_and_switching_unloads(runtime):
    assert runtime.ensure_loaded(spec("a"), "fake") is True
    assert runtime.ensure_loaded(spec("a"), "fake") is False  # already loaded: no-op
    runtime.ensure_loaded(spec("b"), "fake")
    assert FakeEngine.log == ["load:a", "unload:a", "load:b"]
    assert runtime.loaded_model_id == "b"
    runtime.unload()
    assert runtime.loaded_model_id is None


def test_failed_load_leaves_runtime_empty_and_usable(runtime):
    runtime.ensure_loaded(spec("a"), "fake")
    with pytest.raises(InferenceError):
        runtime.ensure_loaded(spec("broken"), "fake")
    assert runtime.loaded_model_id is None
    runtime.ensure_loaded(spec("c"), "fake")
    assert runtime.loaded_model_id == "c"


def test_missing_model_file_suggests_verify_files(tmp_path, monkeypatch):
    import sys
    from unittest.mock import MagicMock

    from app.inference import LlamaCppEngine

    monkeypatch.setitem(sys.modules, "llama_cpp", MagicMock())
    engine = LlamaCppEngine()
    missing_spec = LoadSpec("missing", tmp_path / "does_not_exist.gguf")
    with pytest.raises(InferenceError) as exc_info:
        engine.load(missing_spec)
    assert "missing" in str(exc_info.value).lower()
    assert "Verify files" in str(exc_info.value)


def test_generate_streams_and_stops(runtime):
    with pytest.raises(InferenceError):
        runtime.generate([], GenerationParams(), lambda t: None, lambda: False)
    runtime.ensure_loaded(spec("m"), "fake")
    tokens = []
    result = runtime.generate([ChatMessage("user", "hi")], GenerationParams(), tokens.append, lambda: False)
    assert "".join(tokens) == result.text == "Hello from m"
    assert not runtime.is_generating
    stopped = runtime.generate([], GenerationParams(), tokens.append, lambda: len(tokens) > 5)
    assert stopped.stopped


def test_smolvlm_template_matches_reference_format():
    from jinja2.sandbox import ImmutableSandboxedEnvironment

    template = ImmutableSandboxedEnvironment(trim_blocks=True, lstrip_blocks=True).from_string(
        SMOLVLM_CHAT_FORMAT
    )
    text = template.render(
        messages=[
            {"role": "user", "content": [
                {"type": "image_url", "image_url": {"url": "file:///x.png"}},
                {"type": "text", "text": "What is this?"},
            ]},
            {"role": "assistant", "content": "A cat."},
            {"role": "user", "content": "Thanks"},
        ],
        add_generation_prompt=True,
    )
    # Same shape as Hugging Face's "User:<image>What is this?" – the URL is later
    # swapped for libmtmd's media marker.
    assert text == (
        "<|im_start|>User:file:///x.pngWhat is this?<end_of_utterance>\n"
        "Assistant: A cat.<end_of_utterance>\n"
        "User: Thanks<end_of_utterance>\n"
        "Assistant:"
    )


@pytest.mark.skipif(not os.environ.get("SMOLCHAT_TEST_GGUF"), reason="set SMOLCHAT_TEST_GGUF=/path/model.gguf")
def test_real_llama_cpp_generation():
    """Integration test against a real GGUF (e.g. SmolLM2-135M-Instruct)."""
    from app.inference import LlamaCppEngine

    engine = LlamaCppEngine()
    engine.load(LoadSpec("real", Path(os.environ["SMOLCHAT_TEST_GGUF"]), context_length=1024))
    try:
        pieces = []
        result = engine.generate(
            [ChatMessage("user", "What is the capital of France? Answer in one word.")],
            GenerationParams(temperature=0.0, max_tokens=16),
            pieces.append,
            lambda: False,
        )
        assert result.tokens > 0 and "".join(pieces) == result.text
        assert "paris" in result.text.lower()
    finally:
        engine.unload()
    assert engine.loaded_model_id is None


# ------------------------------------------------- response length vs. context window


class FakeLlama:
    """Stands in for llama_cpp.Llama: one token per word, records the request."""

    def __init__(self):
        self.request = None

    def tokenize(self, data, add_bos=False, special=False):
        return data.decode("utf-8").split()

    def create_chat_completion(self, messages, max_tokens, **kwargs):
        self.request = {"messages": messages, "max_tokens": max_tokens}
        yield {"choices": [{"delta": {"content": "ok"}, "finish_reason": "stop"}]}


def loaded_engine(context_length):
    from app.inference import LlamaCppEngine

    engine = LlamaCppEngine()
    engine._llm = FakeLlama()
    engine._spec = LoadSpec("fake", Path("/dev/null"), context_length=context_length)
    return engine


@pytest.mark.parametrize(
    "max_tokens, context_length, expected",
    [
        (512, 2048, 512),
        (1024, 2048, 1024),
        (2048, 2048, 1024),
        (4096, 2048, 1024),
        (4096, 8192, 4096),
        (1024, 1, 1),
    ],
)
def test_effective_max_tokens_is_at_most_half_the_context(max_tokens, context_length, expected):
    from app.inference import effective_max_tokens

    assert effective_max_tokens(max_tokens, context_length) == expected


@pytest.mark.parametrize("max_tokens", [512, 2048, 4096])
def test_generate_clamps_max_tokens_to_the_loaded_context(max_tokens):
    engine = loaded_engine(context_length=2048)

    result = engine.generate(
        [ChatMessage("user", "hello there")],
        GenerationParams(max_tokens=max_tokens),
        lambda piece: None,
        lambda: False,
    )

    assert result.text == "ok"
    sent = engine._llm.request
    assert sent["max_tokens"] == min(max_tokens, 1024)
    # prompt and reply fit in n_ctx together
    prompt_tokens = sum(len(m["content"].split()) for m in sent["messages"])
    assert prompt_tokens + sent["max_tokens"] <= 2048


def test_fit_context_keeps_history_when_response_length_exceeds_context():
    engine = loaded_engine(context_length=2048)
    history = [
        ChatMessage("user" if i % 2 == 0 else "assistant", " ".join(["word"] * 100))
        for i in range(30)
    ]

    max_tokens = 1024  # what generate() sends for a 4K response length on a 2K model
    payload = engine._fit_context(history, max_tokens)

    # 2048 - 1024 - 64 = 960 tokens for history: several 108-token turns, newest kept
    assert 1 < len(payload) < len(history)
    assert payload[-1]["content"] == history[-1].content
    assert sum(len(m["content"].split()) + 8 for m in payload) <= 960


def test_fit_context_budget_is_never_negative():
    engine = loaded_engine(context_length=2048)
    history = [ChatMessage("user", "a b c"), ChatMessage("assistant", "d e"), ChatMessage("user", "f")]

    # When max_tokens exceeds context_length, budget is clamped to 0 and any message raises
    with pytest.raises(InferenceError) as exc_info:
        engine._fit_context(history, max_tokens=4096)
    assert "too long" in str(exc_info.value).lower()


def test_fit_context_raises_user_friendly_error_when_latest_message_exceeds_budget():
    engine = loaded_engine(context_length=2048)
    # 2048 - 1024 - 64 = 960 tokens budget. A 1000-word message exceeds it.
    over_budget_msg = ChatMessage("user", " ".join(["word"] * 1000))

    with pytest.raises(InferenceError) as exc_info:
        engine._fit_context([over_budget_msg], max_tokens=1024)

    msg = str(exc_info.value)
    assert "fake" in msg  # model_id
    assert "2048" in msg  # context window
    # Explains what to do: shorten, context size, or different model
    assert "shorten" in msg.lower()
    assert "context" in msg.lower()
    assert "model" in msg.lower()


def test_fit_context_raises_when_latest_message_exceeds_budget_with_history():
    engine = loaded_engine(context_length=2048)
    history = [
        ChatMessage("user", "hello"),
        ChatMessage("assistant", "hi there"),
        ChatMessage("user", " ".join(["word"] * 1000)),
    ]

    with pytest.raises(InferenceError) as exc_info:
        engine._fit_context(history, max_tokens=1024)

    msg = str(exc_info.value)
    assert "too long" in msg.lower()
    assert "shorten" in msg.lower()


def test_generate_raises_user_friendly_error_on_over_long_message():
    engine = loaded_engine(context_length=2048)
    # effective_max_tokens will clamp to 1024, leaving 960 tokens for prompt budget.
    over_long = [ChatMessage("user", " ".join(["word"] * 1000))]

    with pytest.raises(InferenceError) as exc_info:
        engine.generate(
            over_long,
            GenerationParams(max_tokens=1024),
            lambda piece: None,
            lambda: False,
        )

    msg = str(exc_info.value)
    assert not msg.startswith("Generation failed:")
    assert "too long" in msg.lower()
    assert "fake" in msg
    assert "2048" in msg
