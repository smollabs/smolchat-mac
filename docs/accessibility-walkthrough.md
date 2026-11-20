# SmolChat VoiceOver and Keyboard Accessibility Walkthrough

This document outlines the accessibility structure, keyboard interaction model, and manual VoiceOver verification procedures for the SmolChat macOS application.

> [!NOTE]
> Verification environment notice: Automated Qt accessibility unit tests run directly against PySide6's accessibility tree and QML properties (`tests/test_accessibility.py`). Manual VoiceOver verification procedures below are documented for macOS (`Command + F5`). In Windows or non-macOS development environments, live VoiceOver execution remains unverified on host hardware and should be confirmed on macOS.

---

## 1. Enabling VoiceOver on macOS

- **Toggle VoiceOver**: Press `Command + F5` (or triple-click Touch ID / power button on Apple Silicon MacBooks).
- **VoiceOver Modifier Key (VO)**: `Control + Option` (or `Caps Lock` if configured).
- **VoiceOver Cursor Navigation**: Use `VO + Left Arrow` / `VO + Right Arrow`.
- **Activate Element**: `VO + Space` or `Return` / `Space`.
- **Keyboard Tab Navigation**: Press `Tab` to advance focus and `Shift + Tab` to move backwards.
- **macOS Full Keyboard Access**: Ensure *System Settings > Keyboard > Keyboard navigation* is toggled ON to allow Tab navigation across all controls.

---

## 2. Navigating the Sidebar

1. **Title Bar Controls**:
   - The collapse sidebar button is keyboard-focusable with `Tab`.
   - VoiceOver announces: *"Hide sidebar, Button, Collapse sidebar navigation (Command+\\)"*.
2. **New Chat Action**:
   - Reachable via `Tab` or shortcut `Command + N`.
   - VoiceOver announces: *"New chat, Button, Start a new conversation (Command+N)"*.
   - Activates with `Space` or `Return`.
3. **Search Field**:
   - Accessible role: `EditableText`.
   - Accessible name: *"Search chats"*.
   - Description: *"Filter conversations by keyword"*.
   - Can be activated directly via `Ctrl+K` / `Command+K`. Pressing `Escape` clears search and restores normal view.

---

## 3. Conversation List & Context Actions

1. **Conversation History List**:
   - Exposes accessible role `List` named *"Conversations"*.
   - Each item in the list exposes accessible role `ListItem` with the chat title.
2. **Conversation Item**:
   - Keyboard users can Tab to the conversation button, showing a clear visual focus border.
   - VoiceOver announces: *"[Title], Button, Open conversation [Title]"*.
   - Pressing `Return` or `Space` opens the selected conversation.
3. **Options Button**:
   - Tabbing onto the conversation row exposes the "Options" button.
   - VoiceOver announces: *"Options for [Title], Button, Open menu to rename or delete this conversation"*.
   - Pressing `Return` opens the popup menu for "Rename" and "Delete".

---

## 4. Sidebar Bottom Status & Settings

1. **Model Library Status Button**:
   - Focusable via `Tab`.
   - VoiceOver announces current model or download state (e.g., *"Model Library status: Ready, Button, Click to open Model Library"* or *"Model Library status: SmolLM2-135M-Instruct, Button"*).
2. **Theme Switch Button**:
   - VoiceOver announces: *"Switch to light theme / Switch to dark theme, Button, Toggle application appearance between light and dark (Shift+Command+L)"*.
3. **Settings Button**:
   - VoiceOver announces: *"Settings, Button, Open application settings dialog (Command+,)"*.

---

## 5. Main Stage & Chat View

1. **Model Selector Pill**:
   - VoiceOver announces: *"Model selector: Auto, Button, Choose between automatic routing or a specific downloaded model"*.
   - When opened, exposes `RadioButton` items for "Auto" and downloaded models with selected states.
2. **On-Device Status**:
   - Exposes static status: *"On-device model status: Loaded in memory"* or *"Generating response"*.
3. **Chat Messages**:
   - Message blocks provide accessible text.
   - Action buttons such as "Copy message text" and "Regenerate response" are focusable via keyboard with clear focus indicators.
   - Code blocks expose copy buttons announced as *"Copy [language] code"*.
   - Model reasoning blocks expose an expand/collapse toggle announced as *"Expand thought process / Collapse thought process, Button"*.

---

## 6. Chat Input & Composer Controls

1. **Message Input**:
   - Role: `EditableText`.
   - Name: *"Message input"*.
   - Description: *"Compose a message to send to the model. Press Return to send, Shift+Return for a new line."*.
   - Clear focus glow and border around the input area.
2. **Attach Button**:
   - Role: `Button`, Name: *"Attach"*, Description: *"Attach images to your message"*.
3. **Send / Stop Button**:
   - Dynamically adapts:
     - When idle: Role `Button`, Name: *"Send message"*, Description: *"Send message to the model (Return)"*.
     - When generating: Role `Button`, Name: *"Stop generating"*, Description: *"Stop generating model response (Command+.)"*.
   - Visual focus ring appears around the send button when reached via `Tab`.

---

## 7. Model Library Navigation & Progress Updates

1. **Dialog Accessibility**:
   - Opened via `Command+Shift+M` or Sidebar status button.
   - Role: `Dialog`, Name: *"Model Library"*.
2. **Category Filter Tabs**:
   - Role: `PageTabList` with `PageTab` options ("All", "Recommended", "Downloaded", "Text & Chat", "Vision", etc.).
   - VoiceOver announces selected state.
3. **Model Rows**:
   - Each model item has Role `ListItem` named `[Model Name], [Installed / Compatibility Label]`.
   - Description provides the model summary and download status.
4. **Download Progress Announcements**:
   - `SlimProgress` exposes role `ProgressBar` with percentage value.
   - Meaningful state updates trigger `Accessible.announce(..., Accessible.Polite)` upon download completion, avoiding noisy per-frame announcements.
5. **Action Buttons**:
   - "Download [Model Name]" (`primary`), "Resume download", "Cancel download", "Use [Model Name] in this chat", "Delete [Model Name]".
   - Each has descriptive `accessibleName` and `accessibleDescription`.

---

## 8. Settings Dialog & Custom Controls

1. **Dialog Root**:
   - Role: `Dialog`, Name: *"Settings"*. Focus is kept inside dialog while open. Pressing `Escape` closes the dialog.
2. **Theme Selection**:
   - Radio buttons for System, Light, and Dark themes. Visual focus border highlights each option when tabbed to.
3. **Accent Colour Swatches**:
   - Each accent swatch has Role `RadioButton`, Name: *"[Colour] accent"*, Checked state, and full Tab focus support.
4. **Toggle Switches**:
   - Custom `Switch` component has Role `Switch`, `Accessible.checkable: true`, and announces checked/unchecked state accurately.
   - Focus ring displays around switch track when focused.
5. **Segmented Controls**:
   - Role `PageTabList` containing `PageTab` buttons.
   - Supports Left/Right arrow keys to switch between options.
6. **Sliders (Temperature)**:
   - Role `Slider`, Name: *"Temperature"*, Description with current value (e.g. *"Value 0.7. Lower is more focused, higher is more creative."*).
   - Up/Right arrow increases value, Down/Left arrow decreases value.
7. **System Prompt**:
   - Role `EditableText`, Name: *"System prompt"*.

---

## 9. Keyboard Navigation Summary

| Action / Shortcut | Target | Behaviour |
| :--- | :--- | :--- |
| `Tab` | Next focusable control | Advances keyboard focus in logical DOM order |
| `Shift + Tab` | Previous control | Moves keyboard focus backwards |
| `Return` / `Space` | Buttons / Toggles / Tabs | Activates focused control |
| `Left` / `Right` Arrow | Segmented controls, Sliders | Changes active option or slider value |
| `Escape` | Dialogs / Popups / Search | Closes active popup/dialog, clears search |
| `Command + N` | New Chat | Starts a fresh conversation |
| `Command + K` | Search | Focuses sidebar search field |
| `Command + \` | Sidebar | Toggles sidebar visibility |
| `Command + ,` | Settings | Opens Settings dialog |
| `Shift + Command + L` | Theme | Toggles Dark / Light mode |
| `Command + .` | Stop Generating | Stops in-flight token stream |

---

## 10. Focus Ring & Visual Verification

- **Theme Consistency**: Focus indicators use `Theme.brand` for primary accent contrast and `Theme.accent` where contrast against brand backgrounds is needed.
- **Light & Dark Themes**: Focus rings have been checked to provide high contrast against both `Theme.panel` (#0a0817 in dark / #fcfbff in light) and `Theme.surface` backgrounds.
- **Only on Keyboard Focus**: All focus rings rely on `visualFocus` or `activeFocus`, meaning mouse clicks and touches do not leave persistent rings.
- **Preserved Existing Styling**: All original dimensions, border radii, padding, animations, hover states, and pressed states remain intact.
