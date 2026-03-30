# Portfolio v2

A ground-up rebuild of the personal portfolio site. Focused on speed, simplicity, and letting the work speak for itself.

## Goals

- **Sub-second load times** — static generation, no client-side framework
- **Minimal design** — black, white, and one accent color
- **Case studies over screenshots** — each project tells a story

## Stack

| Layer | Choice | Reason |
|-------|--------|--------|
| Framework | Astro | Static-first, fast builds |
| Styling | Vanilla CSS | No dependencies, full control |
| Hosting | Vercel | Edge deploy, instant rollbacks |
| CMS | Markdown files | Version controlled, portable |

## Structure

```
src/
  pages/
    index.astro
    about.astro
    work/[slug].astro
  content/
    projects/
      markdown-reader.md
      design-system.md
  styles/
    global.css
    tokens.css
```

## Status

- [x] Design mockups
- [x] Typography and color system
- [ ] Project case study template
- [ ] About page copy
- [ ] Deploy pipeline
