# ZeroDock design system

ZeroDock is a landscape dashboard read from a desk stand. The bar to beat is StandBy: calm,
symmetric, readable from a distance. These rules exist so that a new screen cannot drift off the
grid by accident. They are enforced by `Scripts/design-lint.sh` (run by `Scripts/check-source.sh`)
and by `testLayoutIsSymmetricAndAligned` in `UITests/ZeroDockUITests.swift`.

All numbers live in `Core/DesignSystem/DockLayout.swift` (space, size, radius) and
`Core/DesignSystem/DockTheme.swift` (color, type). Views never write raw numbers.

## Rules

1. **One canvas, one axis.** Margins are mirrored (the larger safe-area inset is applied to both
   sides), so the canvas is centred on the physical screen, not on the safe area. The mode switcher
   sits exactly on the centre axis. Everything else hangs off it.
2. **Two equal halves.** Content is split into two halves of identical width and height with a
   24 pt gutter (`DockHalves`). Wider rows (the Gaming strip) are four equal columns whose middle
   divider lands on the same axis as the gutter.
3. **8 pt unit.** `unit` 8, `tight` 8, `gap` 16, `pad` 16, `margin`/`gutter` 24. Nothing is
   spaced by eye.
4. **Two layers.** The content layer (cards) is flat: faint fill, hairline edge, no gradient and no
   shadow (`contentCard`). The control layer (things you press) is glass (`GlassBackground`).
   Glass is never used on content.
5. **Concentric corners.** Outer card radius 32; anything inset by `pad` inside it uses
   `innerRadius` (32 - 16 = 16). Controls are capsules or circles only.
6. **Same level, same size.** Controls at the same level share one height: 48 (`control`) in the
   top bar and for secondary actions, 56 (`controlLarge`) for the main action and its siblings.
   Minimum hit region is 44 pt in both directions.
7. **One prominent action per screen.** Only the main button gets the accent gradient.
   `AccentButton` is that button.
8. **Press feedback everywhere.** Every custom control uses `PressableStyle`.
9. **Type for distance.** Assumed viewing distance is about 60 cm, roughly 1.6x a handheld
   distance (an estimate, to be checked on the stand). Nothing is below 18 pt. Scale: caption 18,
   label 18 bold, control 20, body 22, heading 30, title 40, numerals 56 to 128 in the display face.
   Thin weights go larger, never smaller.
10. **Less, not more.** Prefer removing a line of copy to shrinking it.

## Layout reference (landscape iPhone, 874 x 402 pt)

```
 margin | time/date  battery |     [ switcher ]     | music  gear | margin
        +-------------------------- gap 16 ---------------------------+
        |            left half            gutter 24        right half |
        |  Focus:  ring (side x side)                 heading         |
        |                                              presets (3)    |
        |                                              Start + reset  |
        |  Gaming: game card                          session card    |
        |  Gaming: [ status | FPS | Frame time | GPU time ] strip     |
```

Ambient has no halves: the clock is centred on the screen both ways and the top bar fades to 40%.

## What the tests measure

- Switcher centred within 1.5 pt of the screen axis in every mode.
- Halves: equal width and height, shared top edge, equal side margins, gutter on the axis.
- Focus: ring and controls share a width and a vertical centre, each centred in its half.
- Gaming: strip spans both cards, four equal columns, middle divider on the axis.
- Ambient: container centred on the screen both ways.
- Every hittable button is at least 44 x 44 pt.

## Sources

Apple Human Interface Guidelines: [Layout](https://developer.apple.com/design/human-interface-guidelines/layout),
[Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons),
[Materials](https://developer.apple.com/design/human-interface-guidelines/materials),
[Typography](https://developer.apple.com/design/human-interface-guidelines/typography),
[Widgets](https://developer.apple.com/design/human-interface-guidelines/widgets) (StandBy section).

- Alignment implies relatedness; group with space or containers; keep spacing consistent (Layout).
- Same-level options share a size; one or two prominent buttons; 44 pt hit region; press state (Buttons).
- Glass belongs to controls, not content; use it sparingly (Materials).
- StandBy shows two widgets side by side, scaled up, background removed, large text (Widgets).
- Concentric corners: inner radius = outer radius - padding.
  See [this summary](https://dev.to/sgbp/the-concentric-border-radius-rule-why-nested-rounded-corners-look-slightly-wrong-3hog)
  and Apple's `ConcentricRectangle` (iOS 26).
- Gestalt principles (proximity, similarity, symmetry): [Toptal overview](https://www.toptal.com/designers/ui/gestalt-principles-of-design).
- Fitts's law and target size: [Laws of UX](https://lawsofux.com/fittss-law/).

The 8 pt unit is a convention from Android's guidance, not an Apple rule. The viewing-distance
scale in rule 9 is this project's own estimate.

## Not done yet

- StandBy-style red Night Mode. Apps cannot read the ambient light sensor, so this needs a manual
  or scheduled switch.
- Verified on one device size (iPhone 18 Pro simulator). Test a smaller landscape width before
  trusting the top bar on every phone.
