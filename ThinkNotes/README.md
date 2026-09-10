# ThinkNotes

An overpowered iPad notes app that helps you **think** — not just store text. Write with keyboard, sketch with Apple Pencil, and get real-time hints from a multimodal AI assistant.

## Features

### Core note-taking
- **iPad-native** split view: notes library + editor
- **Keyboard + Apple Pencil** via PencilKit with full tool picker
- **Text / Pencil / Split** pane modes
- **Themes** (Ink, Parchment, Midnight, Forest, Coral) with title + description per note

### Thinking Assistant (the magic)
Real-time, debounced analysis as you type or draw:

| You write… | Assistant helps with… |
|---|---|
| Research topics ("conservatives vs liberals") | Web-sourced summaries, argument angles, counterpoints |
| Equations (`x^2 + 3x = 0`, LaTeX) | Solution strategies, visualization ideas |
| Pseudocode | Structure, edge cases, loop invariants |
| "implementation in Java" | Idiomatic patterns, pitfalls, best approach |
| HLD / architecture sketches | Missing components, wrong arrows, naming nudges |

Hints appear in a side panel — pin the useful ones, dismiss the rest. Analysis is **non-blocking** (700ms debounce on text, 400ms on strokes).

### Offline mode
Without an API key, heuristic hints + DuckDuckGo web snippets still work. Add your key in **Settings** for full multimodal GPT-4o analysis (including vision on canvas snapshots).

## Requirements

- Xcode 15+
- iPad running iOS 17+ (Simulator or device)
- Optional: OpenAI API key for live AI

## Getting started

1. Open `ThinkNotes/ThinkNotes.xcodeproj` in Xcode on a Mac
2. Select an **iPad** simulator or connected iPad
3. Set your **Development Team** in Signing & Capabilities
4. Run (⌘R)
5. Optional: Settings → paste your OpenAI API key

Or set the env var when launching from Xcode:

```
THINKNOTES_API_KEY=sk-...
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  NoteEditorView                                         │
│  ┌──────────────────────┐  ┌─────────────────────────┐  │
│  │ TextEditorPane       │  │ PencilCanvasView        │  │
│  │ (keyboard)           │  │ (Apple Pencil)          │  │
│  └──────────┬───────────┘  └────────────┬────────────┘  │
│             │                           │               │
│             └───────────┬───────────────┘               │
│                         ▼                               │
│                  HintPipeline                           │
│            (debounce + cancel stale)                    │
│                         │                               │
│                         ▼                               │
│               ContentAnalyzer                           │
│         (research/math/code/diagram)                    │
│                         │                               │
│                         ▼                               │
│              AIAssistantService                         │
│     ┌──────────────────┼──────────────────┐           │
│     │                  │                  │           │
│  WebSearch         GPT-4o text       GPT-4o vision     │
│  (DuckDuckGo)                         (canvas PNG)      │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
              AssistantPanelView (hints)
```

### Key files

- `Services/ContentAnalyzer.swift` — detects content type from text + drawing state
- `Services/HintPipeline.swift` — debounced, cancellable real-time pipeline
- `Services/AIAssistantService.swift` — multimodal model + offline fallbacks
- `Components/PencilCanvasView.swift` — PencilKit wrapper with stroke debouncing
- `Components/CanvasSnapshot.swift` — renders strokes to PNG for vision API

## Example workflows

**Debate note:** Create a note titled "Conservatives vs Liberals" with a description of your angle. Start writing bullet points — the assistant fetches web context and suggests definitions, steel-manned counterarguments, and evidence to verify.

**Math:** Type `∫ x² dx` or `2x + 5 = 15` — get strategy hints and visualization suggestions.

**Pseudocode → code:** Write pseudocode, then add a line like `implementation in Java` — the assistant switches to language-specific guidance.

**Diagrams:** Switch to Pencil mode, sketch boxes and arrows. With an API key, the vision model analyzes your HLD and nudges you on architecture mistakes.

## Roadmap ideas

- [ ] Streaming hint tokens (character-by-character)
- [ ] On-device Apple Intelligence fallback
- [ ] Math rendering with MathJax / LaTeX preview
- [ ] Shape recognition (convert rough boxes to clean nodes)
- [ ] iCloud sync
- [ ] Collaborative notes

## License

MIT
