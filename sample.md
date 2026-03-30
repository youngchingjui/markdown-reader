# The Art of Writing

Good writing begins with clarity of thought. Every word should earn its place on the page, every sentence should flow naturally into the next, and every paragraph should build toward something meaningful.

## Prose & Typography

The best typography is invisible — it gets out of the way and lets the words breathe. A well-set page invites the reader in, while a poorly set one pushes them away before they've read a single line.

*"Typography is the craft of endowing human language with a durable visual form."*
— Robert Bringhurst

### The Elements of Style

There are a few principles that every writer should keep close:

1. **Omit needless words.** Vigorous writing is concise. A sentence should contain no unnecessary words, a paragraph no unnecessary sentences.
2. **Use the active voice.** The active voice is direct and vigorous. "The cat sat on the mat" beats "The mat was sat upon by the cat."
3. **Write with nouns and verbs.** Prefer the specific to the general, the definite to the vague, the concrete to the abstract.

### Working with Lists

Sometimes you need to organize thoughts without a particular order:

- Read widely and voraciously
- Write every day, even when you don't feel like it
- Revise ruthlessly — your first draft is never your best
  - Cut anything that doesn't serve the piece
  - Simplify complex sentences
  - Read aloud to catch awkward phrasing
- Share your work and welcome feedback

## Code & Technical Writing

When writing about code, clarity matters even more. Here's a simple example in Swift:

```swift
struct Document {
    let title: String
    let content: String
    let wordCount: Int

    var readingTime: String {
        let minutes = max(1, wordCount / 200)
        return "\(minutes) min read"
    }
}
```

You can also reference code inline — for instance, the `readingTime` property assumes a reading speed of roughly `200` words per minute, which is a reasonable average.

### A Python Example

```python
def word_frequency(text: str) -> dict[str, int]:
    """Count the frequency of each word in the given text."""
    words = text.lower().split()
    frequency = {}
    for word in words:
        clean = word.strip(".,!?;:")
        frequency[clean] = frequency.get(clean, 0) + 1
    return dict(sorted(frequency.items(), key=lambda x: -x[1]))
```

## Comparisons & Data

Tables are useful for presenting structured information clearly:

| Language | Typing | First Appeared | Known For |
|----------|--------|---------------|-----------|
| Python | Dynamic | 1991 | Readability |
| Swift | Static | 2014 | Safety |
| Rust | Static | 2010 | Performance |
| JavaScript | Dynamic | 1995 | Ubiquity |

## Quotations

> "The scariest moment is always just before you start. After that, things can only get better."
> — Stephen King

> "If you want to be a writer, you must do two things above all others: read a lot and write a lot."
> — Stephen King

---

## Formatting Showcase

This paragraph demonstrates **bold text** for emphasis, *italic text* for nuance, and ***bold italic*** when you really mean it. You can also use ~~strikethrough~~ to show revisions. Links like [Markdown Guide](https://www.markdownguide.org) render cleanly inline.

#### A Note on Simplicity

The best tools are the ones you forget you're using. A markdown reader should feel like reading a beautifully typeset book — nothing between you and the words.
