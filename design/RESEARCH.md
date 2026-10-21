# Abyssal visual research

Research date: 2026-10-21.

The user found A (Technical) and C (Glass) interesting and asked for online
research to bring the main style closer to the abyss theme. These notes are
recommendations for the next study, not approval of a final design. The running
four-direction preview and functional shell have not changed in this round.

## References

### Underwater: Ash Thorp / Alt Creative

https://www.altcinc.com/projects/underwater.html

The original artist's project contains screen/HUD concepts, diagrams and
production frames. Thorp describes aiming for plausible, functional technology
in the film's setting. I inspected selected navigation studies from the page.
Useful design interpretation: precise geometry and bright information against
dark environments can provide a more specific identity than rounding or tint
alone. The film graphics are visual references, not usability-tested desktop
components or assets to copy.

### Prometheus: Territory Studio

https://territorystudio.com/project/prometheus/

Territory describes combining research into scientific/military interfaces
with references from art and nature. The production images show layered
scientific displays. Useful interpretation: combine a disciplined functional
layout with an organic source of identity, rather than adding ornament to every
control. This is a method reference, not an ocean-specific style.

### Cockpit: Blue Robotics

https://bluerobotics.com/introducing-cockpit/
https://github.com/bluerobotics/cockpit

A real, customizable ground-control application used with underwater vehicles.
The product documents user-arranged widgets and profiles. Useful for functional
grouping and the user's existing requirement that panels/widgets adapt to them.
No dependency or code reuse is proposed.

### Subnautica: Unknown Worlds

https://unknownworlds.com/en/news/voice-deep-update-released

The developer's post includes the redesigned PDA. I inspected that image: blue
translucent surfaces, bright thin edges, clear list/detail grouping, and a
strong selected item. Useful for C's atmosphere and sense of a complete system.
Its color saturation, framing and device metaphor are specific to the game;
the desktop needs its own proportions and controls.

### Bioluminescence: MBARI

https://www.mbari.org/know-your-ocean/bioluminescence/

Natural reference for concentrated light against darkness. The design proposal
is to let active controls and information carry the light. This is an aesthetic
interpretation, not a scientific claim about UI perception or performance.

### Carbon: dark surface layering

https://www.carbondesignsystem.com/building-blocks/foundations/color/guidelines

Carbon defines explicit background/layer/field/interaction tokens. Useful as a
construction method for consistent shell surfaces. It does not determine
Abyssal's appearance.

## Proposed synthesis: a deep-sea research station

- A supplies alignment, compact control grouping and precise numerical readouts.
- C supplies layered blue-black surfaces, separation from the wallpaper and a
  floating overlay model.
- Preserve the liked Slate neutrals. Compare pale cyan against muted violet for
  selection within this specific composition; do not decide by swatches alone.
- Test small 4–8 px control corners and 10–12 px overlay corners. A subtle inner
  highlight can distinguish a surface without a heavy frame.
- Reuse a short illuminated edge for selection/focus across the launcher,
  workspace indicator and menus. Keep normal labels and separators subdued.
- Keep the chosen JetBrains Mono. Compare a proportional label font only as an
  explicit alternative, retaining mono for numerical readouts.
- Keep glass at the outer surface; fields and controls remain clear and stable.
- Real values such as volume, CPU and RAM can use scales/ticks. Do not add fake
  coordinates, depth numbers, decorative radar or background telemetry.
- Motion should explain opening, selection and closing. No perpetual pulsing or
  scanning effect is needed to establish the identity.

The next review should compare a more technical and a more atmospheric version
of this same design language. Final choices remain with the user.
