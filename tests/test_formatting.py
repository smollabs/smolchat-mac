import pytest

from app.formatting import DARK_SYNTAX, highlight, segment_message


@pytest.mark.parametrize("language", [
    "html", "xml", "css", "scss", "yaml", "yml",
    "toml", "md", "markdown", "diff", "dockerfile",
    "ini", "rb", "ruby", "php", "lua", "r",
])
def test_requested_languages_are_recognized(language):
    rendered = highlight(
        "if value < 10:\n    return value",
        language,
        DARK_SYNTAX,
    )
    assert rendered
    assert "&lt;" in rendered or language in {
        "diff", "dockerfile", "ini", "markdown", "md"
    }


@pytest.mark.parametrize("fence,language", [
    ("~~~", "python"),
    ("````", "python"),
    ("   ```", "python"),
])
def test_supported_fence_styles(fence, language):
    message = f"{fence}{language}\nprint(1)\n{fence}\n"

    segments = segment_message(message)

    assert len(segments) == 1
    assert segments[0]["kind"] == "code"
    assert segments[0]["lang"] == language
    assert segments[0]["text"] == "print(1)"
    assert segments[0]["open"] is False


def test_shorter_nested_fence_does_not_close_outer_fence():
    message = "````python\n```\nprint(1)\n````\n"

    segments = segment_message(message)

    assert len(segments) == 1
    assert segments[0]["text"] == "```\nprint(1)"


def test_diff_additions_and_removals_use_existing_palette():
    rendered = highlight(
        "+added\n-removed\n unchanged",
        "diff",
        DARK_SYNTAX,
    )

    assert f'color:{DARK_SYNTAX["keyword"]}' in rendered
    assert f'color:{DARK_SYNTAX["comment"]}' in rendered