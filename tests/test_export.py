"""Unit tests for app.export — Qt-independent conversation export helpers.

All tests use plain Python objects (simple namespaces / dataclasses) so no
running Qt application, GUI, network connection or actual database is needed.
"""

from __future__ import annotations

import json
import math
import types

from app.export import (
    conversation_to_json,
    conversation_to_markdown,
    default_filename,
)

# ---------------------------------------------------------------------------
# Helpers — build lightweight fake Conversation / Message objects
# ---------------------------------------------------------------------------

def _conv(
    *,
    id: str = "abc123",
    title: str = "Test Chat",
    created_at: float = 1_700_000_000.0,
    updated_at: float = 1_700_000_100.0,
    model_id: str = "",
    model_mode: str = "auto",
    title_is_auto: bool = True,
):
    """Return a simple namespace that mimics app.database.Conversation."""
    return types.SimpleNamespace(
        id=id,
        title=title,
        created_at=created_at,
        updated_at=updated_at,
        model_id=model_id,
        model_mode=model_mode,
        title_is_auto=title_is_auto,
    )


def _msg(
    *,
    id: int = 1,
    conversation_id: str = "abc123",
    role: str = "user",
    content: str = "Hello",
    created_at: float = 1_700_000_050.0,
    model_id: str = "",
    metadata: dict | None = None,
):
    """Return a simple namespace that mimics app.database.Message."""
    return types.SimpleNamespace(
        id=id,
        conversation_id=conversation_id,
        role=role,
        content=content,
        created_at=created_at,
        model_id=model_id,
        metadata=metadata or {},
    )


# ---------------------------------------------------------------------------
# 1. Basic Markdown export
# ---------------------------------------------------------------------------


def test_basic_markdown_export():
    conv = _conv(title="My Chat")
    msgs = [
        _msg(role="user", content="Hi there"),
        _msg(role="assistant", content="Hello!", model_id="smollm3-3b", id=2),
    ]
    md = conversation_to_markdown(conv, msgs)

    assert isinstance(md, str)
    assert "# My Chat" in md
    assert "**You**" in md
    assert "Hi there" in md
    assert "**SmolChat (smollm3-3b)**" in md
    assert "Hello!" in md


# ---------------------------------------------------------------------------
# 2. Basic JSON export
# ---------------------------------------------------------------------------


def test_basic_json_export():
    conv = _conv(title="JSON Chat")
    msgs = [_msg(role="user", content="Ping")]
    output = conversation_to_json(conv, msgs)

    data = json.loads(output)
    assert data["conversation"]["title"] == "JSON Chat"
    assert len(data["messages"]) == 1
    assert data["messages"][0]["content"] == "Ping"


# ---------------------------------------------------------------------------
# 3. Conversation title and timestamps
# ---------------------------------------------------------------------------


def test_title_in_markdown():
    conv = _conv(title="Special Title")
    md = conversation_to_markdown(conv, [])
    assert "# Special Title" in md


def test_created_at_iso_in_markdown():
    conv = _conv(created_at=1_700_000_000.0)
    md = conversation_to_markdown(conv, [])
    # 2023-11-14T22:13:20Z
    assert "2023-11-14T22:13:20Z" in md


def test_timestamps_in_json():
    conv = _conv(created_at=1_700_000_000.0, updated_at=1_700_000_100.0)
    data = json.loads(conversation_to_json(conv, []))
    assert data["conversation"]["created_at"] == 1_700_000_000.0
    assert data["conversation"]["created_at_iso"] == "2023-11-14T22:13:20Z"
    assert data["conversation"]["updated_at"] == 1_700_000_100.0
    assert "updated_at_iso" in data["conversation"]


# ---------------------------------------------------------------------------
# 4. User and assistant message formatting
# ---------------------------------------------------------------------------


def test_user_message_heading():
    conv = _conv()
    msgs = [_msg(role="user", content="A user message")]
    md = conversation_to_markdown(conv, msgs)
    assert "**You**" in md
    assert "A user message" in md


def test_assistant_message_heading_with_model():
    conv = _conv()
    msgs = [_msg(role="assistant", content="An answer", model_id="smollm2-360m")]
    md = conversation_to_markdown(conv, msgs)
    assert "**SmolChat (smollm2-360m)**" in md
    assert "An answer" in md


def test_assistant_message_heading_no_model():
    conv = _conv()
    msgs = [_msg(role="assistant", content="An answer", model_id="")]
    md = conversation_to_markdown(conv, msgs)
    assert "**SmolChat (SmolChat)**" in md


# ---------------------------------------------------------------------------
# 5. Assistant model IDs and names
# ---------------------------------------------------------------------------


def test_model_id_preserved_in_json():
    conv = _conv()
    msgs = [_msg(role="assistant", content="ok", model_id="smollm3-1b")]
    data = json.loads(conversation_to_json(conv, msgs))
    assert data["messages"][0]["model_id"] == "smollm3-1b"


def test_model_id_in_markdown_heading():
    conv = _conv()
    msgs = [_msg(role="assistant", content="ok", model_id="smollm-custom-v2")]
    md = conversation_to_markdown(conv, msgs)
    assert "smollm-custom-v2" in md


# ---------------------------------------------------------------------------
# 6. Multiple messages in chronological order
# ---------------------------------------------------------------------------


def test_multiple_messages_order():
    conv = _conv()
    msgs = [
        _msg(id=1, role="user", content="First", created_at=1_000.0),
        _msg(id=2, role="assistant", content="Second", created_at=2_000.0, model_id="m"),
        _msg(id=3, role="user", content="Third", created_at=3_000.0),
    ]
    md = conversation_to_markdown(conv, msgs)
    pos_first = md.find("First")
    pos_second = md.find("Second")
    pos_third = md.find("Third")
    assert pos_first < pos_second < pos_third


def test_multiple_messages_all_in_json():
    conv = _conv()
    msgs = [
        _msg(id=1, role="user", content="A"),
        _msg(id=2, role="assistant", content="B", model_id="m"),
        _msg(id=3, role="user", content="C"),
    ]
    data = json.loads(conversation_to_json(conv, msgs))
    contents = [m["content"] for m in data["messages"]]
    assert contents == ["A", "B", "C"]


# ---------------------------------------------------------------------------
# 7. Empty conversations
# ---------------------------------------------------------------------------


def test_empty_conversation_markdown():
    conv = _conv(title="Empty")
    md = conversation_to_markdown(conv, [])
    assert "# Empty" in md
    # No user/assistant blocks.
    assert "**You**" not in md
    assert "**SmolChat" not in md


def test_empty_conversation_json():
    conv = _conv(title="Empty")
    data = json.loads(conversation_to_json(conv, []))
    assert data["messages"] == []
    assert data["conversation"]["title"] == "Empty"


# ---------------------------------------------------------------------------
# 8. Code block preservation (Markdown)
# ---------------------------------------------------------------------------


def test_code_block_preserved_in_markdown():
    conv = _conv()
    code = "```python\ndef hello():\n    return 42\n```"
    msgs = [_msg(role="assistant", content=code, model_id="m")]
    md = conversation_to_markdown(conv, msgs)
    assert "```python" in md
    assert "def hello():" in md
    assert "return 42" in md


def test_code_block_preserved_in_json():
    conv = _conv()
    code = "```python\ndef hello():\n    return 42\n```"
    msgs = [_msg(role="assistant", content=code, model_id="m")]
    data = json.loads(conversation_to_json(conv, msgs))
    assert data["messages"][0]["content"] == code


# ---------------------------------------------------------------------------
# 9. <think> reasoning exclusion (Markdown)
# ---------------------------------------------------------------------------


def test_think_block_excluded_from_markdown():
    conv = _conv()
    msgs = [
        _msg(role="assistant", content="<think>secret plan</think>The answer is 42.", model_id="m")
    ]
    md = conversation_to_markdown(conv, msgs)
    assert "secret plan" not in md
    assert "The answer is 42." in md


def test_think_block_at_start_excluded():
    conv = _conv()
    msgs = [
        _msg(role="assistant", content="<think>\nlong reasoning\n</think>\nResponse text.", model_id="m")
    ]
    md = conversation_to_markdown(conv, msgs)
    assert "long reasoning" not in md
    assert "Response text." in md


def test_think_block_preserved_in_json():
    """JSON export keeps the raw content including <think> blocks."""
    conv = _conv()
    raw = "<think>reasoning</think>Answer"
    msgs = [_msg(role="assistant", content=raw, model_id="m")]
    data = json.loads(conversation_to_json(conv, msgs))
    assert data["messages"][0]["content"] == raw


# ---------------------------------------------------------------------------
# 10. Malformed reasoning tags
# ---------------------------------------------------------------------------


def test_unclosed_think_tag_removed_entirely():
    """An unclosed <think> tag should remove everything from the tag onwards."""
    conv = _conv()
    msgs = [_msg(role="assistant", content="<think>still thinking…", model_id="m")]
    md = conversation_to_markdown(conv, msgs)
    assert "still thinking" not in md


def test_multiple_think_blocks():
    """Multiple complete think blocks are all stripped."""
    conv = _conv()
    content = "<think>one</think>Middle<think>two</think>End"
    msgs = [_msg(role="assistant", content=content, model_id="m")]
    md = conversation_to_markdown(conv, msgs)
    assert "one" not in md
    assert "two" not in md
    assert "Middle" in md
    assert "End" in md


def test_think_in_middle_of_content_not_stripped():
    """A <think> tag that is NOT at the start of content is not stripped by
    the segmenter, but our _strip_reasoning removes it regardless of position.
    """
    conv = _conv()
    content = "Some text <think>internal</think> more text"
    msgs = [_msg(role="assistant", content=content, model_id="m")]
    md = conversation_to_markdown(conv, msgs)
    assert "internal" not in md
    assert "Some text" in md
    assert "more text" in md


def test_no_think_tag_content_unchanged():
    conv = _conv()
    content = "Plain response without any think tags."
    msgs = [_msg(role="assistant", content=content, model_id="m")]
    md = conversation_to_markdown(conv, msgs)
    assert content in md


# ---------------------------------------------------------------------------
# 11. Image attachment references
# ---------------------------------------------------------------------------


def test_image_attachment_in_markdown():
    conv = _conv()
    msgs = [
        _msg(
            role="user",
            content="Look at this",
            metadata={"images": ["/home/user/.smolchat/attachments/abc.png"]},
        )
    ]
    md = conversation_to_markdown(conv, msgs)
    assert "abc.png" in md
    # The full internal path must NOT appear.
    assert "/home/user/.smolchat" not in md


def test_image_attachment_in_json():
    conv = _conv()
    meta = {"images": ["/some/path/photo.jpg"]}
    msgs = [_msg(role="user", content="See attached", metadata=meta)]
    data = json.loads(conversation_to_json(conv, msgs))
    assert data["messages"][0]["metadata"]["images"] == ["/some/path/photo.jpg"]


def test_multiple_image_attachments_in_markdown():
    conv = _conv()
    imgs = ["/att/img1.png", "/att/img2.png", "/att/img3.jpg"]
    msgs = [_msg(role="user", content="x", metadata={"images": imgs})]
    md = conversation_to_markdown(conv, msgs)
    assert "img1.png" in md
    assert "img2.png" in md
    assert "img3.jpg" in md


def test_no_attachments_no_attachment_line():
    conv = _conv()
    msgs = [_msg(role="user", content="Just text", metadata={})]
    md = conversation_to_markdown(conv, msgs)
    assert "Attachment" not in md


# ---------------------------------------------------------------------------
# 12. JSON metadata preservation
# ---------------------------------------------------------------------------


def test_json_preserves_message_metadata():
    conv = _conv()
    meta = {"tokens": 42, "tokens_per_second": 15.3, "routed": True}
    msgs = [_msg(role="assistant", content="ok", model_id="m", metadata=meta)]
    data = json.loads(conversation_to_json(conv, msgs))
    stored_meta = data["messages"][0]["metadata"]
    assert stored_meta["tokens"] == 42
    assert math.isclose(stored_meta["tokens_per_second"], 15.3)
    assert stored_meta["routed"] is True


def test_json_preserves_conversation_model_fields():
    conv = _conv(model_id="smollm3-3b", model_mode="manual")
    data = json.loads(conversation_to_json(conv, []))
    assert data["conversation"]["model_id"] == "smollm3-3b"
    assert data["conversation"]["model_mode"] == "manual"


def test_json_includes_export_version():
    data = json.loads(conversation_to_json(_conv(), []))
    assert data["smolchat_export_version"] == 1


def test_json_preserves_message_id_and_role():
    conv = _conv()
    msgs = [_msg(id=99, role="user", content="hi")]
    data = json.loads(conversation_to_json(conv, msgs))
    m = data["messages"][0]
    assert m["id"] == 99
    assert m["role"] == "user"


# ---------------------------------------------------------------------------
# 13. Unicode and special characters
# ---------------------------------------------------------------------------


def test_unicode_title_in_markdown():
    conv = _conv(title="Разговор о Python 🐍")
    md = conversation_to_markdown(conv, [])
    assert "Разговор о Python 🐍" in md


def test_unicode_content_in_markdown():
    conv = _conv()
    msgs = [_msg(role="user", content="héllo wörld — naïve café")]
    md = conversation_to_markdown(conv, msgs)
    assert "héllo wörld — naïve café" in md


def test_unicode_in_json():
    conv = _conv(title="对话")
    msgs = [_msg(role="user", content="你好")]
    output = conversation_to_json(conv, msgs)
    data = json.loads(output)
    assert data["conversation"]["title"] == "对话"
    assert data["messages"][0]["content"] == "你好"
    # ensure_ascii=False: Chinese characters must appear as-is, not escaped.
    assert "\\u" not in output or "你" in output  # loose check


def test_special_chars_in_json_valid():
    conv = _conv(title='Tricky: <>&"\'')
    msgs = [_msg(role="user", content="<div>test</div>")]
    output = conversation_to_json(conv, msgs)
    data = json.loads(output)  # must not raise
    assert data["conversation"]["title"] == 'Tricky: <>&"\''
    assert data["messages"][0]["content"] == "<div>test</div>"


# ---------------------------------------------------------------------------
# 14. Valid JSON output
# ---------------------------------------------------------------------------


def test_output_is_valid_json():
    conv = _conv()
    msgs = [
        _msg(role="user", content="hi", created_at=1_000.0),
        _msg(role="assistant", content="hello", model_id="m", created_at=2_000.0, id=2),
    ]
    output = conversation_to_json(conv, msgs)
    data = json.loads(output)  # must not raise
    assert isinstance(data, dict)


def test_json_indentation():
    output = conversation_to_json(_conv(), [])
    # Pretty-printed: each line of the top-level object is indented 2 spaces.
    assert '  "conversation"' in output


def test_json_utf8_encoded():
    output = conversation_to_json(_conv(title="日本語"), [])
    encoded = output.encode("utf-8")
    decoded = encoded.decode("utf-8")
    assert "日本語" in decoded


# ---------------------------------------------------------------------------
# 15. default_filename helper
# ---------------------------------------------------------------------------


def test_default_filename_md():
    conv = _conv(title="My Great Chat")
    assert default_filename(conv, "md") == "My-Great-Chat.md"


def test_default_filename_json():
    conv = _conv(title="My Great Chat")
    assert default_filename(conv, "json") == "My-Great-Chat.json"


def test_default_filename_special_chars():
    conv = _conv(title="Chat: <Q&A> (2024)")
    fname = default_filename(conv, "md")
    # Must not contain shell-special characters like < > & ( )
    assert "<" not in fname
    assert ">" not in fname
    assert "&" not in fname
    assert fname.endswith(".md")


def test_default_filename_empty_title():
    conv = _conv(title="")
    assert default_filename(conv, "md") == "conversation.md"


# ---------------------------------------------------------------------------
# 16. System messages skipped
# ---------------------------------------------------------------------------


def test_system_messages_excluded_from_markdown():
    conv = _conv()
    msgs = [
        _msg(role="system", content="You are a helpful assistant."),
        _msg(role="user", content="Hello"),
    ]
    md = conversation_to_markdown(conv, msgs)
    assert "You are a helpful assistant." not in md
    assert "Hello" in md


def test_system_messages_included_in_json():
    """JSON is a faithful archive — system messages are kept."""
    conv = _conv()
    msgs = [
        _msg(role="system", content="system prompt here"),
        _msg(role="user", content="hi"),
    ]
    data = json.loads(conversation_to_json(conv, msgs))
    roles = [m["role"] for m in data["messages"]]
    assert "system" in roles
