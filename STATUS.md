# Spirogears — Project Status

iOS spirograph drawing app. SwiftUI + UIKit. Simulator target: iPhone 17 / iOS 26.4.
Git repo lives in the `Spirogears/` subdirectory (not the project root).

---

## Architecture

### Data model
| File | Role |
|------|------|
| `SpiroGuide.swift` | Base class. `notchSize = 10.0 pts`. |
| `SpiroCircle.swift` | Adds `outerNotchCircumference`, `storedHoleNumber`, `penRadius`. `invisibleHolesToEdge = 7`. |
| `SpiroRing.swift` | Adds `innerNotchCircumference`, `innerRadius`. Overrides `angleIncrement = 360/innerNotchCircumference`. |
| `SpiroWheel.swift` | Thin subclass of `SpiroCircle`, factory helpers only. |
| `SpiroLayer.swift` | One gear pair + pen color + offset. `stepCount = lcm(ring.notchCircumference, wheel.notchCircumference)`. Owns `point(at:in:)` (spirograph formula) and `path(in:)`. Also stores `drawnFrom`/`drawnTo` for partial manual drawings. |
| `SpiroDrawing.swift` | Ordered array of `SpiroLayer`s. Save/load (in-memory only). Preset factories. |
| `SpiroDialogData.swift` | Transient config struct passed from `SpiroConfigView` to `ContentView`. `lastData` persists last-used settings. |

### Rendering
| File | Role |
|------|------|
| `SpiroCanvas.swift` | `@MainActor ObservableObject`. Owns `renderedImage` (2× oversized `UIImage` accumulator), animation overlay, and manual-drawing overlay. `oversizeFactor = 2.0` so drawings that extend beyond screen edges are captured. |
| `SpiroCanvasView.swift` (in `SpiroCanvas.swift`) | Displays the canvas image at `scaleEffect(scale)`. Handles pinch-to-zoom. Double-tap resets zoom to 1×. |
| `GearOverlay.swift` | `GearOverlayView` — SwiftUI `Canvas` that draws the ring band and rolling wheel on top of the spiral. `OutsideRingOverlayView` — orange tint over the area outside the ring during manual drawing. |

### UI
| File | Role |
|------|------|
| `ContentView.swift` | Root view. Owns canvas, current drawing, undo stack, all modal sheets, and all manual-drawing gesture state. |
| `SpiroConfigView.swift` | Sheet for configuring a new layer (ring notches, wheel notches, hole, color, starting notch). |
| `DrawingMenuView.swift` | Sheet for drawing actions (new, add layer, undo/redo, save, load preset, clear). |
| `SettingsView.swift` | Sheet for app settings (animation toggle, animation speed, manual drawing toggle). |

---

## Key formulas

**Wheel-center position at step `s`:**
```
thetaDeg = ring.angleIncrement * s + ring.originalAngle - 90
```
`ring.angleIncrement = 360 / ring.innerNotchCircumference`
`ring.originalAngle  = ring.angleIncrement * ring.startingNotch`

**Pen position** (in `SpiroLayer.point(at:in:)`):
```
alphaDeg = -wheel.angleIncrement * s + thetaDeg
x = c2c * cos(theta) + penRadius * cos(alpha) + center.x
y = c2c * sin(theta) + penRadius * sin(alpha) + center.y
```

**Center-to-center distance:** `ring.innerRadius - wheel.outerRadius`

---

## Manual drawing — how it works

`manualDrawing` mode (AppStorage toggle) routes new layers through a drag gesture instead of auto-drawing.

### State (all in `ContentView`)
- `manualJumpStep` — absolute step where drawing began (set when direction locks)
- `manualDirection` — `+1` CW, `-1` CCW, `0` not yet set
- `manualAccumulatedNotches` — total notches swept from jump (0 → stepCount)
- `manualPrevTranslation` — previous drag translation, for computing per-frame delta
- `manualDragActive`, `manualCursorOutside` — display state

### Drag handling (three cases)
1. **Outside ring** (`curRadius > ringEdge` where `ringEdge = innerRadius + 30`):
   Accumulate angle, update wheel visually only. No drawing. `manualCursorOutside = true` → orange tint appears.
2. **Re-entry** (`prevRadius > ringEdge && curRadius ≤ ringEdge`):
   Compute cursor's ring-notch position (`reFwd`). Compute forward sweep from `lastRingPos` to `reFwd` in the drawing direction — always non-negative, uses `ring.innerNotchCircumference` (not `stepCount`) as the modulus. Snap accumulator to match. Call `resumeManualDrawing`.
3. **Inside** (normal):
   `deltaAngle = atan2(cross, dot)` of consecutive cursor vectors from ring center. Accumulate, clamped to `[−∞, stepCount]` so forward drawing stops when wheel completes a full cycle. Call `updateManualDrawing`.

### Canvas methods used
- `beginManualDrawing(layer:)` — sets up state
- `jumpManualStep(to:)` — silently repositions start step (called when direction locks)
- `updateManualDrawing(toStep:)` — incremental overlay stroke; triggers `backingUp` erase (≤3-notch retreats absorbed as jitter)
- `updateManualWheelOnly(toStep:)` — moves wheel without drawing (outside-ring)
- `resumeManualDrawing(atStep:)` — forward: extends drawing; backward: repositions `manualLastStep` without erasing
- `endManualDrawing()` — merges overlay into `renderedImage`, stamps `drawnFrom`/`drawnTo` on layer, returns layer

### Partial drawing persistence
`SpiroLayer.drawnFrom` and `drawnTo` record the step range actually drawn. `path(in:)` and `runAnimation` both respect these, so saved/reloaded manually-drawn layers redraw only the drawn portion.

---

## Known SourceKit false positives
SourceKit consistently reports "Cannot find X in scope" for every cross-file type in `ContentView.swift`, `SpiroCanvas.swift`, and `GearOverlay.swift`. These are indexing artifacts — the project builds and runs correctly. They can be ignored.

---

## Recent commits (newest first)
```
f5129ec  Fix outside-ring tint to fill full screen when zoomed out
bcc5e41  Add outside-ring tint feedback during manual drawing
e0f9a61  Fix manual drawing sync when cursor exits and re-enters the ring
282a091  Remove lower clamp on manual drawing accumulator
d2857e5  Remove upper clamp on manual drawing accumulator
16e6250  Don't auto-finalize manual drawing on full rotation
5a4641c  Remove outside-ring accumulation freeze
af5dc68  Fix manual drawing: jump-step accumulator model and outside-ring desync
54efac1  Implement remaining Manual Drawing desired behaviors
05cfd1e  Draw from layer start to jump position when drag direction is locked
c2bb490  Fix gear overlay sync during manual drawing
62f6544  Refine Manual Drawing UX
965189b  Add Manual Drawing mode
413127f  Implement incremental animation for spirograph drawing
```

---

## Pending / not yet done
- `SpiroDrawing` save/load is **in-memory only** — nothing persists across app launches.
- The `drawnFrom`/`drawnTo` fields on `SpiroLayer` are not yet encoded/decoded, so saved drawings lose partial-draw info across sessions (though this is moot until persistence is added).
- No undo within a single manual drawing stroke (only whole-layer undo via the Drawing menu).
