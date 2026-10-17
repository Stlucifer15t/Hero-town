# Hero Town

Hero Town is a portrait-first Godot 4 superhero game prototype. The active build opens on an in-world, low-poly 3D park scene with a distant city skyline, a hero creator, touch movement, and usable powers. The earlier isometric city slice is preserved at `scenes/main.tscn` while the 3D direction is being proved out.

## Run the game

1. Open the project in **Godot 4.4 or newer** and run it.
2. The opening scene is **Hero Town Park**. Choose **Create Your Hero**, set a callsign and suit/cape palette, then equip up to three powers and choose an elemental affinity.
3. **Begin Patrol** enters the park. Use the on-screen joystick and power buttons on a touchscreen. On desktop, move with **WASD** or the arrow keys, use **1–3** for equipped powers, and press **Space** to strike.
4. Use **HERO** during a patrol to edit the look or loadout. The changes apply without resetting your current position.

The Android export and viewport are set to portrait. The active scene uses the GL Compatibility renderer and instanced grass so it can be tested on a broad range of phones.

## Current 3D slice

The startup scene is a playable proof of the new visual direction: a ground-level third-person camera, warm afternoon sky, low-poly park trees and furniture, a textured distant skyline, instanced foreground grass and flowers, strolling park visitors, a Hero Association landmark, and a restrained location intro. It now uses 15 original pixel-art materials for the meadow, paving, waterfront, facades, trees, furniture, hero fabric, and title-screen crest. The textures are 128 × 128 nearest-filter PNGs (about 18 KB compressed in total, under 1 MB decoded), so they add detail without a large mobile memory cost. The player hero is assembled from original low-poly shapes, with suit/cape colors and a compact, game-styled creator. See `assets/pixel/ART_ASSETS.md` and `tools/generate_pixel_art_assets.py` for the pack and its reproducible source.

The park has a small training range with three damageable targets. All six selectable powers have 3D effects:

- **Elemental:** Fire bolts burn, Ice bolts freeze, and Lightning can chain to another nearby target.
- **Super Strength:** a wide ground smash damages nearby targets; it also strengthens the regular Strike.
- **Super Speed:** toggle faster movement and a visible energy trail/aura.
- **Teleportation:** blink forward, stopping before a collision if the route is blocked.
- **Beast Form:** toggle a larger form with stronger attacks and faster movement.
- **Flight:** hover, move faster, and ignore ground obstacles while airborne.

The 3D scene is intentionally a vertical slice, not yet a complete city conversion: the park and skyline are playable scenery, while city streets, vehicles, full pedestrian destinations, and neighborhood exploration remain in the preserved isometric prototype. The first goal is to validate the camera, portrait framing, mobile controls, and 3D power feel before replacing those systems.

## Classic isometric city slice

To run the original pixel-art city build, select `scenes/main.tscn` in the Godot editor and run that scene. It retains selectable city sizes, procedural island-city layouts, named pedestrian destinations, Hero Association visitors, city camera navigation, and the original 2D hero/power system.

| Option | Grid | Map tiles | Maximum block slots |
| --- | ---: | ---: | ---: |
| District | 6 × 8 blocks | 49 × 65 | 48 |
| Borough | 9 × 12 blocks | 73 × 97 | 108 |
| Large City | 12 × 18 blocks | 97 × 145 | 216 |
| Megacity | 16 × 24 blocks | 129 × 193 | 384 |

The city art is original and procedural, with an original project building atlas. Its broad layout reference is **Secaton** by Kevin 421 Hung, listed in the TheoTown Center sandbox collection as an island city: [TheoTown Center map listing](https://sites.google.com/view/retrocitycenter/theotown/maps/sandboxfree-mode). The old save download is inaccessible from that archive and the listing does not specify a reuse license, so Hero Town does not bundle or import a TheoTown save, screenshot, texture, or exact street plan. More asset notes are in `assets/city/ART_ASSETS.md`.

## Validation and Android build

GitHub Actions imports the project, runs the existing city and 2D hero smoke tests, runs the new portrait 3D park/hero smoke test, and exports a debug-signed Android APK. The APK is uploaded as the `hero-town-android-debug-apk` artifact for sideloading. It is for device testing, not a Play Store release. CI does not replace testing touch controls and frame pacing on a real phone.

If Godot is installed locally, the smoke tests can be run with:

```sh
godot --headless --path . --script res://tests/city_smoke_test.gd
godot --headless --path . --script res://tests/hero_smoke_test.gd
godot --headless --path . --script res://tests/hero_town_3d_smoke_test.gd
```
