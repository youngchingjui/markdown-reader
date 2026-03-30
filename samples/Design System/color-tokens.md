# Color Tokens

A minimal palette that adapts to light and dark mode.

## Core Palette

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `background` | #FFFFFF | #1C1C1E | Page background |
| `surface` | #F5F5F7 | #2C2C2E | Cards, sidebar |
| `text-primary` | #1D1D1F | #F5F5F7 | Body text |
| `text-secondary` | #6E6E73 | #98989D | Captions, labels |
| `accent` | #0071E3 | #2997FF | Links, selections |
| `code-bg` | #F0F0F2 | #323236 | Code block fill |
| `border` | #D2D2D7 | #48484A | Dividers, rules |

## Guidelines

- **Never hardcode hex values.** Always reference tokens so themes propagate automatically.
- **Accent color is for interaction only.** Links, buttons, and selections — nothing else.
- Use `text-secondary` for supporting information that shouldn't compete with body text.

## Dark Mode

The system appearance drives everything. We don't offer a manual toggle — we respect the user's OS preference.

```swift
let textColor = NSColor.labelColor       // adapts automatically
let bgColor = NSColor.textBackgroundColor // adapts automatically
```
