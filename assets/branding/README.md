# VHSFin artwork

Original raster concepts generated for VHSFin with the built-in OpenAI image-generation tool. No external reference images were supplied. The selected cassette artwork is the shared app identity; the CRT is an alternate concept, and the movie-night scene is editorial brand artwork, not an app screenshot.

| File | Purpose |
| --- | --- |
| `cassette-icon.png` | Selected source: tactile cassette, ivory reels, green play symbol |
| `crt-icon.png` | Alternate concept: miniature television with phosphor glow |
| `crt-90s.png` | Production late-90s TV/VCR with a transparent screen and integrated transport keys |
| `walnut.jpg` | Walnut veneer, cropped and tiled at a fixed scale across the shelves |
| `movie-night.png` | Original movie-night illustration |
| `adaptive-background.png` | Phosphor glow cropped from the left half of `assets/icon.png` |
| `adaptive-foreground.png` | Transparent CRT safe-zone layer for Android adaptive icons |
| `../../docs/movie-night.jpg` | Smaller JPEG export for the README |
| `../icons/app_icon_1024.png` | 1024-pixel app master used by Flutter |
| `../icon.png` | Two-up source sheet: glow background | CRT (baked checkerboard) |
| `../tr_icon.png` | Transparent CRT foreground used by the Android adaptive icon |

## Platform assets

The production assets are checked in; image generation is not a build dependency. On macOS, run:

```sh
python3 tool/generate_brand_assets.py
```

The helper uses the system `sips` utility to resize the cassette master for iOS, macOS, web install icons, and the iOS launch image. Android adaptive icons and the Android splash use the CRT pair instead: the left panel of `assets/icon.png` as the glow background, and `assets/tr_icon.png` as a transparent foreground fitted to the 72dp safe zone. `sips` padding is opaque, so transparent padding is written in Python. It deliberately retains the simplified SVG/PNG browser favicon, which is easier to read at 16 pixels.

The web splash combines the generated cassette icon with responsive HTML text and a status indicator. Android launch screens use the CRT over the phosphor glow; iOS still uses the cassette on the shared dark brown background. Keeping text outside the bitmap makes the launch surface crisp at different sizes.

`crt-90s.png` has real transparency outside the cabinet and across the entire screen opening. The live screen extends underneath the opaque bezel; the bitmap defines the visible contour. Its five physical transport keys have interactive symbol overlays. The source is 1254 × 1254 pixels; normalized positions in `VcrBox` keep the screen, slot, and keys aligned at every size.

`walnut.jpg` is a flat, horizontal-grain veneer used for the shelf cavity, front lips, and console surround. `ExactAssetImage(scale: 2)` and `BoxFit.none` maintain the grain size without stretching it to fit tall cabinets or thin shelf edges.

### Late-90s production cabinet

Generated with the built-in image tool. Prompt:

```text
Production transparent PNG for a Flutter VHS player: photorealistic late-1990s charcoal TV/VCR combination, straight-on orthographic front elevation, square canvas. Practical understated consumer electronics, smooth graphite ABS with fine subtle grain, gently rounded rectangular cabinet. Large 4:3 CRT opening occupies the upper cabinet. The entire glass/picture area is a truly transparent alpha hole all the way to its rounded inner bezel. Transparent outside too. No painted glass, picture, triangle, or colored inner border. Bottom fascia: centered VHS slot, small power button and green LED left, speaker perforations right. Five separated rectangular silver-gray blank transport keycaps in one horizontal row below the slot, integrated in the housing. Two small feet on a horizontal baseline. Soft warm overhead studio light, cool right edge light, sharp product photography. No logos, text, props, ground plane, or background.
```

### Walnut material

Generated with the built-in image tool, then exported as a 1200-pixel JPEG. Prompt:

```text
Photorealistic flat dark American walnut veneer filling the canvas. Horizontal grain, satin pores, even scan lighting. No props, seams, text, or perspective. An unobtrusive cabinet material.
```

## Generation prompts

### Cassette icon

```text
Use case: stylized-concept
Asset type: production app icon for VHSFin, a nostalgic family Jellyfin VHS player.
Primary request: a gorgeous early iPhone era skeuomorphic app icon, square 1024x1024, a miniature black VHS cassette almost filling a rounded-square app tile. Straight-on with slight top-down depth, unmistakable two large ivory reels seen through smoked glass, tactile ribbed charcoal injection-molded plastic, tiny screws and a cream paper center label with a simple dark green play triangle, no lettering. One thin warm orange accent stripe. Rich bevels, polished edges, soft studio reflections, convincing miniature physical object. The tape should be chunky and icon-like, adapted to the square composition with very little empty space, readable at 48 pixels. Background tile warm near-black #1A100C, large rounded corners, subtle dimensional edge. Dark warm backdrop fills the entire canvas, tile fills canvas edge to edge. Lighting from upper left, warm highlights and a faint mint rim light. Premium, restrained, photorealistic 3D product render. No text, no watermark, no hands, no surrounding props, no extra frame.
```

### CRT alternative

```text
Use case: stylized-concept
Asset type: alternative production app icon for VHSFin, square 1024x1024.
Primary request: premium early iPhone skeuomorphic app icon, a beautiful miniature charcoal CRT television filling an iOS rounded-square silhouette edge to edge. Straight-on view, thick tactile dark graphite plastic casing, slightly curved smoked glass screen with deep phosphor green glow and a single large luminous ivory play triangle centered. A narrow VHS cassette slot integrated below the screen, tiny amber power light, subtle speaker grille and one metal knob. Screen occupies most of the icon, controls secondary. Physical depth, rounded glass edges, precise chamfers, warm upper-left studio light and soft mint edge reflections. Nostalgic, inviting, tactile, photorealistic 3D render, exceptional small-size readability. Rounded icon corners on full-bleed very dark warm brown #1A100C canvas. No typography, letters, watermark, antennas, scenery or props.
```

### Movie-night illustration

```text
Use case: ads-marketing
Asset type: wide 1536x1024 brand illustration for the VHSFin README and splash artwork.
Primary request: cinematic miniature product photography of a cozy 1990s movie-night entertainment center, a charcoal curved-glass CRT television on the right with a luminous phosphor-green play triangle on its empty screen, VHS deck below it, and a short row of colorful VHS cassette cases on a walnut shelf. Jewel-like tactile materials, polished black glass, brushed plastic, warm amber lighting with subtle mint green glow. Consistent premium early-iPhone skeuomorphic aesthetic. Clean composition, no people or clutter. Right half contains the TV and a few tapes; left half is beautiful uncluttered nearly black warm brown negative space, softly illuminated. Background deep #1A100C brown. No movie titles, logos, text, letters, watermark. This is brand artwork, not a screenshot.
```

Generation output may not exactly match the requested pixel dimensions; platform exports are resized deterministically from the saved originals. These prompts document the visual direction, not a promise of identical future outputs.
