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
//   15.90 on waves 1, 2, 5, 8 and 22 of the owner's screens, and 32.18 and
//   131.72 at the levels their waves 50 and 100 stood on).
// - A basic enemy's health is the SDK's, unrounded (D120). The owner's waves
//   50 and 100 read it exactly at the level Enemy Level Skip left them on
//   (75.17 and 341.33), so the correction fitted to their earlier screens is
//   gone; those screens' health at waves 5, 8 and 22 sits 2-9% under the SDK
//   for a reason not yet known, and is kept below as unmatched.
// - Type multipliers and masses are the SDK's (mass sets how far Knockback
//   pushes). Type speeds are the owner's Wave Info (D122): the SDK's differ
//   for every type but the basic. The type mix is the owner's Wave Info at waves 1, 22,
//   50 and 100 (D120), as whole percents: fast, tank and ranged, with basic
//   the rest, as The Tower keeps it. The SDK can't recover it (91/3/3/3).
// - Wave timing: the SDK's 26 seconds of spawning, then the owner's 9-second
//   cooldown (their Wave Info and screen recording, D121; the SDK's is 8.7).
// - How fast enemies walk: speed 1 is 7.66 m a game second, from the owner's
//   screen recording (D121). The SDK gives speeds but no distances.
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

// Expand the checked horizon explicitly: node ... package --waves 10000.
const waveOption = process.argv.indexOf("--waves");
const LAST_WAVE = waveOption < 0 ? 6500 : Number(process.argv[waveOption + 1]);
if (!Number.isInteger(LAST_WAVE) || LAST_WAVE < 6500 || LAST_WAVE > 100000) {
  throw new Error("--waves must be a whole number from 6500 to 100000");
}
// The owner's Wave Info screens, Tier 1: a basic enemy's health and attack at
// the level each stood on, the wave less the Enemy Health or Attack Level Skip
// the screen shows (24, 25 and 29 September 2026).
const READINGS = [
  { wave: 1, health_level: 1, health: 2.35, attack_level: 1, attack: 1.18 },
  { wave: 2, health_level: 2, health: 3.31, attack_level: 2, attack: 1.39 },
  { wave: 5, attack_level: 5, attack: 2.3 },
  { wave: 8, attack_level: 8, attack: 3.56 },
  { wave: 22, attack_level: 22, attack: 15.9 },
  { wave: 50, health_level: 23, health: 75.17, attack_level: 32, attack: 32.18 },
  { wave: 100, health_level: 45, health: 341.33, attack_level: 63, attack: 131.72 },
];
// The earlier screens' health, which the SDK doesn't match: kept, not used.
const HEALTH_UNMATCHED = [
  { wave: 5, health: 7.2 },
  { wave: 8, health: 12.15 },
  { wave: 22, health: 63.11 },
];
// The owner's Wave Info, Tier 1, in whole percents (wave 22 on 24 September,
// the rest on 29 September). Basic is what's left.
const MIX = [
  { wave: 1, fast: 5, tank: 0, ranged: 0 },
  { wave: 22, fast: 7, tank: 6, ranged: 2 },
  { wave: 50, fast: 10, tank: 10, ranged: 6 },
  { wave: 100, fast: 11, tank: 13, ranged: 7 },
];
// The chart's Standard column, as it is printed (34 starts at both 600 and
// 750 there). The owner's own Wave Info read 15 at wave 22, which it agrees
// with, and 22 at wave 50 and 26 at wave 100 with the Wave Accelerator card at
// its full 100% (D120): it brings each rate in at half its wave.
const SPAWN_RATES = [
  [1, 10], [3, 11], [6, 15], [40, 17], [60, 19], [80, 20], [100, 22], [150, 24], [200, 26], [250, 28],
  [300, 30], [400, 32], [600, 34], [750, 34], [800, 36], [1000, 37], [1250, 38], [1500, 39], [2000, 40],
  [2500, 42], [3000, 44], [3500, 46], [4000, 48], [4500, 49], [5000, 50], [5500, 52], [6000, 54], [6500, 56],
].map(([wave, rate]) => ({ wave, rate }));
// The owner's screen recording of Tier 1 wave 1, 29 September (D121): 20
// basics walked 8.54-8.76 m a real second (8.69 on average) against the 30 m
// Range ring, and the wave bar filled its 26 seconds of spawning in 22.9 real
// seconds, so ×1 runs 1.135 times real time: 8.69 / 1.135 = 7.66 m a game
// second. The bar's second phase, the cooldown, filled 2.887 times faster:
// 26 / 9 = 2.889, so the cooldown is 9 seconds, not the SDK's 8.7.
const METRES_PER_SPEED = 7.66;
// Each type's speed as a basic's, from the owner's Wave Info on a new save's
// Tier 1 wave 1, 29 September (D122). The recording (D121) showed a fast
// enemy walking the 2.09 times a basic this screen says, so these are how
// enemies move. The SDK's panel has fast 2.31, tank, boss and Scatter 0.34,
// ranged 0.56, and the Protector, Vampire and Ray 0.22.
const TYPE_SPEEDS = { basic: 1, fast: 2.1, tank: 0.6, ranged: 1.2, boss: 0.4, protector: 0.4, vampire: 0.4, ray: 0.4, scatter: 0.6 };
const COOLDOWN_SECONDS = 9;
const SPAWN_READINGS = [
  { wave: 1, rate: 10, accelerator: 0 },
  { wave: 22, rate: 15, accelerator: 0 },
  { wave: 50, rate: 22, accelerator: 1 },
  { wave: 100, rate: 26, accelerator: 1 },
];
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

const input = (wave) => ({ wave, tier: 1, tournament: false });
const keep = (value) => Number(value.toPrecision(9));

const health = [];
const attack = [];
const speed = [];
const massGrowth = [];
const protectorRadius = [];
for (let wave = 1; wave <= LAST_WAVE; wave++) {
  health.push(keep(scaling.computeWaveBaseHealthRaw(input(wave))));
  attack.push(keep(scaling.computeWaveBaseDamage(input(wave))));
  speed.push(keep(panel.computeWaveInfoPanelEnemyExtras({ ...input(wave), enemyType: "Basic" }).speed));
  massGrowth.push(keep(panel.enemyMassWaveMult(wave)));
  protectorRadius.push(keep(panel.computeWaveInfoPanelSummary(1, wave).protectorRadiusMeters));
}

// Two decimals is what the screen shows; allow the last one either way.
for (const reading of READINGS) {
  for (const stat of ["health", "attack"]) {
    if (reading[stat] === undefined) continue;
    const got = (stat === "health" ? health : attack)[reading[`${stat}_level`] - 1];
    if (Math.abs(got - reading[stat]) > Math.max(0.011, reading[stat] * 0.003)) {
      throw new Error(`wave ${reading.wave} ${stat}: generated ${got}, screen ${reading[stat]}`);
    }
  }
}
for (let i = 0; i < MIX.length; i++) {
  const row = MIX[i];
  if (row.fast + row.tank + row.ranged > 100 || (i > 0 && row.wave <= MIX[i - 1].wave)) {
    throw new Error(`mix at wave ${row.wave}: over 100%, or out of order`);
  }
}

const types = {};
const sdkSpeeds = {};
for (const [id, name] of [["basic", "Basic"], ["fast", "Fast"], ["tank", "Tank"], ["ranged", "Ranged"], ["boss", "Boss"],
  ["protector", "Protector"], ["vampire", "Vampire"], ["ray", "Ray"], ["scatter", "Scatter"]]) {
  const typeSpeed = panel.computeWaveInfoPanelEnemyExtras({ ...input(1), enemyType: name }).speed;
  const mass = panel.computeWaveInfoPanelEnemyExtras({ ...input(1), enemyType: name }).mass;
  types[id] = { health: typeMults[name].hp, attack: typeMults[name].damage, speed: TYPE_SPEEDS[id], mass: keep(mass) };
  sdkSpeeds[id] = keep(typeSpeed);
}

// Tiers: the SDK's multipliers, checked constant across every wave.
const gates = require(path.join(dist, "mechanics/waves/update-spawn-gate-pass.js"));
const tierRows = require(path.join(dist, "data/tiers/data.js")).TIER_COIN_BONUS_ROWS;
const bossEvery = require(path.join(dist, "data/enemies/data.js")).bossWaveIntervalForTier;
const spawnCap = require(path.join(dist, "knowledge/compartments/enemies.js")).ENEMY_SPAWN_CAP;
const sdkSpawnRoll = require(path.join(dist, "mechanics/waves/spawn-gate-constants.js")).WAVE_SPAWN_TIMER_QUANTUM_SECONDS_V29;
// A roll every other tick of the SDK's timer: 104 rolls a wave, about 11
// enemies in wave 1, as the owner counted in The Tower (D135). At the SDK's
// 1/8 s (208 rolls, D124) wave 1 sent about 22, more than a fresh tower with
// no Cash can shoot, and fresh runs died on waves 1 to 3.
const SPAWN_ROLL_TICKS = 2;
const spawnRoll = sdkSpawnRoll * SPAWN_ROLL_TICKS;
const rateAt = (wave) => SPAWN_RATES.filter((row) => row.wave <= wave).at(-1).rate;
for (const row of require(path.join(dist, "data/charts/data.js")).WAVE_ACCELERATOR_SPAWN_RATE_ROWS) {
  if (rateAt(row.normal) !== row.spawnCount) {
    throw new Error(`spawn rate at wave ${row.normal}: the chart has ${rateAt(row.normal)}, the SDK ${row.spawnCount}`);
  }
}
// Wave Accelerator at share r brings each rate in at wave / (1 + r) (the
// SDK's chart columns), so a screen with it on reads the chart further on.
for (const reading of SPAWN_READINGS) {
  const chartWave = Math.floor(reading.wave * (1 + reading.accelerator));
  if (rateAt(chartWave) !== reading.rate) {
    throw new Error(`spawn rate at wave ${reading.wave}: the chart has ${rateAt(chartWave)}, the owner's screen ${reading.rate}`);
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
  version: 7,
  source: "The Tower's Tier 1 enemies via TheTowerSDK 0.11.0 (MIT, TmRxJD), calibrated to the owner's screens. Generated by tools/import_tower_enemies.mjs.",
  readings: READINGS,
  health_unmatched: HEALTH_UNMATCHED,
  spawn_seconds: uptime.computeWaveCombatDurationSeconds(false),
  cooldown_seconds: COOLDOWN_SECONDS,
  metres_per_speed: METRES_PER_SPEED,
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
for (const series of [out.basic_health, out.basic_attack, out.basic_speed, out.mass_growth, out.protector_radius]) {
  if (series.some(value => !Number.isFinite(value) || value < 0)) {
    throw new Error("The requested horizon contains invalid numbers; no data was written");
  }
}
fs.writeFileSync(outPath, JSON.stringify(out) + "\n");
console.log(`wrote ${LAST_WAVE} waves to ${path.relative(process.cwd(), outPath)}`);
console.log(`spawn: a roll every ${spawnRoll} s (the SDK's ${sdkSpawnRoll} s × ${SPAWN_ROLL_TICKS}); rates ${SPAWN_RATES.map((r) => `${r.rate}@${r.wave}`).join(" ")}`);
for (const t of tiers) {
  console.log(`tier ${t.tier}: health ×${t.enemy_health}, attack ×${t.enemy_attack}, Coins ×${t.coins}, boss every ${t.boss_every}, double spawn ${t.double_spawn}, mix weight ${t.mix_weight}, Protector ${t.protector.map((p) => `${p.chance}%@${p.wave}`).join(" ") || "none"}, elites from wave ${t.elites[0].wave}`);
}
for (const r of READINGS) {
  const shown = (stat, values) => r[stat] === undefined ? "" : ` ${stat} ${values[r[`${stat}_level`] - 1]} at level ${r[`${stat}_level`]} (screen ${r[stat]})`;
  console.log(`wave ${r.wave}:${shown("health", health)}${shown("attack", attack)}`);
}
for (const r of HEALTH_UNMATCHED) {
  console.log(`wave ${r.wave}: health ${health[r.wave - 1]}, an earlier screen ${r.health} (×${(r.health / health[r.wave - 1]).toFixed(3)}), unmatched`);
}
console.log(`cooldown ${COOLDOWN_SECONDS} s (the SDK's ${keep(uptime.computeWaveInterCooldownSeconds(0, { tournament: false }))}); speed 1 is ${METRES_PER_SPEED} m/s`);
console.log(`type speeds ${Object.entries(TYPE_SPEEDS).map(([id, s]) => `${id} ${s} (SDK ${sdkSpeeds[id]})`).join(", ")}`);
console.log(`mix: ${MIX.map((m) => `${100 - m.fast - m.tank - m.ranged}/${m.fast}/${m.tank}/${m.ranged}@${m.wave}`).join(" ")}`);
