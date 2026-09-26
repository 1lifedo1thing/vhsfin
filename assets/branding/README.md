# VHSFin artwork

Original raster concepts generated for VHSFin with the built-in OpenAI image-generation tool. The current TV icon was made using the earlier iOS artwork, Android splash icon, and the supplied iOS shape template as references. The rounded TV casing is the iOS, macOS, and web app identity; a matching transparent cutout is used by Android. The cassette is an earlier concept, and the movie-night scene is editorial brand artwork, not an app screenshot.

| File | Purpose |
| --- | --- |
| `cassette-icon.png` | Earlier app icon concept: tactile cassette, ivory reels, green play symbol |
| `crt-icon.png` | Original miniature television concept with green phosphor glow |
| `crt-icon-ios-squircle-v3.png` | Current transparent TV artwork; the modeled casing itself forms the iOS rounded-square silhouette |
| `crt-icon-cutout-v3.png` | Detailed live TV cabinet matching the app icon's lighting, with a transparent screen and four subtle transport keys |
| `crt-icon-cutout.png` | Earlier textured TV cabinet cutout |
| `crt-icon-ios-v2.png` | Earlier opaque full-bleed TV face |
| `crt-icon-cyan-cutout-v2.png` | Matching Android foreground with simplified controls and transparent surroundings |
| `crt-icon-ios-fullbleed.png`, `crt-icon-cyan-cutout.png` | Earlier TV icon iterations |
| `crt-90s.png` | Production late-90s TV/VCR with a transparent screen and integrated transport keys |
| `walnut.jpg` | Walnut veneer, made seamless (`tool/make_seamless_texture.py`) and tiled at a fixed scale |
| `../knob.png`, `../knob2.png` | Wood TVs on charcoal and putty decks; printed keys read REW, PLAY, FF, EJECT |
| `movie-night.png` | Original movie-night illustration |
| `adaptive-background.png` | Solid dark background for Android adaptive icons |
| `adaptive-foreground.png` | Transparent CRT safe-zone layer for Android adaptive icons |
| `../../docs/movie-night.jpg` | Smaller JPEG export for the README |
| `../icons/app_icon_1024.png` | Opaque 1024-pixel TV icon used by Flutter |
| `../icon.png` | Earlier two-up source sheet: glow background | CRT (baked checkerboard) |
| `../tr_icon.png` | Earlier transparent CRT foreground |

## Platform assets

The production assets are checked in; image generation is not a build dependency. On macOS, run:

```sh
python3 tool/generate_brand_assets.py
```

The helper extends the nearest cabinet edge colors into the transparent corners before exporting Apple's required opaque square icon. The visible bevel and shadow come from the TV casing itself; iOS applies its own rounded-square mask at display time. Android uses a separate charcoal background and a transparent TV foreground scaled to 54dp so its corners fit inside the circular 66dp safe area. `sips` padding is opaque, so transparent padding is written in Python. The simplified SVG/PNG browser favicon remains easier to read at 16 pixels.

The web splash combines the generated TV icon with responsive HTML text and a status indicator. Android launch screens use the CRT over charcoal; iOS uses the rounded TV cabinet. Keeping text outside the bitmap makes the launch surface crisp at different sizes.

`crt-90s.png` has real transparency outside the cabinet and across the entire screen opening. The live screen extends underneath the opaque bezel; the bitmap defines the visible contour. Its five physical transport keys have interactive symbol overlays. The source is 1254 × 1254 pixels; normalized positions in `VcrBox` keep the screen, slot, and keys aligned at every size.

`crt-icon-cutout-v3.png` keeps the selectable live TV skin's small amber light, full speaker grille, cassette slot, knob, and four transport keys for viewing at larger sizes. Its smoother graphite-bronze casing borrows the app icon's warm upper-left light and restrained cyan edge light, without the original crackle texture. The screen opening and surroundings have true alpha, and the quieter printed keys remain interactive. Its screen and control regions are measured in `CrtSpriteLayout`.

The knob decks were drawn with REW, PLAY, STOP, FF printed on their keys. The app has no stop, so the FF symbol was moved onto the third key and an EJECT symbol in the same cream ink was printed on the fourth. Key positions and actions for every cabinet are in `CrtSpriteLayout`.

`walnut.jpg` is a flat, horizontal-grain veneer, cross-faded so its edges tile without seams, used by the Walnut shelf look. `ExactAssetImage(scale: 2)` and `BoxFit.none` maintain the grain size without stretching it to fit tall cabinets or thin shelf edges.

### Production icon edits

The production masters were edited with the built-in image-generation tool. The user's home-screen screenshot, Android splash icon, and iOS icon grid guided the outer shape. The design briefs were:

- Current iOS icon: make the outer TV casing itself follow the iOS icon squircle, with the bevel, highlights, and soft shadow inside that contour. Fill the canvas at the four side midpoints, keep the screen nearly black with subdued cyan light, and preserve the simplified controls at 48–60 pixels.
- Earlier full-bleed icon: make the square itself a continuous graphite CRT face with no exterior TV silhouette; let the iOS mask form the only outside contour. Simplify the screen, play triangle, slot, amber LED, knob, and speaker holes for 48–60 pixel display. Use warm upper-left light, restrained cool right-edge glint, and lower-edge shadow inside the mask; keep the glass dark with cyan localized near the play symbol.
- Android cutout: preserve genuine transparency outside the compact cabinet; match the simplified controls, dark screen, ivory play symbol, and restrained cyan glow of the production iOS icon.

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
