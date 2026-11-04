# PyInstaller spec for SmolChat.app
#   pip install pyinstaller && pyinstaller packaging/SmolChat.spec --noconfirm
# Model weights are NOT bundled; they are downloaded at runtime into
# ~/Library/Application Support/SmolWorks/SmolChat/models.
from pathlib import Path

from PyInstaller.utils.hooks import collect_data_files, collect_dynamic_libs

root = Path(SPECPATH).parent

a = Analysis(
    [str(root / "main.py")],
    pathex=[str(root)],
    binaries=collect_dynamic_libs("llama_cpp"),
    datas=[
        (str(root / "ui"), "ui"),
        (str(root / "resources"), "resources"),
        *collect_data_files("llama_cpp"),
    ],
    hiddenimports=["PySide6.QtSvg", "PySide6.QtQuickControls2"],
    excludes=["tkinter", "PySide6.QtWebEngineCore", "PySide6.QtWebEngineWidgets"],
)
pyz = PYZ(a.pure)
exe = EXE(pyz, a.scripts, [], exclude_binaries=True, name="SmolChat", console=False,
          target_arch="arm64")
coll = COLLECT(exe, a.binaries, a.datas, name="SmolChat")
app = BUNDLE(
    coll,
    name="SmolChat.app",
    icon=str(root / "resources" / "assets" / "SmolChat.icns")
    if (root / "resources" / "assets" / "SmolChat.icns").exists() else None,
    bundle_identifier="com.smolworks.smolchat",
    info_plist={
        "CFBundleName": "SmolChat",
        "CFBundleDisplayName": "SmolChat",
        "CFBundleShortVersionString": "0.1.0",
        "CFBundleVersion": "1",
        "LSMinimumSystemVersion": "13.0",
        "NSHighResolutionCapable": True,
        "NSRequiresAquaSystemAppearance": False,
        "LSApplicationCategoryType": "public.app-category.productivity",
        "NSHumanReadableCopyright": "© SmolWorks",
    },
)
