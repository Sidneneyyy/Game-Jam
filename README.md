# Forgotten Acorns

**ThunderHacks 2026 Algoma Game Jam** entry. Theme: **Four Seasons**. Built in **Godot 4.7.2**.

You are a red squirrel in a city park. Bury acorns to get through the winter. Every stash you forget sprouts into an oak next spring.
Real squirrels plant forests this way, by forgetting.

## Play

| Platform | How |
|---|---|
| **Windows** | Run `builds/windows/ForgottenAcorns.exe`. Keep `ForgottenAcorns.pck` in the same folder. No install. The exe is the official, code-signed Godot runtime, so Windows Smart App Control allows it. It loads the game from the `.pck` beside it. |
| **Windows (download)** | `builds/ForgottenAcorns-windows.zip` holds the same two files. Upload it as a GitHub Release asset; the exe is too big for the repo itself. |
| **Browser** | Serve `builds/web/` (for example with GitHub Pages) and open `index.html`. |

**F11** toggles fullscreen. **Esc** pauses.

### Controls

| Action | Default | Also |
|---|---|---|
| Move | WASD | Arrow keys, game-pad stick or d-pad |
| Sprint (uses more food) | Shift | Game-pad RB |
| Bury an acorn (carrying) / dig a stash up (empty cheeks) | Space | J, game-pad A |
| Eat (acorn from your cheeks, a flower, berries) | Left click | E, K, game-pad X |
| Climb a tree / slip into its burrow (press again to come out) | Right click | F, L, gamApproved, with these answers and changes. Go ahead and build it, then push it to main.

SCOPE: the deck is 5 slides MAX, with very short text (about 15 words of body text per
slide). Use this outline:
1. Title, tagline and the problem in one line.
2. Our solution: how it works (a simple pipeline diagram).
3. Live dashboard: real screenshots with 2-3 callout labels.
4. Results: the real numbers from docs/VALIDATION.md (296 alerts, 0.40% of normal players
   alerted vs 2.76% for fixed rules, top 25/50/100 alerts all real cases vs 92/96/98%).
5. Roadmap, responsible by design (synthetic data, human decides, every flag explained),
   and Q&A.
Speaker notes per slide with short talking points, the source file for each number, and
timing of about 2 minutes total.

GOOGLE SLIDES COMPATIBILITY: the main deliverable must open correctly in Google Slides.
Export both a .pptx and a PDF from Slidev. The deck must read perfectly with NO animations,
clicks or transitions, because they will not carry into Google Slides. Use only static
visuals. Verify the .pptx opens and renders correctly (convert or inspect it with whatever
tool is available, and tell me what you could not check). Put speaker notes into the .pptx if
Slidev supports it. Tell me plainly that Google Slides will show the slides as images (not
editable text).

ANSWERS TO YOUR QUESTIONS
1. Installs: approved. Install locally inside deck/ only, no global installs: @slidev/cli and
   any theme package it needs, playwright-chromium (needed for export), the @fontsource
   packages for the fonts DESIGN.md uses (including IBM Plex Mono), and playwright for the
   slide checks. Use Microsoft Edge where possible. If anything would download a browser, ask
   me first.
2. Dashboard screenshots: approved. Start the API on port 8765 using the existing
   AML-polish\.venv Python, but RUN FROM the pitch-deck worktree (not AML-polish) so nothing in
   the AML-polish folder changes. data/ is git-ignored. If running the pipeline rewrites
   docs/VALIDATION.md or any other tracked file, restore it with git checkout and use ONLY the
   committed numbers in the deck. Stop only the server you launch and confirm the port is free.
3. Network analysis: show it as built ONLY if you confirm by running it that the
   /players/{id}/network endpoint works and the validation file has the Network row. Keep Jube
   as roadmap (the repo only has a mock), and mention the HANDOFF contradiction in your report.
   Keep the CBN Crash Game feed as roadmap (draft contract).

KEEP ALL EARLIER RULES
- The OLG challenge brief is confidential: never copy or quote it. All data is synthetic.
- No invented numbers: every number is sourced in deck/SOURCES.md. Team names are TBD, and no
  OLG logos.
- The project name lives in ONE place (a <ProjectName/> component).
- No CDN or internet needed to present: bundle fonts and images locally.
- Git changes only inside deck/ plus .gitignore. Add node_modules/ and dist/ to .gitignore.
- Verify before pushing: screenshot every slide at 1920x1080 and 1280x720 and fix any overflow,
  cut-off or unreadable text.

PUSH (to main, only if every check passes)
1. git fetch. If origin/main has new commits, merge them into pitch-deck first and re-run the
   checks.
2. Create and push a safety tag at origin/main's current commit named pre-pitch-deck-<date>.
3. Push the branch with "git push -u origin pitch-deck" (check first that origin/pitch-deck
   does not already exist).
4. Merge pitch-deck into main with a normal merge commit (no squash, no rebase) and push main.
   Confirm the merge touches only deck/ and .gitignore, and that no app code, docs or tracked
   data files changed. Commit the exported PDF and .pptx under deck/export/ along with the
   source. If main is protected, the push is rejected, or I lack write access, do NOT bypass
   it: stop and tell me so I can open a pull request.
5. Update the local main to match origin/main.

HARD RULES: never use --force or --force-with-lease, never delete branches, tags or worktrees,
do not touch other people's branches, and do not kill processes you did not start (no
taskkill /IM python.exe or /IM node.exe). Commit in small steps.

FINAL REPORT: the 5 slides, every number with its source, what could not be verified
(especially the Google Slides import, which I will test myself), where the PDF, .pptx and
screenshots are, how to open the .pptx in Google Slides, and the exact tag, branch and commits
pushed.epad B |

Every main control can be remapped in **Settings → Controls**. There is no inventory: you carry up to 4 acorns in your cheeks.

## The idea

You have to decide what every acorn is for. Eat it now, stash it for later, or forget it and let it become a tree.
The demo is one full year. When spring comes back, your forgotten stashes sprout, and the park you leave behind is your score.
Choose **Keep going** to play endless years. The true ending comes when the park has turned into a forest.

## How each season changes the rules

| Season | What changes | Carries into the next season |
|---|---|---|
| **Spring** | Flowers bloom and bees arrive. Bees that sit on flowers near a tree long enough **build a hive in it**, and you can't climb a hive tree because the bees sting. **Eat the flowers near your trees** to keep the bees away. Rain showers pass through now and then, and bees stop building while it rains. You can still dig up last year's stashes. | Hives stay all year. Flowers wilt. |
| **Summer** | Last spring's sprouts grow into saplings. **The dog** bursts in through a gate and chases you: climb a tree without bees and it barks, gets bored and leaves. **The hawk** is never seen circling. You hear a screech, a shadow swells where you stand, and a blur drops out of the sky. Hide under a leafy crown or just don't be there. The dog and the hawk never come together or back to back. Berry bushes give quick food that can't be stashed. | Saplings become young oaks in fall. |
| **Fall** | Oaks drop acorns, but not as many as you'd like. **Eat extra to fluff up**: food beyond a full stomach becomes body fat, and you can see the squirrel go from lean to plump to a round fur-ball. Bury the rest. **Rival squirrels** (a darker coat) come to spy from inside a tree, from behind a trunk or from far away. If one sees you bury, it comes back later and takes the whole stash. Run at a rival while your hunger is above the 60% line and it bolts. If you're weaker than that, it fights you off. | Acorns left on the ground are lost under the snow. |
| **Winter** | The ground is frozen, so you can't bury. It's dark and snowing, and you see only a small circle around you (and the park lamps). You still get hungry, so dig up your stashes. The cold burns your fluff on top of that, and once the fluff is gone it eats into your food and you freeze fast. A **burrow** keeps the cold out, but only a fluffed-up body warms back up inside one: **if you didn't fluff up in fall, you won't survive the winter.** The **fox** is the only hunter: you can see its **paw prints** across the snow from far away, but the fox itself only once it's inside your circle. Stashes are hidden under the snow, and sparkles show them when you're close. | Every stash still in the ground next spring can sprout (one tree per stash, however many acorns are in it). |

**Burrows:** stash 3 or more acorns around a tree and you dig a burrow in it. It's a warm hideout in winter and a safe spot from the dog, and a burrow tree can never get a beehive. The acorns are still yours to lose, though: rivals can steal them.

**Stashes:** you can keep burying acorns in the same spot to grow one big stash. It's easy to find again, but one rival can take all of it in one go, and if you forget it, it sprouts only one tree.

## Accessibility

- **Remappable controls**, plus fixed arrow/E/F alternatives and full game-pad support.
- **Assist mode**: hunger and cold drain about 30% slower, you see wider in winter, and stashes stay visible under the snow.
- **High contrast mode**: every threat gets a bold marker that differs by shape as well as colour (solid circle for the dog and fox, dashed circle for rivals, diamond for bees, ring for the hawk's strike spot). Nothing relies on colour alone.
- **Screen shake** can be turned off. Music and sound volumes are adjustable.
- **Season length** can be set from 1 to 4 minutes per season (default 1:30).
- **A tutorial without text**: the first seconds show a pictogram card (acorn → Space → stash → winter → sprout). After that, key and mouse glyphs appear in the world at the moment you can use them. When something is chasing you, an arrow points at the nearest safe tree.

## Repository

| Path | What |
|---|---|
| `game/` | The Godot project (open `game/project.godot`) |
| `game/scripts/` | Autoloads (settings, season clock, run state, art, sound), park and actors, UI, autotest and balance bot |
| `tools/` | Python scripts that generate **all** art and audio (`pip install pillow numpy`) |
| `builds/` | Windows and web builds |
| `docs/` | Design notes, pitch, credits |
| `prototype/` | The earlier single-file web prototype this game grew from |

### Rebuild everything

```sh
python tools/build_all.py                                     # every sprite, tile, icon, font, sound and music loop
Godot --headless --path game --import                         # import the new assets
Godot --headless --path game -- --autotest                    # scripted test of every mechanic -> "AUTOTEST OK"
Godot --headless --path game -- --bot --speed=4               # balance bot plays a whole year and reports
Godot --headless --path game --export-pack "Windows Desktop" ../builds/windows/ForgottenAcorns.pck
cp Godot_v4.7.2-stable_win64.exe builds/windows/ForgottenAcorns.exe   # signed runtime; loads the .pck
Godot --headless --path game --export-release "Web" ../builds/web/index.html
```

## Credits

See [docs/CREDITS.md](docs/CREDITS.md). All art, sound, music and the pixel font were made by the team during the jam, using code.
