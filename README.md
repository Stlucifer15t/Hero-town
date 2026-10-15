# Hero Town

A landscape-first Godot 4 mobile game prototype. The project is being built in testable slices; the current slice is **Step 1: City**.

## Run the prototype

1. Open this folder in **Godot 4.3 or newer** (`project.godot`).
2. Run the project (F6/F5, or the Run button).
3. On a touchscreen, drag with one finger to pan and pinch with two fingers to zoom. On desktop, drag with the left mouse button and use the mouse wheel to zoom.

The city is generated from placeholder 64×64 pixel-style source tiles and a fixed seed, so it is repeatable between launches. The ground is projected as a classic 2:1 isometric diamond; the tile colors and procedural shapes are deliberately easy to replace with a tileset later.

## Android / phone testing

The project viewport is landscape-first and uses the GL Compatibility renderer for broad mobile support. GitHub Actions installs Godot, its Android export templates, Java, and the Android SDK, then builds a **debug-signed APK** and uploads it as the `hero-town-android-debug-apk` artifact. Download the artifact from the successful workflow run in the repository's Actions tab and sideload the APK on your phone. It is for device testing, not a Play Store release. The workflow reuses a debug key so later builds can update the installed test app.

## Step 1 acceptance check

- Project opens directly into the generated isometric city.
- Streets, sidewalks, city blocks, buildings, and trees are visible.
- Citizens walk around sidewalks and cars circulate on the roads.
- One-finger drag pans; two-finger pinch zooms. Desktop mouse controls are also available.
- The scene remains landscape on Android.

If Godot is installed, run the lightweight generation smoke test with:

```sh
godot --headless --path . --script res://tests/city_smoke_test.gd
```

The same GitHub Actions workflow runs this smoke test and builds the Android APK on pushes, pull requests, or manual dispatch. It checks project initialization and city generation; it does not replace touch testing on a real Android phone.

## Planned gameplay rule: powers must have real behavior

Powers will be implemented as gameplay capabilities, not just names or visual effects. For example, **Flight** will change traversal, let the hero reach/intercept someone who is airborne, and carry them to safety; **Super-speed** will increase movement speed, change attack tempo, and show a speed-blur trail. The later power data will describe which capabilities and effects a power grants, so adding entries can compose real gameplay behavior.
