# Hero Town

A landscape-first Godot 4 mobile game prototype. The project is being built in testable slices; the current slice is **Step 1: City**.

## Run the prototype

1. Open this folder in **Godot 4.4 or newer** (`project.godot`).
2. Run the project (F6/F5, or the Run button).
3. Choose a map size at the start. Tap **New City** in the top-right HUD to choose another size at any time.
4. On a touchscreen, drag with one finger to pan and pinch with two fingers to zoom. On desktop, drag with the left mouse button and use the mouse wheel to zoom.

The city uses an original pixel-art look inspired by a **TheoTown community island city**, not a real-world map. Its broad layout reference is **Secaton** by Kevin 421 Hung, listed in the TheoTown Center sandbox collection as an island city with roughly 208,000 inhabitants: [TheoTown Center map listing](https://sites.google.com/view/retrocitycenter/theotown/maps/sandboxfree-mode). The same archive labels a 2,800+-tile “Former Largest Map” as not recommended for mobile, so Hero Town does not use that oversized map.

The old Secaton download link is no longer accessible from the archive, and the listing does not specify a reuse license. Hero Town therefore does **not** bundle or import a TheoTown save, screenshot, texture, or exact street plan. It translates the public island-city concept into a new playable layout: irregular coast and inlets, waterfront roads, a ring route, mixed street grids, parks, a harbor district, and a denser central skyline. The ground tiles are original procedural art, and the buildings use original project-specific pixel-art sprites in a shared atlas.

### Selectable map sizes

| Option | Grid | Map tiles | Maximum block slots |
| --- | ---: | ---: | ---: |
| District | 6 × 8 blocks | 49 × 65 | 48 |
| Borough | 9 × 12 blocks | 73 × 97 | 108 |
| Large City | 12 × 18 blocks | 97 × 145 | 216 |
| Megacity | 16 × 24 blocks | 129 × 193 | 384 |

The shoreline and parks leave some slots as water or green space, so the number of built city blocks is lower than the maximum. The default selection is **Large City**; the largest option stays within a phone-oriented tile footprint rather than using the community archive's 2,800+-tile map.

### Art direction and mobile rendering

The starter building atlas contains original townhouse, shop, apartment, and mid-rise art; it is not copied from TheoTown. The closer default camera, quieter tile seams, varied ground textures, and larger walkers are intended to make the neighborhood view more readable. Static buildings share one renderer and texture atlas, the ground remains a `TileMapLayer`, and pedestrians/vehicles pause their movement updates when off-screen. The number of walkers and vehicles is capped to keep the Android update budget bounded. Actual frame pacing still needs confirmation on a phone.

## Android / phone testing

The project viewport is landscape-first and uses the GL Compatibility renderer for broad mobile support. GitHub Actions installs Godot, its Android export templates, Java, and the Android SDK, then builds a **debug-signed APK** and uploads it as the `hero-town-android-debug-apk` artifact. Download the artifact from the successful workflow run in the repository's Actions tab and sideload the APK on your phone. It is for device testing, not a Play Store release. The workflow reuses a debug key so later builds can update the installed test app.

## Step 1 acceptance check

- Project opens to a map-size selection screen; **New City** opens it again while playing.
- Each size generates a mobile-sized island map with an irregular shoreline, bays, ring road, winding arterial routes, a harbor district, parks, landmarks, and dense city blocks.
- Blocks include varied low-rise and high-rise buildings, rooftop details, trees, pedestrians, and cars, taxis, buses, and delivery vans.
- One-finger drag pans; two-finger pinch zooms. Desktop mouse controls are also available.
- The scene remains landscape on Android.

If Godot is installed, run the lightweight generation smoke test with:

```sh
godot --headless --path . --script res://tests/city_smoke_test.gd
```

The same GitHub Actions workflow runs this smoke test and builds the Android APK on pushes, pull requests, or manual dispatch. It checks project initialization and more than one map size; it does not replace touch testing on a real Android phone.

## Planned gameplay rule: powers must have real behavior

Powers will be implemented as gameplay capabilities, not just names or visual effects. For example, **Flight** will change traversal, let the hero reach/intercept someone who is airborne, and carry them to safety; **Super-speed** will increase movement speed, change attack tempo, and show a speed-blur trail. The later power data will describe which capabilities and effects a power grants, so adding entries can compose real gameplay behavior.
