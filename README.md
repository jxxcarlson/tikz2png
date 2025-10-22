# TikZ to PNG Converter

A web-based TikZ editor with real-time PNG rendering. Edit TikZ code in your browser and see the rendered output instantly.

## Features


- **Files**: Create, import, and save TikZ files with localStorage persistence
- **Live rendering**: Automatic rendering on file selection + manual render button
- **File format**: Handles both raw TikZ code and full LaTeX documents
- **Example files**: Three starter examples (graph, complete-graph, spheres, lindenmayer)

## Quick Start

### Build

```bash
elm make src/Main.elm --output=main.js
```

### Run

Open `app.html` in your browser. The app requires a backend server running at `http://localhost:3000/tikz2png` (or configure the URL in `src/Main.elm`).

### Server Endpoint

The app expects a POST endpoint that accepts:

```json
{
  "name": "filename",
  "content": "\\begin{tikzpicture}...",
  "preamble": "\\usetikzlibrary{...}"
}
```

And returns:

```json
{
  "name": "filename",
  "url": "path/to/generated.png"
}
```

Or on error:

```json
{
  "name": "filename",
  "errorMsg": "Error description"
}
```

## Project Structure

```
src/
  Main.elm              - Main application logic
  Data.elm              - Initial example TikZ files
  LatexToTikzJson.elm   - LaTeX/TikZ parser and JSON encoder
  app.html              - HTML with localStorage port integration
  elm.json              - Elm dependencies
```

## Tech Stack

- Elm 0.19.1
- elm/file for file operations
- JavaScript ports for localStorage persistence

## Usage

1. **New File**: Click "New File" to start with a blank editor
2. **Import**: Click "Import File" to load a `.tikz` file from your computer
3. **Edit**: Type or paste TikZ code in the editor
4. **Render**: Click "Render" to generate PNG (or select a file from the list for auto-render)
5. **Save**: Click "Save File" to download and persist to localStorage

## License

MIT
