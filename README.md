# Hero Town

A landscape-first Godot 4 mobile game prototype. The project is being built in testable slices: **Step 1: City** is in place, and the current slice adds **hero creation and usable powers**.

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

The starter building atlas contains original townhouse, shop, apartment, and mid-rise art; it is not copied from TheoTown. The ground now uses several deterministic tile treatments across the whole island: mottled grass, paving seams, water ripples, road wear, and alternate intersections. Procedural facades add occasional balconies and rooftop equipment. Curated sprite buildings and larger walkers stay concentrated in a centered neighborhood of up to 7 × 8 blocks to protect phone performance. Residents follow sidewalk-aware routes between home and named destinations, including a dedicated Hero Association headquarters that visitors can navigate to from the HUD. Static buildings share one renderer and texture atlas, the ground remains a `TileMapLayer`, and pedestrians/vehicles pause their movement updates when off-screen. Walker and vehicle counts are capped to keep the Android update budget bounded. Actual frame pacing still needs confirmation on a phone.

## Create and play as a hero

The first playable hero flow lets the player choose a callsign, suit/cape color, elemental affinity, and up to three powers from six options: Elemental, Super Strength, Super Speed, Teleportation, Beast Form, and Flight. The **HERO** button reopens creation so the hero and loadout can be changed without rebuilding the city. Training targets near the Hero Association give the action powers something to affect.

- **Elemental:** fire bolts burn targets over time, ice bolts freeze them, and lightning can chain to a nearby target.
- **Super Strength:** a heavy close-range ground smash damages and knocks back targets. The always-available Strike action also hits nearby targets.
- **Super Speed:** toggle faster movement, a visible speed trail, and faster strikes / shorter power cooldowns.
- **Teleportation:** blink forward through obstacles and land on walkable ground.
- **Beast Form:** toggle a larger, clawed form with faster movement and stronger, wider strikes.
- **Flight:** toggle a hovering form that moves faster and can cross water and blocked city lots.

On desktop, move with **WASD** or the arrow keys, use **1–3** for the equipped powers, and press **Space** to strike. On touchscreens, hold the on-screen isometric direction pad and tap the power / strike buttons. Power cooldowns and active toggles are shown on the HUD. The elemental selector offers Fire, Ice, and Lightning.

## Android / phone testing

The project viewport is landscape-first and uses the GL Compatibility renderer for broad mobile support. GitHub Actions installs Godot, its Android export templates, Java, and the Android SDK, then builds a **debug-signed APK** and uploads it as the `hero-town-android-debug-apk` artifact. Download the artifact from the successful workflow run in the repository's Actions tab and sideload the APK on your phone. It is for device testing, not a Play Store release. The workflow reuses a debug key so later builds can update the installed test app.

## Playable-slice acceptance check

- The first launch opens hero creation, followed by map-size selection; **HERO** lets the player edit their hero and loadout later, and **NEW CITY** changes the map.
- Hero creation accepts a callsign, suit/cape palette, elemental affinity, and one to three powers.
- All six selectable powers have an activated gameplay effect; cooldowns and toggled modes are visible in the HUD.
- Training targets near the Hero Association visibly react to strikes and elemental effects.
- City generation, named pedestrian destinations, Hero Association visitors, camera navigation, and mobile-safe city actor budgets continue to work.
- One-finger drag pans; two-finger pinch zooms. Desktop mouse controls are also available, while WASD/arrows and the on-screen pad move the hero.
- The scene remains landscape on Android.

If Godot is installed, run both headless checks with:

```sh
godot --headless --path . --script res://tests/city_smoke_test.gd
godot --headless --path . --script res://tests/hero_smoke_test.gd
```

GitHub Actions runs both smoke tests and builds the Android APK on pushes, pull requests, or manual dispatch. These checks do not replace touch testing on a real Android phone.
