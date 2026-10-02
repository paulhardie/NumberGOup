# Cards, Workshop and Labs layout

The owner requested a layout closer to The Tower on 2 October 2026, retaining Number Go Up's colours and typography. This changes presentation and access to existing card details, not gameplay or progression.

## Built screens

- **Cards:** Buy New Card at the top; Active shows every bought slot, including empty ones; Inventory lists every built card in three columns. Both active cards and inventory tiles open the existing details with Equip or Remove. Tiles show the card's name, effect, seven level dots, copy progress and an equipped tick. Unfound cards stay dimmed and explain that they are not found. Maxed cards have a static diagonal gold sheen and gold edges in both Inventory and Active slots, plus gold level dots and progress bars in Inventory. The equipped tick remains separate from completion; unequipped maxed cards keep their sheen. The highlight sits behind text and ignores pointer input.
- **Card art pilot:** Damage, Health and Cash use original fine-line SVG faces: a multiplication burst, a protected plus and a growing banknote stack. These three appear in owned Inventory tiles, Active slots, details and draw results. Unfound cards keep their concealed face; the remaining eight cards are still text-only pending visual sign-off. Inventory tiles are taller to give the art a dedicated space above the value, with names, levels, exact copy counts and the maxed gold finish retained. This is low-risk decorative presentation: art ignores input and changes no card or save rule.
- **Workshop:** two columns of upgrades with name, value, level, price and affordability bar. The next group's unlock follows the grid. Attack, Defense and Utility controls sit above the existing navigation dock. Multi-buy, the unlock order and opening descriptions are unchanged. Rates of 1,000/s and above use compact suffixes in Workshop so their units remain visible; other screens keep their existing formatting.
- Navigation and reveal thresholds are unchanged. No presets, new cards, balance changes, save changes or additional live screens were added.

Reference organisation was checked visually against the [Tower Cards screenshot](https://www.mumuplayer.com/blog/the-tower-cards-guide-tier-list.html), [early Workshop screenshot](https://www.bluestacks.com/blog/game-guides/the-tower-idle-tower-defense/ttitd-beginners-guide-en.html), and [Labs screenshot](https://www.mumuplayer.com/blog/the-tower-lab-research-guide.html). These are dated third-party screenshots, used for layout only; they do not establish the current game's rules.

## Labs preview only

`tools/preview_labs_layout.gd` renders a standalone layout study. It is not connected to the game's navigation, does not read player progress and never saves anything. Its three example slots illustrate researching and idle states, not an approved slot count. Timers are labelled sample values; effects, catalogue rows, times and prices remain undecided.

```bash
bash run_godot.sh --path . -s res://tools/preview_labs_layout.gd
```

It writes `labs_layout.png` and `labs_catalogue_layout.png` to scratch `user://capture`, then exits. The research-slot view and catalogue view are visual studies, not working research controls. No rush, speed-up or paid-slot rule is implied by the mock-up. The playable Labs catalogue remains on the 1.2 roadmap.

## Verification

Risk: medium, because active card tiles provide an additional route to existing details and the Workshop purchase layout changes.

Verified on this change:

- `bash run_tests.sh`: exit 0, 4,711 tower checks and 235 foundation checks. Existing purchase, draw, slot and equipment coverage passes; added checks cover empty slots, individual active-card callbacks, full collections, removing the chosen card and saving/reloading screen actions through the unchanged save contract.
- Headless main-scene boot: exit 0, no script or parse errors.
- `capture_battle.gd`: successful renders at 540 × 960 and 390 × 844. Visually inspected Cards, card overlays, empty and full collections, bottom-scrolled inventory, mixed maxed/ordinary cards with the maxed card equipped and unequipped, the three illustrated card faces and their details, unfound faces, the three Workshop categories, multi-buy and maxed upgrades. A narrow-screen Free Upgrades overflow was corrected, and large regen values now retain their `/s` unit.
- Labs slot and catalogue previews rendered and visually inspected at both sizes. They have no live research actions.
- Final diff and whitespace checks passed. Battle rules, data, simulation tools, save implementation and the excluded decision, handover and Cards documents are untouched.

The suites and headless boot still print audio-resource leak warnings, whose counts varied between runs; a verbose run identified AudioStreamWAV and AudioStreamPlaybackWAV resources. Music cleanup remains a separate task. Capture files are inspection artefacts, not committed snapshots or pixel-equality tests.

Not checked: owner play, touch hardware, or other viewport sizes.

Owner play is still needed for feel and visual sign-off. Changes arrive in the play folder only after the PR merges.
