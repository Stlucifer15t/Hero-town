# Hero Town

A landscape-first Godot 4 mobile game prototype. The project is being built in testable slices; the current slice is **Step 1: City**.

## Run the prototype

1. Open this folder in **Godot 4.4 or newer** (`project.godot`).
2. Run the project (F6/F5, or the Run button).
3. Choose a map size at the start. Tap **New City** in the top-right HUD to choose another size at any time.
4. On a touchscreen, drag with one finger to pan and pinch with two fingers to zoom. On desktop, drag with the left mouse button and use the mouse wheel to zoom.

The city is a new procedural, pixel-art-style interpretation of a Manhattan-like island: a dense orthogonal street grid, wider avenues, a bending Broadway, Central Park with a lake and paths, waterfront promenades, bridges, and a few civic landmarks. Blocks contain varied low-rise and high-rise buildings, trees, pedestrians, cars, taxis, buses, and delivery vans. This is **TheoTown-inspired in spirit only**: no TheoTown graphics, save files, or proprietary assets are used.

### Selectable map sizes

| Option | Grid | Maximum block slots |
| --- | ---: | ---: |
| District | 5 × 12 blocks | 60 |
| Borough | 7 × 16 blocks | 112 |
| Large City | 9 × 24 blocks | 216 |
| Megacity | 11 × 30 blocks | 330 |

The shoreline and park leave some slots as water or green space, so the number of built city blocks is lower than the maximum. The default selection is **Large City**.

## Map reference and attribution

The layout reference is **“Manhattan NYC OpenStreetMap 2023-08-21.png” by OpenStreetMap**, published under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) via [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Manhattan_NYC_OpenStreetMap_2023-08-21.png). The underlying OpenStreetMap data is made available under the [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/1-0/). The project adapts the broad island outline and street-plan ideas into an original fictional, playable isometric map; it does not include the reference image or import a TheoTown map/save.

## Android / phone testing

The project viewport is landscape-first and uses the GL Compatibility renderer for broad mobile support. GitHub Actions installs Godot, its Android export templates, Java, and the Android SDK, then builds a **debug-signed APK** and uploads it as the `hero-town-android-debug-apk` artifact. Download the artifact from the successful workflow run in the repository's Actions tab and sideload the APK on your phone. It is for device testing, not a Play Store release. The workflow reuses a debug key so later builds can update the installed test app.

## Step 1 acceptance check

- Project opens to a map-size selection screen; **New City** opens it again while playing.
- Each size generates a larger/smaller island map with its own coastline, Manhattan-style avenues and cross streets, Broadway-like diagonal, Central Park and bridges.
- Dense city blocks include varied buildings, rooftop details, trees, landmarks, pedestrians, and several vehicle types.
- One-finger drag pans; two-finger pinch zooms. Desktop mouse controls are also available.
- The scene remains landscape on Android.

If Godot is installed, run the lightweight generation smoke test with:

```sh
godot --headless --path . --script res://tests/city_smoke_test.gd
```

The same GitHub Actions workflow runs this smoke test and builds the Android APK on pushes, pull requests, or manual dispatch. It checks project initialization and more than one map size; it does not replace touch testing on a real Android phone.

## Planned gameplay rule: powers must have real behavior

Powers will be implemented as gameplay capabilities, not just names or visual effects. For example, **Flight** will change traversal, let the hero reach/intercept someone who is airborne, and carry them to safety; **Super-speed** will increase movement speed, change attack tempo, and show a speed-blur trail. The later power data will describe which capabilities and effects a power grants, so adding entries can compose real gameplay behavior.
