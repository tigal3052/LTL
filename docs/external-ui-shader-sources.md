# External UI Shader Sources

The current interaction polish uses external shader references as implementation guidance, not copied screenshots or image/video assets.

## Used References

- GodotShaders `3D Hover CanvasItem`: hover tilt, specular-feeling lift, and click compression pattern.
- GodotShaders `Glow & Click Ripple | UI Effect V2.0`: pointer glow, click ripple, and fade-out interaction pattern.
- Godot Engine CanvasItem shader documentation: Godot 4 `canvas_item` shader constraints and material behavior.

## License Handling

GodotShaders shader posts are licensed per post under CC0, MIT, or GPLv3. The site license and FAQ say shader code/snippets can be reused under the selected post license, while screenshots, videos, and displayed image assets are not automatically licensed for reuse. This project therefore implements its own shader and tween layer in `app-LTL/src/ui/InteractionFX.gd` and does not import external screenshots or media.

## Local Implementation

- `app-LTL/src/ui/InteractionFX.gd` owns hover glow, click ripple, press compression, cursor changes, disabled dimming, and drag/drop feedback.
- `app-LTL/src/ui/presenters/InteractionCuePresenter.gd` keeps cue values testable without scene mutation.
