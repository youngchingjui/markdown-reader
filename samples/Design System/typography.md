# Typography

Our type system is built on clarity and rhythm. Every scale step serves a purpose.

## Type Scale

| Role | Size | Weight | Font |
|------|------|--------|------|
| Display | 36px | Bold | Serif |
| Heading 1 | 28px | Semibold | Serif |
| Heading 2 | 22px | Semibold | Serif |
| Body | 17px | Regular | Serif |
| Caption | 14px | Regular | Sans-serif |
| Code | 14px | Regular | Monospace |

## Principles

1. **Hierarchy through size, not decoration.** Avoid underlines, all-caps, or color to establish hierarchy. Size and weight do the work.
2. **Generous line height.** Body text uses 1.6x line height. Headings use 1.3x. Code uses 1.45x.
3. **Consistent vertical rhythm.** Spacing between elements follows a 4px baseline grid.

## Usage

Body text should sit comfortably at `17px` on desktop. On compact displays, scale down to `15px` but never below — readability is non-negotiable.

> "Typography is what language looks like."
> — Ellen Lupton

For code samples, always use a monospace font with slightly tighter line height:

```swift
let bodyFont = NSFont(name: "Georgia", size: 17)
let codeFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
```
