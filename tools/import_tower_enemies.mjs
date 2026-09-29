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
// - The on-screen caps are the SDK's: 120 normal enemies, 20 elites, 10
//   bosses; the owner's (28 September) 8 of any one elite type.
// - Enemy speed: a tier's weight speeds every enemy as it raises the shares
//   (the panel's enemySpeedWaveMult uses the same weight). Mass grows past
//   wave 4,000 as the panel's enemyMassWaveMult has it, and 4% more for each
//   wave an enemy stays alive (the knowledge base, from The Tower's patch
//   notes). An enemy alive three waves pays half its Coins (ENEMY_COIN_DECAY).
// - Heat-up: each hit an enemy lands makes its next ×1.04, compounding
//   (ENEMY_HEAT_UP_MULTIPLIER_PER_HIT, from the game's Enemy.Attack; D116).
// - Cash a kill pays by its wave, before its type and Cash Bonus: $1, and $1
//   more every 10 waves to wave 200, then every 20 (the community wiki's Cash
//   page, 28 September 2026; D116). Nothing in the SDK gives it.
// - The Protector (from Tier 2, D115): its share of spawns by wave band
//   (80/160/320/751), its gate, health 0.6 of a basic's, speed, mass, radius
//   by wave and tier, and damage taken under it (0.6, the binary's constant;
//   the panel's display default of 55% is not what hits use; Thorns 0.7).
// - Elites (Vampire, Ray, Scatter): each tier's rows of the Elite Spawn
//   Chance chart (single and double chance, from the wave each opens), and
//   their multipliers, speeds and masses. Vampire drains 2% of the tower's
//   Health a second (WAVE_INFO_VAMPIRE_TOWER_DAMAGE_MULT), Ray charges 30
//   seconds between shots and Scatter splits four times (the SDK's enemy
//   summaries).
// - Spawning, as the game does it (the owner, 28 September: "a 56% chance for
//   an enemy to spawn every 1/8th of a second" at the top rate): every roll
//   interval of the spawning window, one enemy spawns by the wave's spawn rate
//   (0-100). The rate by wave is the community's "Spawn Rate to Wave Count"
//   chart, Standard column, from the wave each rate starts (the owner, 29
//   September; D118): transcribed below as SPAWN_RATES and checked against the
//   SDK's Wave Accelerator chart wherever both have a row. Its other columns
//   are the Wave Accelerator card's, not built.
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
// The chart's Standard column, as it is printed (34 starts at both 600 and
// 750 there). The owner's own Wave Info read 15 at wave 22, which it agrees with.
const SPAWN_RATES = [
  [1, 10], [3, 11], [6, 15], [40, 17], [60, 19], [80, 20], [100, 22], [150, 24], [200, 26], [250, 28],
  [300, 30], [400, 32], [600, 34], [750, 34], [800, 36], [1000, 37], [1250, 38], [1500, 39], [2000, 40],
  [2500, 42], [3000, 44], [3500, 46], [4000, 48], [4500, 49], [5000, 50], [5500, 52], [6000, 54], [6500, 56],
].map(([wave, rate]) => ({ wave, rate }));
const SPAWN_READINGS = [{ wave: 22, rate: 15 }];
const TIERS = [1, 2, 3];
// The Wave Info panel's tier weight on fast, tank and ranged spawn chances,
// below Tier 9 (info-panel-stats.js tierSpawnWeight, not exported; checked below).
const MIX_WEIGHT_PER_TIER = 0.04;
// The owner, 28 September: "20 elite with 8 per type".
const ELITE_PER_TYPE_CAP = 8;
// From the SDK's enemy summaries and knowledge base, which state them in prose.
const RAY_CHARGE_SECONDS = 30;
const SCATTER_SPLITS = 4;
const MASS_PER_WAVE_ALIVE = 1.04;
// Thorns on an enemy under a Protector: the knowledge base's reading of
// Enemy.ThornDamage, which it gives only in prose.
const PROTECTOR_THORNS_TAKEN = 0.7;
const COIN_DECAY_AFTER_WAVES = 3;
const KILL_CASH = { every_waves: 10, until_wave: 200, then_every_waves: 20 };

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
const massGrowth = [];
const protectorRadius = [];
for (let wave = 1; wave <= LAST_WAVE; wave++) {
  health.push(keep(scaling.computeWaveBaseHealthRaw(input(wave)) * healthDrift(wave)));
  attack.push(keep(scaling.computeWaveBaseDamage(input(wave))));
  speed.push(keep(panel.computeWaveInfoPanelEnemyExtras({ ...input(wave), enemyType: "Basic" }).speed));
  massGrowth.push(keep(panel.enemyMassWaveMult(wave)));
  protectorRadius.push(keep(panel.computeWaveInfoPanelSummary(1, wave).protectorRadiusMeters));
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
for (const [id, name] of [["basic", "Basic"], ["fast", "Fast"], ["tank", "Tank"], ["ranged", "Ranged"], ["boss", "Boss"],
  ["protector", "Protector"], ["vampire", "Vampire"], ["ray", "Ray"], ["scatter", "Scatter"]]) {
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
const rateAt = (wave) => SPAWN_RATES.filter((row) => row.wave <= wave).at(-1).rate;
for (const row of require(path.join(dist, "data/charts/data.js")).WAVE_ACCELERATOR_SPAWN_RATE_ROWS) {
  if (rateAt(row.normal) !== row.spawnCount) {
    throw new Error(`spawn rate at wave ${row.normal}: the chart has ${rateAt(row.normal)}, the SDK ${row.spawnCount}`);
  }
}
for (const reading of SPAWN_READINGS) {
  if (rateAt(reading.wave) !== reading.rate) {
    throw new Error(`spawn rate at wave ${reading.wave}: the chart has ${rateAt(reading.wave)}, the owner's screen ${reading.rate}`);
  }
}
const knowledge = require(path.join(dist, "knowledge/compartments/enemies.js"));
const eliteRows = require(path.join(dist, "data/charts/data.js")).ELITE_SPAWN_CHANCE_ROWS;
const spawnTypes = require(path.join(dist, "mechanics/waves/new-wave-spawn-type-chances.js"));
const infoConstants = require(path.join(dist, "mechanics/waves/info-enemy-constants.js"));
const heatUp = require(path.join(dist, "mechanics/enemies/overcharge-hit-scaling.js")).ENEMY_HEAT_UP_MULTIPLIER_PER_HIT;
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
  // Each speed must be the tier's weight times Tier 1's, as the panel has it.
  for (const name of ["Basic", "Fast", "Protector", "Vampire"]) {
    const ratio = panel.computeWaveInfoPanelEnemyExtras({ wave: 300, tier, tournament: false, enemyType: name }).speed
      / panel.computeWaveInfoPanelEnemyExtras({ wave: 300, tier: 1, tournament: false, enemyType: name }).speed;
    if (Math.abs(ratio / weight - 1) > 1e-6) {
      throw new Error(`tier ${tier}: ${name} speed is ${ratio} times Tier 1's, not the tier weight ${weight}`);
    }
  }
  // The Protector's share by wave band, from the wave each band opens.
  const protector = [];
  for (const band of spawnTypes.NEW_WAVE_PROTECTOR_SLOT_WAVE_BANDS_V29) {
    const chance = spawnTypes.newWaveProtectorChanceV29(tier, band);
    if (chance > 0) protector.push({ wave: band, chance });
  }
  // The elite chart's rows for this tier: from the wave each opens, the chance
  // one of each elite type spawns in a wave, and then of a second.
  const elites = [];
  for (const row of eliteRows) {
    const wave = Number.parseInt(row[1 + tier], 10);
    const single = Number.parseInt(row[1], 10);
    if (wave > 0 && single > 0) elites.push({ wave, single, double: Number.parseInt(row[0], 10) });
  }
  tiers.push({
    tier,
    enemy_health: keep(healthRatio),
    enemy_attack: keep(attackRatio),
    coins: coin.coinBonus,
    boss_every: bossEvery(tier),
    double_spawn: gates.waveUpdateThresholdGtePassRate(gates.newWaveEnemyDoubleSpawnThresholdV29({ tier })),
    mix_weight: keep(weight),
    protector_radius: keep(panel.computeWaveInfoPanelSummary(tier, 1000).protectorRadiusMeters / panel.computeWaveInfoPanelSummary(1, 1000).protectorRadiusMeters),
    protector,
    protector_gate: spawnTypes.newWaveProtectorWavesUntilNextCanSpawnV29(tier),
    elites,
  });
}

const out = {
  version: 4,
  source: "The Tower's Tier 1 enemies via TheTowerSDK 0.11.0 (MIT, TmRxJD), calibrated to the owner's screens. Generated by tools/import_tower_enemies.mjs.",
  readings: READINGS,
  health_drift: { per_wave: HEALTH_DRIFT_PER_WAVE, known_to_wave: HEALTH_DRIFT_KNOWN_TO },
  spawn_seconds: uptime.computeWaveCombatDurationSeconds(false),
  cooldown_seconds: keep(uptime.computeWaveInterCooldownSeconds(0, { tournament: false })),
  boss_every: 10,
  mix: MIX,
  tiers,
  enemy_cap: spawnCap.normal,
  elite_cap: spawnCap.elite,
  elite_type_cap: ELITE_PER_TYPE_CAP,
  boss_cap: spawnCap.boss,
  coin_decay: { after_waves: COIN_DECAY_AFTER_WAVES, share: knowledge.ENEMY_COIN_DECAY },
  mass_per_wave_alive: MASS_PER_WAVE_ALIVE,
  heat_up_per_hit: heatUp,
  kill_cash: KILL_CASH,
  protector: { damage_taken: knowledge.PROTECTOR_DAMAGE_MULTIPLIER, thorns_taken: PROTECTOR_THORNS_TAKEN, gate_step: 10 - spawnTypes.advanceNewWaveProtectorGateV29({ wavesUntilNext: 10 }).wavesUntilNext },
  elites: {
    vampire_drain: infoConstants.WAVE_INFO_VAMPIRE_TOWER_DAMAGE_MULT,
    ray_charge_seconds: RAY_CHARGE_SECONDS,
    scatter_splits: SCATTER_SPLITS,
  },
  spawn: { roll_seconds: spawnRoll, chart: SPAWN_RATES },
  types,
  basic_health: health,
  basic_attack: attack,
  basic_speed: speed,
  mass_growth: massGrowth,
  protector_radius: protectorRadius,
};
const outPath = path.join(path.dirname(new URL(import.meta.url).pathname), "..", "data", "tower", "enemies.json");
fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(out) + "\n");
console.log(`wrote ${LAST_WAVE} waves to ${path.relative(process.cwd(), outPath)}`);
console.log(`spawn: a roll every ${spawnRoll} s; rates ${SPAWN_RATES.map((r) => `${r.rate}@${r.wave}`).join(" ")}`);
for (const t of tiers) {
  console.log(`tier ${t.tier}: health ×${t.enemy_health}, attack ×${t.enemy_attack}, Coins ×${t.coins}, boss every ${t.boss_every}, double spawn ${t.double_spawn}, mix weight ${t.mix_weight}, Protector ${t.protector.map((p) => `${p.chance}%@${p.wave}`).join(" ") || "none"}, elites from wave ${t.elites[0].wave}`);
}
for (const r of READINGS) {
  console.log(`wave ${r.wave}: health ${health[r.wave - 1]} (screen ${r.health}), attack ${attack[r.wave - 1]} (screen ${r.attack})`);
}
