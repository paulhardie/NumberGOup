# NUMBER GO UP

A portrait-first, local-save Godot web idle-game vertical slice.

## Run

```bash
GODOT=/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot ./run_tests.sh
```

Open the project in Godot 4.7.2 and run `scenes/main.tscn` for the playable build.

## Web export

`export_presets.cfg` defines a single-threaded, PWA-enabled Web export at `build/web/index.html`.
Exported files must be served over HTTPS for browser persistence and PWA behavior to work reliably. No hosting configuration is included.

## Product boundary

This slice implements a fast Workshop bootstrap, tapping, passive production, a four-bay ranked Workshop board, a 25%-discount Research Focus, synergy, selected-upgrade automation, local saves/offline rewards, a stats/settings drawer, and a locked Prestige teaser. Prestige, Knowledge, Laws, accounts, monetisation, and deployment are intentionally excluded.

## Progression vocabulary

`Workshop` is the early machine-building bootstrap: Output, Speed, Chance, and Logic remain permanently visible, with later bays gated by total ranks. `Research` softly specialises a build by discounting one bay rather than closing alternatives. Cards are typed as `Modules`, `Protocols`, or `Routines`; the catalog also reserves `Breakthroughs`, `Knowledge`, `Laws`, and `Violations` for later progression layers without revealing them in the current slice.
