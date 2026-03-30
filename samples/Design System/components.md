# Components

Reusable building blocks for the interface.

## Sidebar

The sidebar is the primary navigation surface. It displays workspace folders as expandable sections, each containing a tree of markdown files.

- Folder headers show the folder name with a folder icon
- Files are listed alphabetically within each folder
- Nested directories appear as collapsible groups
- The active file is highlighted with the accent color

## Content View

The main reading area renders markdown as richly styled attributed text.

### Layout

- Content width is capped at **600pt** for comfortable reading
- Horizontal padding of **80pt** on each side centers the text
- Vertical scrolling with a subtle overlay scrollbar

### Text Rendering

All text is rendered via `NSAttributedString` into an `NSTextView`. This gives us:

- **Pixel-perfect typography** — kerning, ligatures, and line spacing handled by Core Text
- **Clickable links** — inline links open in the default browser
- **Selectable text** — readers can copy passages freely

## Quick Open

A modal overlay triggered by `Cmd+P`:

1. Type to fuzzy-search across all workspace files
2. Arrow keys to navigate results
3. Enter to open, Escape to dismiss

Results are ranked by match quality, with filename matches weighted higher than path matches.

## Toolbar

Minimal by design — two buttons:

- **Open** — import a single markdown file
- **Quick Open** — launch the fuzzy search overlay
