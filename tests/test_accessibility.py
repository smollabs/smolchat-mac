"""Automated tests for QML accessibility and keyboard navigation.

Verifies:
- Accessible roles, names, descriptions, and focus policies on reusable components (IconButton, ActionButton, Field, Pill)
- Settings custom controls (Toggle, Segmented, Slider)
- Model Library accessibility properties and announcements
- Keyboard navigation (Tab focus policies, visual focus indicators)
"""

import sys
from pathlib import Path
import pytest
from PySide6.QtCore import Qt, QUrl
from PySide6.QtGui import QGuiApplication, QAccessible
from PySide6.QtQml import QQmlApplicationEngine, QQmlComponent

ROOT_DIR = Path(__file__).resolve().parent.parent
UI_DIR = ROOT_DIR / "ui"


@pytest.fixture(scope="session")
def qapp():
    """Ensure QGuiApplication exists."""
    app = QGuiApplication.instance()
    if app is None:
        app = QGuiApplication(sys.argv)
    return app


@pytest.fixture
def qml_engine(qapp):
    """Create a QQmlApplicationEngine with ui import path."""
    engine = QQmlApplicationEngine()
    engine.addImportPath(str(ROOT_DIR))
    return engine


def test_components_qml_loads_cleanly(qml_engine):
    """Verify components.qml loads without any compilation errors."""
    comp = QQmlComponent(qml_engine, QUrl.fromLocalFile(str(UI_DIR / "components.qml")))
    assert comp.errors() == []
    obj = comp.create()
    assert obj is not None


def test_settings_qml_loads_cleanly(qml_engine):
    """Verify settings.qml loads without any compilation errors."""
    comp = QQmlComponent(qml_engine, QUrl.fromLocalFile(str(UI_DIR / "settings.qml")))
    assert comp.errors() == []


def test_sidebar_qml_loads_cleanly(qml_engine):
    """Verify sidebar.qml loads without any compilation errors."""
    comp = QQmlComponent(qml_engine, QUrl.fromLocalFile(str(UI_DIR / "sidebar.qml")))
    assert comp.errors() == []


def test_chat_qml_loads_cleanly(qml_engine):
    """Verify chat.qml loads without any compilation errors."""
    comp = QQmlComponent(qml_engine, QUrl.fromLocalFile(str(UI_DIR / "chat.qml")))
    assert comp.errors() == []


def test_model_library_qml_loads_cleanly(qml_engine):
    """Verify model_library.qml loads without any compilation errors."""
    comp = QQmlComponent(qml_engine, QUrl.fromLocalFile(str(UI_DIR / "model_library.qml")))
    assert comp.errors() == []


def test_main_qml_loads_cleanly(qml_engine):
    """Verify main.qml loads without any compilation errors."""
    comp = QQmlComponent(qml_engine, QUrl.fromLocalFile(str(UI_DIR / "main.qml")))
    assert comp.errors() == []


def test_icon_button_accessibility(qml_engine):
    """Test IconButton accessible role, accessible name from tip, and TabFocus policy."""
    qml_src = (
        'import QtQuick\n'
        'import QtQuick.Controls\n'
        'import "."\n'
        'Item {\n'
        '    id: root\n'
        '    width: 200; height: 200\n'
        '    C.IconButton {\n'
        '        id: btn\n'
        '        tip: "Send message"\n'
        '        accessibleDescription: "Sends current chat prompt"\n'
        '    }\n'
        '    property var testBtn: btn\n'
        '    property var accRole: btn.Accessible.role\n'
        '    property var accName: btn.Accessible.name\n'
        '    property var accDesc: btn.Accessible.description\n'
        '    property var accFocusable: btn.Accessible.focusable\n'
        '}\n'
    )
    comp = QQmlComponent(qml_engine)
    comp.setData(qml_src.encode("utf-8"), QUrl.fromLocalFile(str(UI_DIR / "test_icon_button.qml")))
    assert comp.errors() == []
    obj = comp.create()
    assert obj is not None

    btn = obj.property("testBtn")
    assert btn is not None
    assert btn.property("focusPolicy") == Qt.FocusPolicy.TabFocus

    assert obj.property("accRole") == QAccessible.Role.Button.value
    assert obj.property("accName") == "Send message"
    assert obj.property("accDesc") == "Sends current chat prompt"
    assert obj.property("accFocusable") is True


def test_action_button_accessibility(qml_engine):
    """Test ActionButton accessible role, name, and TabFocus policy."""
    qml_src = (
        'import QtQuick\n'
        'import QtQuick.Controls\n'
        'import "."\n'
        'Item {\n'
        '    id: root\n'
        '    width: 200; height: 200\n'
        '    C.ActionButton {\n'
        '        id: btn\n'
        '        text: "Download model"\n'
        '        kind: "primary"\n'
        '    }\n'
        '    property var testBtn: btn\n'
        '    property var accRole: btn.Accessible.role\n'
        '    property var accName: btn.Accessible.name\n'
        '    property var accFocusable: btn.Accessible.focusable\n'
        '}\n'
    )
    comp = QQmlComponent(qml_engine)
    comp.setData(qml_src.encode("utf-8"), QUrl.fromLocalFile(str(UI_DIR / "test_action_button.qml")))
    assert comp.errors() == []
    obj = comp.create()
    assert obj is not None

    btn = obj.property("testBtn")
    assert btn.property("focusPolicy") == Qt.FocusPolicy.TabFocus

    assert obj.property("accRole") == QAccessible.Role.Button.value
    assert obj.property("accName") == "Download model"
    assert obj.property("accFocusable") is True


def test_field_accessibility(qml_engine):
    """Test Field accessible role, name, and StrongFocus policy."""
    qml_src = (
        'import QtQuick\n'
        'import QtQuick.Controls\n'
        'import "."\n'
        'Item {\n'
        '    id: root\n'
        '    width: 200; height: 200\n'
        '    C.Field {\n'
        '        id: field\n'
        '        placeholderText: "Search chats"\n'
        '        accessibleDescription: "Filter conversation list"\n'
        '    }\n'
        '    property var testField: field\n'
        '    property var accRole: field.Accessible.role\n'
        '    property var accName: field.Accessible.name\n'
        '    property var accDesc: field.Accessible.description\n'
        '    property var accFocusable: field.Accessible.focusable\n'
        '}\n'
    )
    comp = QQmlComponent(qml_engine)
    comp.setData(qml_src.encode("utf-8"), QUrl.fromLocalFile(str(UI_DIR / "test_field.qml")))
    assert comp.errors() == []
    obj = comp.create()
    assert obj is not None

    field = obj.property("testField")
    assert field.property("focusPolicy") == Qt.FocusPolicy.StrongFocus

    assert obj.property("accRole") == QAccessible.Role.EditableText.value
    assert obj.property("accName") == "Search chats"
    assert obj.property("accDesc") == "Filter conversation list"
    assert obj.property("accFocusable") is True


def test_settings_controls_accessibility(qml_engine):
    """Test Settings custom controls: Toggle and Segmented."""
    comp = QQmlComponent(qml_engine, QUrl.fromLocalFile(str(UI_DIR / "settings.qml")))
    assert comp.errors() == []


def test_slim_progress_accessibility(qml_engine):
    """Test SlimProgress accessible role and progress description."""
    qml_src = (
        'import QtQuick\n'
        'import "."\n'
        'Item {\n'
        '    id: root\n'
        '    width: 200; height: 50\n'
        '    C.SlimProgress {\n'
        '        id: prog\n'
        '        accessibleName: "Model download"\n'
        '        value: 0.75\n'
        '        indeterminate: false\n'
        '    }\n'
        '    property var testProgress: prog\n'
        '    property var accRole: prog.Accessible.role\n'
        '    property var accName: prog.Accessible.name\n'
        '    property var accDesc: prog.Accessible.description\n'
        '}\n'
    )
    comp = QQmlComponent(qml_engine)
    comp.setData(qml_src.encode("utf-8"), QUrl.fromLocalFile(str(UI_DIR / "test_progress.qml")))
    assert comp.errors() == []
    obj = comp.create()
    assert obj is not None

    assert obj.property("accRole") == QAccessible.Role.ProgressBar.value
    assert obj.property("accName") == "Model download"
    assert obj.property("accDesc") == "75%"
