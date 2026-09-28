#!/usr/bin/env node
// Builds data/tower/enemies.json: The Tower's Tier 1 enemies, wave by wave,
// from TheTowerSDK (MIT licence, by TmRxJD). Never edit the JSON by hand;
// change this script and rerun it.
//
//     npm pack thetowersdk@0.11.0 && tar xzf thetowersdk-0.11.0.tgz
//     (cd package && npm install --omit=dev)
//     node tools/import_tower_enemies.mjs package
//
// What comes from where:
// - A basic enemy's Attack is the SDK's, unrounded. The SDK floors it, but
//   unrounded it is exactly what the game shows (1.18, 1.39, 2.30, 3.56 and
//   15.90 on waves 1, 2, 5, 8 and 22 of the owner's screens).
// - A basic enemy's health is the SDK's, unrounded, times a correction fitted
//   to the owner's screens: the SDK runs high by about half a percent a wave.
//   The fit is only known to wave 22, so it holds at wave 22's value past it.
//   Replace it when a later wave is read.
// - Type multipliers, speeds and masses are the SDK's (mass sets how far
//   Knockback pushes). The type mix is the owner's
//   wave 22 screen, which disagrees with the SDK's 91/3/3/3.
// - Wave timing is the SDK's: 26 seconds of spawning, then a cooldown.
// - Tiers 1 to 3 (D107 authors only those), all the SDK's: enemy health and
//   attack multipliers (checked constant at every wave, Attack unrounded),
//   the Coins bonus, the boss cadence, the double-spawn chance a tier adds
//   (base 5 plus tier / 2.85, on the game's 0-100 roll), and how much a tier
//   raises the fast, tank and ranged shares (1 + 0.04 a tier, the Wave Info
//   panel's tier weight). The spawn rate itself follows the wave, not the tier:
//   the SDK's Wave Info reads it from one chart for every tier.
// - The on-screen cap on normal enemies is the SDK's (120).
// - Spawning, as the game does it (the owner, 28 September: "a 56% chance for
//   an enemy to spawn every 1/8th of a second" at the top rate): every roll
//   interval of the spawning window, one enemy spawns by the wave's spawn rate
//   (0-100). The rate by wave is the SDK's Wave Accelerator chart (Normal
//   column) from wave 1,000, and the owner's Wave Info below it; between and
//   before those, BattleSim reads it as Guesses says.
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import Module from "node:module";

const LAST_WAVE = 6500;
const HEALTH_DRIFT_PER_WAVE = 0.9953;
const HEALTH_DRIFT_KNOWN_TO = 22;
// The owner's screens, Tier 1, 24 and 25 September 2026.
const READINGS = [
  { wave: 1, health: 2.35, attack: 1.18 },
  { wave: 2, health: 3.31, attack: 1.39 },
  { wave: 5, health: 7.2, attack: 2.3 },
  { wave: 8, health: 12.15, attack: 3.56 },
  { wave: 22, health: 63.11, attack: 15.9 },
];
const MIX = { basic: 0.85, fast: 0.07, tank: 0.06, ranged: 0.02 };
// The owner's Wave Info, Tier 1.
const SPAWN_READINGS = [{ wave: 22, rate: 15 }];
const TIERS = [1, 2, 3];
// The Wave Info panel's tier weight on fast, tank and ranged spawn chances,
// below Tier 9 (info-panel-stats.js tierSpawnWeight, not exported; checked below).
const MIX_WEIGHT_PER_TIER = 0.04;

const sdkRoot = path.resolve(process.argv[2] ?? "package");
const require = createRequire(path.join(sdkRoot, "package.json"));
const dist = path.join(sdkRoot, "dist");

// The SDK floors Attack inside a function it doesn't export unrounded, so
// load that one module with the floor taken out.
function loadUnroundedScaling() {
  const file = path.join(dist, "mechanics/waves/base-empirical-scaling.js");
  const source = fs.readFileSync(file, "utf8");
  const floored = "    const raw = envelope * linearTerm * centuryStack * damageTierAttenuationFactor(t, tierPressure);\n    return Math.floor(raw);";
  if (source.split(floored).length !== 2) {
    throw new Error("computeEmpiricalWaveBaseDamage has changed shape; check the SDK version");
  }
  const mod = new Module(file);
  mod.filename = file;
  mod.paths = Module._nodeModulePaths(path.dirname(file));
  mod._compile(source.replace(floored, floored.replace("Math.floor(raw)", "raw")), file);
  return mod.exports;
}

const scaling = loadUnroundedScaling();
const panel = require(path.join(dist, "mechanics/waves/info-panel-stats.js"));
const uptime = require(path.join(dist, "mechanics/uptime/compute.js"));
const typeMults = require(path.join(dist, "mechanics/enemies/type-mults.js")).ENEMY_MULT_BY_TYPE_TABLE;

const healthDrift = (wave) => HEALTH_DRIFT_PER_WAVE ** (Math.min(wave, HEALTH_DRIFT_KNOWN_TO) - 1);
const input = (wave) => ({ wave, tier: 1, tournament: false });
const keep = (value) => Number(value.toPrecision(9));

const health = [];
const attack = [];
const speed = [];
for (let wave = 1; wave <= LAST_WAVE; wave++) {
  health.push(keep(scaling.computeWaveBaseHealthRaw(input(wave)) * healthDrift(wave)));
  attack.push(keep(scaling.computeWaveBaseDamage(input(wave))));
  speed.push(keep(panel.computeWaveInfoPanelEnemyExtras({ ...input(wave), enemyType: "Basic" }).speed));
}

// Two decimals is what the screen shows; allow the last one either way.
for (const reading of READINGS) {
  const got = { health: health[reading.wave - 1], attack: attack[reading.wave - 1] };
  for (const stat of ["health", "attack"]) {
    if (Math.abs(got[stat] - reading[stat]) > Math.max(0.011, reading[stat] * 0.003)) {
      throw new Error(`wave ${reading.wave} ${stat}: generated ${got[stat]}, screen ${reading[stat]}`);
    }
  }
}

const types = {};
for (const [id, name] of [["basic", "Basic"], ["fast", "Fast"], ["tank", "Tank"], ["ranged", "Ranged"], ["boss", "Boss"]]) {
  const typeSpeed = panel.computeWaveInfoPanelEnemyExtras({ ...input(1), enemyType: name }).speed;
  const mass = panel.computeWaveInfoPanelEnemyExtras({ ...input(1), enemyType: name }).mass;
  types[id] = { health: typeMults[name].hp, attack: typeMults[name].damage, speed: keep(typeSpeed), mass: keep(mass) };
}

// Tiers: the SDK's multipliers, checked constant across every wave.
const gates = require(path.join(dist, "mechanics/waves/update-spawn-gate-pass.js"));
const tierRows = require(path.join(dist, "data/tiers/data.js")).TIER_COIN_BONUS_ROWS;
const bossEvery = require(path.join(dist, "data/enemies/data.js")).bossWaveIntervalForTier;
const spawnCap = require(path.join(dist, "knowledge/compartments/enemies.js")).ENEMY_SPAWN_CAP;
const spawnRoll = require(path.join(dist, "mechanics/waves/spawn-gate-constants.js")).WAVE_SPAWN_TIMER_QUANTUM_SECONDS_V29;
const spawnChart = require(path.join(dist, "data/charts/data.js")).WAVE_ACCELERATOR_SPAWN_RATE_ROWS
  .map((row) => ({ wave: row.normal, rate: row.spawnCount }));
const tiers = [];
for (const tier of TIERS) {
  let healthRatio = null;
  let attackRatio = null;
  for (let wave = 1; wave <= LAST_WAVE; wave += 1) {
    const at = { wave, tier, tournament: false };
    const h = scaling.computeWaveBaseHealthRaw(at) / scaling.computeWaveBaseHealthRaw(input(wave));
    const a = scaling.computeWaveBaseDamage(at) / scaling.computeWaveBaseDamage(input(wave));
    healthRatio ??= h;
    attackRatio ??= a;
    if (Math.abs(h / healthRatio - 1) > 1e-6 || Math.abs(a / attackRatio - 1) > 1e-6) {
      throw new Error(`tier ${tier} wave ${wave}: multipliers ${h}, ${a} differ from ${healthRatio}, ${attackRatio}`);
    }
  }
  const weight = 1 + MIX_WEIGHT_PER_TIER * (tier - 1);
  const shown = panel.waveInfoSpawnChances(tier, 1);
  if (shown.Fast !== Math.min(64, Math.round(3.294 * weight)) || shown.Tank !== Math.min(64, Math.round(3.019 * weight))) {
    throw new Error(`tier ${tier}: the Wave Info tier weight is no longer 1 + ${MIX_WEIGHT_PER_TIER} a tier`);
  }
  const coin = tierRows.find((row) => row.tier === tier);
  tiers.push({
    tier,
    enemy_health: keep(healthRatio),
    enemy_attack: keep(attackRatio),
    coins: coin.coinBonus,
    boss_every: bossEvery(tier),
    double_spawn: gates.waveUpdateThresholdGtePassRate(gates.newWaveEnemyDoubleSpawnThresholdV29({ tier })),
    mix_weight: keep(weight),
  });
}

const out = {
  version: 2,
  source: "The Tower's Tier 1 enemies via TheTowerSDK 0.11.0 (MIT, TmRxJD), calibrated to the owner's screens. Generated by tools/import_tower_enemies.mjs.",
  readings: READINGS,
  health_drift: { per_wave: HEALTH_DRIFT_PER_WAVE, known_to_wave: HEALTH_DRIFT_KNOWN_TO },
  spawn_seconds: uptime.computeWaveCombatDurationSeconds(false),
  cooldown_seconds: keep(uptime.computeWaveInterCooldownSeconds(0, { tournament: false })),
  boss_every: 10,
  mix: MIX,
  tiers,
  enemy_cap: spawnCap.normal,
  spawn: { roll_seconds: spawnRoll, readings: SPAWN_READINGS, chart: spawnChart },
  types,
  basic_health: health,
  basic_attack: attack,
  basic_speed: speed,
};
const outPath = path.join(path.dirname(new URL(import.meta.url).pathname), "..", "data", "tower", "enemies.json");
fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(out) + "\n");
console.log(`wrote ${LAST_WAVE} waves to ${path.relative(process.cwd(), outPath)}`);
console.log(`spawn: a roll every ${spawnRoll} s; rate ${SPAWN_READINGS.map((r) => `${r.rate} at wave ${r.wave}`).join(", ")}; chart ${spawnChart.map((r) => `${r.rate}@${r.wave}`).join(" ")}`);
for (const t of tiers) {
  console.log(`tier ${t.tier}: health ×${t.enemy_health}, attack ×${t.enemy_attack}, Coins ×${t.coins}, boss every ${t.boss_every}, double spawn ${t.double_spawn}, mix weight ${t.mix_weight}`);
}
for (const r of READINGS) {
  console.log(`wave ${r.wave}: health ${health[r.wave - 1]} (screen ${r.health}), attack ${attack[r.wave - 1]} (screen ${r.attack})`);
}
