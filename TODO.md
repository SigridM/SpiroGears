# TODO List

---

# Pending Tasks

## Pending Tasks – High Priority

## Pending Tasks - Medium Priority - Bugs

### ⬜ Intermittent failure to stop (Manual Mode)
**Priority:** Medium (bug)
**Status:** Pending
**Description:** There are times when the drawing fails to stop when it reaches the starting point. This may happen when the finger/cursor wanders outside of the ring. But maybe not. I cannot always replicate this error.

---

## Pending Tasks – Medium Priority - Features


### ⬜ Ending Notch
**Priority:** Medium
**Status:** Pending
**Description:** Give the user a way to specify the ending notch (defaults to the starting notch, meaning, go all the way around). Some of the formulas given for designs in the original spirograph had you start at one notch and end part of the way around to pick up a different color for the next section; e.g., one third of the way around in red, the second third in blue, and the third third in green.
    In manual mode, if the user stops before the end and clicks on the Drawing menu to create a new layer or save the drawing, choose as the ending notch wherever the wheel stopped.

---

### ⬜ Give Hole/Notch maximum
**Priority:** Medium
**Status:** Pending
**Description:** When a user chooses a wheel size, provide a maximum hole number after the words "Hole Number". Likewise, when a user chooses Inner Ring Notches, provide the maximum wheel notches for that ring size.

---

### ⬜ Allow Zoom while drawing (animation)
**Priority:** Medium
**Status:** Pending
**Description:** When drawing using animation, allow the user to pinch to zoom during the animation

---


### ⬜ Choose Multiple Layers as Template
**Priority:** Medium
**Status:** Pending
**Description:** In the Show Layers window, put a checkbox next to each layer so the user can choose more than one as the basis for a new drawing.

--- 

### ⬜ Layer Editing
**Priority:** Medium
**Status:** Pending
**Description** For non-free users only, allow the user to edit any layer in their drawing. (Can't allow this for free users or they'd get more than three drawings total by infinitely editing layers.) Allow these layer editing features: 
    [ ] Reconfigure layer (different sizes, starts, ends, color, etc.)
    [ ] Hide/Show layer (add a "Show Layers" checkbox for which layers are shown so the user can uncheck one or more layers to hide them from the drawing)
    [ ] Rearrange layers (drag them up and down in a list of layers)
    [ ] Delete layer (with undo/redo)

---

### ⬜ Share Button
**Priority:** Medium
**Status:** Pending
**Description:** Allow the user to share any drawing with a "share" button (send to Messages, Facebook, etc.)

---

### ⬜ Redraw
**Priority:** Medium
**Status:** Pending
**Description:** Add a "redraw" option so an entire drawing (all the layers) can be redrawn. This will allow a user to draw the same drawing again with animation on or at a different speed. (This is actually already there if the user saves the drawing; it animates when they open a saved drawing.)

---

## Pending Tasks – Low Priority

### ⬜ Commit the xcshareddata directory
**Priority:** Low
**Status:** Pending
**Description:** `Spirogears.xcodeproj/xcshareddata/xcschemes/Spirogears.xcscheme` is untracked. Shared schemes belong in source control so any team member (or future device) gets the same build configuration.

**Steps:**
```
git add Spirogears.xcodeproj/xcshareddata/
git commit -m "Add shared Xcode scheme"
```

---

### ⬜ Out-of-Bounds Drawing Modes (aka "Ghost Mode")
**Priority:** Low
**Status:** Pending
**Description:** Two "invalid" configurations produce visually interesting results that should become intentional features rather than blocked inputs:

1. **Wheel larger than ring** — when wheel notches ≥ inner ring notches, the wheel draws through and beyond the ring boundary, producing moiré-like patterns larger than the ring. Currently prevented by validation; previously noted that e.g. a 13-notch ring + 120-notch wheel makes beautiful patterns.

2. **Hole number beyond the wheel's physical holes** — selecting a hole number past the wheel's last hole places the pen outside the ring, producing an oversize spirograph pattern.

Both effects are analogous to intentional "rule-breaking" techniques real Spirograph users discovered. They should be surfaced as a deliberate mode (e.g., a toggle or a separate section in the config) rather than a side-effect of entering a number that happens to pass validation. Until then, both remain blocked by the current limit checks.
Calling this "Ghost Mode" because it draws thorugh the ring as if it is a ghost.

---

### ⬜ Choose Stationary Object
**Priority:** Low
**Status:** Pending
**Description:** Add ability to choose which object is stationary and which object moves. E.g., add holes to the rings and allow the ring to circle around the wheel with the "pen" in a ring hole instead of a wheel hole.

---

### ⬜ Allow wheels to go around wheels
**Priority:** Low
**Status:** Pending
**Description:** Once a wheel can be stationary, allow the user to choose another wheel to roll around the outside of the stationary wheel.

---

### ⬜ Allow two or more moving wheels
**Priority:** Low
**Status:** Pending
**Description:** With one wheel, ring or shape stationary, allow two or more wheels that are adjacent to each other, to move, with the pen in one of them.

---

### ⬜ Add Rods
**Priority:** Low
**Status:** Pending
**Description:** The orignal spirograph included two rods (straight sides, curved ends): one with 144 notches, and one with 150 notches. This allowed the user to roll a wheel around a rod to create oblong designs.

---

### ⬜ Rotate Rods
**Priority:** Low
**Status:** Pending
**Description:** Let the user choose to rotate a rod by some number of degrees so that as layers are built up a circular pattern emerges.

---

### ⬜ Rod Rotation Point
**Priorty:** Low
**Status:** Pending
**Description:** Rods normally rotate around their center. Let the user choose a different pivot point for rotation so unusual shapes can be drawn.

---

### ⬜ Shape Add-Ons
**Priority:** Low
**Status:** Pending
**Description:** As in-app purchases, provide other shapes for the wheel to roll around the outside of (or in the inside of, if hollow), besides rods and circles. Some ideas: star, triangle, raindrop, paisley. These should also be allowed to rotate by any chosen rotation point.

---

### ⬜ Draw-Your-Own Shape
**Priority:** Low
**Status:** Pending
**Description:** Let the user buy a bundle of "draw your own shape" options (maybe three at a time?). Once they've saved a shape, they can use it as much as they want, just like other shapes.

---

### ⬜ Color-in Option
**Priority:** Low
**Status:** Pending
**Description:** Either in this app or as a companion app, take drawings made with the gears and saved into a mode (or another app) where the user can apply color to each enclosed area of the drawing (like the paint bucket of drawing tools).

---

### ⬜ Mandala Maker
**Priority:** Low
**Status:** Pending
**Description:** Instead of a simple straight line, let the user choose a shape that gets "stamped" at intervals on the path around the wheel. E.g., a circle, triangle, diamond, paisley, etc. These can be given a starting rotation at the top, and then the shape (if not a circle, obviously) would rotate with the angle of the wheel when the stamp is applied. E.g., if a triangle that is originally pointing up at the top, as it moves 5 degrees around the circle, the triangle rotates by 5 degrees, allowing it to still point at the point tangential to the radius at that point.

# Completed Tasks

### ✅ Port Spirogears from Smalltalk to Swift/SwiftUI
**Priority:** Critical
**Status:** Completed 2026-04-16
**Description:** Full port of the 2005 Smalltalk Spirograph implementation to an iOS SwiftUI app.

**Class structure:**
- `SpiroGuide` — base class; holds `notchSize`
- `SpiroCircle: SpiroGuide` — geometry for any circular piece; computes radii, angles, pen radius
- `SpiroRing: SpiroCircle` — stationary outer ring; uses inner notch measurements
- `SpiroWheel: SpiroCircle` — moving pen gear
- `SpiroLayer` — one drawing pass: ring + wheel + color; contains the core spirograph math in `path(in:)`
- `SpiroDrawing` — ordered collection of layers; manages saved drawings
- `SpiroDialogData` — value type holding parameters for a new layer; factory methods build ring/wheel/layer

**UI:**
- `SpiroCanvas` — `ObservableObject`; renders layers into a `UIImage` buffer (accumulates layers, doesn't redraw all on every frame)
- `SpiroCanvasView` — SwiftUI view displaying the canvas image; pinch-to-zoom with double-tap reset
- `SpiroConfigView` — modal sheet with fields for all 6 layer parameters + `ColorPicker`
- `DrawingMenuView` — sheet-based menu with preset drawings, new/add/undo/redo/save/load actions, and a Show Layers detail view
- `ContentView` — root view; owns drawing state, undo stack, unsaved-change tracking, and wires everything together

**Preset drawings:** Circle (10 layers), Star (9 layers), Triangle (13 layers)

---

### ✅ Pinch-to-zoom on canvas
**Priority:** High
**Status: ** Completed 2026-04-16
**Description:** Added `MagnificationGesture` to `SpiroCanvasView`. Renders into a 2× oversized canvas so content that extends beyond the screen edge is captured. At default zoom the center of the 2× canvas fills the screen, matching the previous appearance. Pinching out reveals the full canvas; pinching in magnifies. Double-tap resets to default zoom.

**Key decisions:**
- `allowsHitTesting(false)` on the `Image` — the 2× layout footprint was absorbing gestures
- `.simultaneousGesture` — prevents conflict with the double-tap recognizer
- `oversizeFactor = 2.0` — enough headroom for all current presets

---

### ✅ Show Layers with "Use as template"
**Priority:** Medium
**Status:** Completed 2026-04-16
**Description:** Drawing menu → Show Layers displays each layer's parameters (outer ring, inner ring, wheel notches, hole, starting notch, color swatch). Each row has a "Use as template" button that clears the canvas, starts a new drawing, and opens the config form pre-filled with that layer's values. Works for presets and saved drawings alike.

---

### ✅ Preset drawings made immutable
**Priority:** Medium
**Status:** Completed  2026-04-16
**Description:** `SpiroDrawing.presetNames` lists the three reserved names (Circle, Star, Triangle). `confirmSave` rejects any attempt to save with a preset name and shows an explanatory alert. "Triangle" was also removed from the initial `_savedDrawings` seed data to eliminate the duplicate.

---

### ✅ "Save before discarding" prompt
**Priority:** High
**Status:** Completed 2026-04-16
**Description:** `ContentView` tracks `isModified` (set when layers are added, undone, or redone; cleared on load or save). When the user chooses a preset, draws new, loads a saved drawing, uses a template, or clears — and there are unsaved changes — a prompt offers Save, Discard, or Cancel. Choosing Save chains into the name-entry alert and then runs the original action after saving.

### ✅ User Preferences
**Priority:** High
**Status:** Completed (2026-04-19)
**Description:** Add a Settings screen (or SwiftUI `.sheet`) for user-configurable options that affect drawing behavior and feedback. Preferences should be persisted via `UserDefaults` or `AppStorage`.

**Settings to include:**
- **Show Gears** (on/off) — overlay a translucent ring and wheel on the canvas while drawing
- **Animate** (on/off) — draw the path incrementally instead of rendering it instantly
- **Animation Speed** (slow / medium / fast, or a slider) — controls how quickly the path is traced when animation is on
- **Manual Drawing** (on/off) — finger/stylus controls the gear hole directly (see separate task); enabling this forces Show Gears on and Animate off
- **Haptics** (on/off) — vibrate once per gear tooth traversed during drawing (see separate task)

**Implementation notes:**
- `AppStorage` property wrappers in a shared `PreferencesStore` observable object, injected via `.environmentObject`
- Manual Drawing requires Show Gears; enforce that dependency in the UI (disable the Show Gears toggle and keep it on when Manual Drawing is on)
- Animation Speed is only relevant when Animate is on; grey it out otherwise

---
### ✅ Show Gears
**Priority:** High
**Status** Completed (2026-04-19)
**Description:** When the Show Gears preference is on, draw a translucent overlay of the stationary ring and the moving wheel on top of the canvas while a layer is being drawn (or always, in Manual Drawing mode).

**Behavior:**
- Ring: a circle outline centered on the canvas, radius = `stationaryGuide.innerRadius`, drawn in a neutral translucent color
- Wheel: a smaller circle outline whose center tracks the correct position along the ring at each step
- Holes: small dots on the wheel at each valid hole position; the active hole is highlighted
- Overlay updates each frame during animation; in Manual Drawing mode it updates as the finger moves

**Implementation notes:**
- Overlay is a SwiftUI `Canvas` or `Path` layer on top of `SpiroCanvasView`, separate from the `UIImage` render buffer
- Gear positions are computed from the same geometry already in `SpiroCircle` / `SpiroRing`

---

### ✅ Remove Outer Notches
**Priority:** High
**Status:** Completed (2026-04-19)
**Description:** The outer notches are not being used and their function will be replaced later by the option to choose a stationary wheel with a moving wheel outside of it, described below.

---

### ✅ Limit Checks
**Prioirity:** High
**Status:** (Completed 2026-04-19 for violations that crash the app; see "Out-of-Bounds Drawing Modes" for possible enhancements)
**Description:** The app will crash if you enter in a negative number of notches anywhere. What about if the wheel is bigger than the ring? What if a number is very, very high? How does that impact performance? May need to constrain some of the numbers to keep it reasonable (whatever "reasonable" turns out to be). (I answered one of my questions: if the wheel is larger than the ring, it draws through the ring as if the ring isn't there and makes a pattern larger than the ring. This is pretty but quite unlike the physical game where the bulk of the ring would keep the pen from going past it -- assuming you could even get a physical wheel larger than a physical ring inside the ring, which you can't. Still, it's interesting. You can get some beautiful moire patterns with a very small ring [e.g., 13 notches] and a very large wheel [e.g., 120 notches]. Perhaps we just need to find a way to make this seem more intentional, rather than a lovely bug.)

---
### ✅ Animation
**Priority:** High
**Status:** Completed (2026-04-19)
**Description:** When the Animate preference is on, trace the spirograph path incrementally rather than rendering all points at once, so the user watches the drawing emerge.

**Behavior:**
- Path is drawn point-by-point (or in small batches for performance) at the rate set by Animation Speed
- Undo/Redo operate on whole layers, not individual frames
- If the user taps the canvas during animation, the drawing completes instantly (skip-to-end)

**Implementation notes:**
- `SpiroLayer.path(in:)` already computes all points; feed them to a `Timer` or `AsyncStream` to stroke incrementally into the `UIGraphicsImageRenderer` buffer
- Batching (e.g., 10–50 points per frame at 60 fps) will look smooth without being too slow
- Speed preference maps to points-per-frame: Slow ≈ 10, Medium ≈ 30, Fast ≈ 100

---

### ✅ Manual Drawing
**Priority:** High
**Status:** Completed (2026-04-23)
**Description:** Allow the user to drive the wheel around the ring with their finger or Apple Pencil, exactly like using a physical Spirograph — but without the gear-skipping frustration. Enabling Manual Drawing forces Show Gears on and Animate off.

**Behavior:**
1. User selects a color and gear configuration via the existing config sheet
2. Canvas shows the ring and wheel overlay (Show Gears)
3. User places their finger anywhere on the wheel; the nearest hole is highlighted and becomes the active pen hole
4. As the user drags, the wheel rolls around the inside of the ring — angle advances proportional to drag distance, constrained to the gear-tooth grid so it never skips
5. The pen path is stroked in real time under the finger
6. Lifting the finger ends the layer (equivalent to completing a drawing pass)

**Updated Behavior:**
1. User selects configuration same as for automatic draw. 
2. Animation defaults to on for manual so the drawing can be shown in real time.
3. User places their finger anywhere on the wheel, but the chosen hole from the configuration is used (it's too hard to select a hole with the finger; they're too small).
4. As the user drags in either direction, the wheel rolls around the inside of the ring.
5. The pen path is stroked in real time under the finger.
6. The layer ends when the user clicks on the Drawing menu; if they lift a finger, but then resume, the drawing resumes.

**Additional Desired Behavior:**
1. Highlight the selected hole in the selected color.
2. Show Gears currently defaults to "On" for Manual Drawing. But after drawing, the user might like to see the drawing unobscured by the gears. Although the gear has to show during the drawing, give the user the option of hiding the gears at any time they are not actively dragging, rather than making them turn off Manual Drawing in order to turn off Show Gears.
3. If the user "backs up" (goes the opposite direction from the one in which they started), erase that part of the drawing.
4. Allow the user to pinch to zoom out mid-drawing.

**Implementation notes:**
- Map drag distance to tooth count: `toothsDragged = dragDistance / notchSize`; advance `stationaryGuide.startingNotch` accordingly
- Constrain wheel angle to integer tooth positions to prevent skipping
- The pen position is computed the same way as `SpiroLayer.path(in:)` — reuse that math per step
- Use `DragGesture` with `.onChanged` for real-time stroke updates and `.onEnded` to finalize the layer
- Hole selection on finger-down: find the hole whose position is closest to the touch point using `penRadius` geometry

---
### ✅ Fix gear clipping on zoom out
**Priority:** High
**Status:** Completed (2026-04-24)
**Description:** Although we fixed clipping on the drawing if a large drawing starts out clipped to the edges of the screen, we did not make the same fix for the wheel and the ring. When zooming out, these get (and stay) clipped to the sides of the original screen.

---

### ✅ Haptics
**Priority:** High
**Status:** Completed (2026-04-24)
**Description:** When the Haptics preference is on, produce a haptic tap for each gear tooth the wheel traverses, giving the user the tactile sensation of a real Spirograph clicking through its teeth.

**Behavior:**
- One light impact (`UIImpactFeedbackGenerator` style `.light` or `.soft`) per tooth
- Fires during animation playback (one tap per rendered step that crosses a tooth boundary) and during manual drawing (one tap per tooth as the finger drags)
- Silent when animation is off and manual drawing is off (since drawing is instant)

**Implementation notes:**
- Prepare a `UIImpactFeedbackGenerator` once and reuse it; calling `prepare()` before a burst reduces latency
- Throttle to at most ~30 haptics/second to avoid feeling like a buzz rather than distinct clicks
- Respect the system mute switch; `UIImpactFeedbackGenerator` does this automatically

---

###  ✅ Highlight Selected Hole
**Priority:** Medium
**Status:** Completed (2026-04-20)
**Description:** Using the color selected for the layer, fill the selected hole with that color so the user can see the selected hole.

---

### ✅ Subscription Model
**Priority:** High
**Status:** Completed (2026-04-25)
**Description:** Monetise Spirogears with a free trial and recurring subscription using StoreKit 2.

**Tiers implemented:**
- **Free** — full access to all drawing features (animation, manual drawing, haptics, presets); up to 3 drawings created (tracked persistently); up to 3 saved drawings; up to 5 layers per drawing
- **Subscribed** — everything in Free, plus unlimited drawings, saves, and layers; 7-day free trial on first subscription
- **Monthly** — $2.99/month
- **Annual** — $29.99/year (~16% off monthly rate)

**Feature gating:**
- Animation, Manual Drawing, and Haptics are **free** — engagement hooks that draw users toward subscribing
- **Subscription-only:** creating more than 3 drawings; saving more than 3 drawings; adding more than 5 layers to a drawing
- Layer editing (hide, delete, rearrange, edit layers) — reserved for subscribers when implemented

**Implementation:**
- `SubscriptionStore` (`@Observable`): fetches products, listens for `Transaction.updates`, publishes `.free`/`.subscribed` entitlement; on-device StoreKit 2 verification
- `PaywallView`: upsell sheet with 7-day trial badge, Monthly/Annual plan picker, purchase and restore; plan labels derived from `subscriptionPeriod.unit` so they work without StoreKit config localizations
- `PaywallRequest` (`Identifiable`): used with `.sheet(item:)` to avoid timing bug where Bool-based sheet captures stale feature-name string
- `Spirogears.storekit`: StoreKit configuration file for local simulator testing (scheme: Run → Options → StoreKit Configuration)
- `drawingsCreated` counter persisted via `@AppStorage`; incremented on Draw New and Use as Template
- Drawing menu items (Add Layer, Undo, Redo, Save) disabled when no drawing is active
- Settings sheet shows **Manage Subscription** button (→ `apps.apple.com/account/subscriptions`) when subscribed, per App Store guideline §3.1.2

---
### ✅ Drawing not centered horizontally
**Prioirty:** Medium (bug)
**Status:** Completed (2026-04-25)
**Description:** The entire drawing (including the ring, when gears are showing) is not centered left-to-right. It is slightly closer to the right edge of the screen than the left.

---
### ✅ Start Drawing at Starting Notch (Manual Mode)
**Priority:** Medium (bug)
**Status:** Pending
**Description:** The user sets the starting notch when they begin a drawing or layer. In manual drawing mode, make sure the line starts there, regardless of where the user first puts down their finger. If their finger is not at the starting location, start at the starting location anyway and quickly catch up to their finger.

---

### ✅ Number pad for Starting Notch
**Priority:** Medium (bug)
**Status:** Completed (2026-04-25)
**Description:** All of the keyboards for the settings for a new drawing are numeric except for Starting Notch, which brings up an alpha keyboard. Starting Notch should also be numeric.

---

### ✅ Inadvertent Drawing Completion 
**Priority:** Medium (bug)
**Status:** Completed (2026-04-25)
**Description:** When playing back a saved drawing with animation on, any touch on the screen stops the animation and the drawing instantly completes, taking the fun away from watching the animation. (Perhaps it would be nice to add a "finish now" feature, but it should be more intentional.) This actually happens during manual drawing mode sometimes, too.

**Fix:** Removed the full-screen `Color.clear` tap-to-skip overlay. Added an explicit "Finish Now" button to the top controls bar that appears only while `canvas.isAnimating`, making skip-to-end a deliberate action.

---

### ✅ Catch up to cursor on resume (Manual Mode)
**Priority:** Medium (bug)
**Status:** Completed (2026-04-25)
**Description:** If the user stops part way through a drawing cycle, then clicks within the ring to resume that layer, the wheel should catch up to where they click (drawing anything it needs to between where it is and where the user clicke). Otherwise, the cursor/finger is out of sync with the wheel.

---

### ✅ Line to edge
**Priority:** Medium
**Status:** Pending
**Description:** for the chosen hole in the wheel, draw a radial line (perpendicular to the tanget) from the hole to the outer edge. Also draw a line at the ring notch 0 as a reference for the user moving the starting notch.

---
