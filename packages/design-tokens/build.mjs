// 디자인 토큰 생성기 — src/*.css(Claude Design 원본) → dist/tokens.json · iOS PumTokens.swift
// 사용: node build.mjs          생성
//       node build.mjs --check  생성물이 최신인지 검사(다르면 exit 1)
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..", "..");
const SOURCES = ["colors.css", "spacing.css", "typography.css", "motion.css"];
export const OUTPUTS = {
  json: join(here, "dist", "tokens.json"),
  swift: join(root, "Pum", "Pum", "DesignSystem", "Generated", "PumTokens.swift"),
};

// ---------- 파싱 ----------
export function parseCustomProperties(css) {
  const body = css.replace(/\/\*[\s\S]*?\*\//g, "");
  const props = {};
  for (const m of body.matchAll(/(--[a-z0-9-]+)\s*:\s*([^;]+);/g)) {
    props[m[1]] = m[2].trim();
  }
  return props;
}

export function resolveVars(props) {
  const out = {};
  const resolve = (value, seen = new Set()) =>
    value.replace(/var\((--[a-z0-9-]+)\)/g, (_, name) => {
      if (seen.has(name)) throw new Error(`순환 참조: ${name}`);
      if (!(name in props)) throw new Error(`정의되지 않은 토큰: ${name}`);
      return resolve(props[name], new Set([...seen, name]));
    });
  for (const [k, v] of Object.entries(props)) out[k] = resolve(v);
  return out;
}

export function parseColor(value) {
  const hex = value.match(/^#([0-9a-f]{6})$/i);
  if (hex) {
    const n = parseInt(hex[1], 16);
    return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255, a: 1, hex: `#${hex[1].toUpperCase()}` };
  }
  const rgba = value.match(/^rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)$/);
  if (rgba) {
    const [r, g, b, a] = rgba.slice(1).map(Number);
    return { r, g, b, a, hex: null };
  }
  return null;
}

const px = (v) => {
  const m = v.match(/^(-?[\d.]+)px$/);
  return m ? Number(m[1]) : null;
};
const ms = (v) => {
  const m = v.match(/^([\d.]+)ms$/);
  return m ? Number(m[1]) : null;
};

export function parseShadow(value) {
  // "0 0 0 1px rgba(...)" = 외곽선(spread), "0 10px 30px rgba(...)" = 그림자
  const m = value.match(/^((?:-?[\d.]+(?:px)?\s+){2,3}-?[\d.]+(?:px)?)\s+(rgba\([^)]*\)|#[0-9a-f]{6})$/i);
  if (!m) return null;
  const lengths = m[1].trim().split(/\s+/);
  if (lengths.length < 3 || lengths.length > 4) return null;
  const [x, y, blur, spread] = [...lengths, "0"].slice(0, 4).map((s) => (s === "0" ? 0 : px(s)));
  const color = parseColor(m[2]);
  if ([x, y, blur, spread].some((n) => n === null) || !color) return null;
  return { x, y, blur, spread, color };
}

export function parseFont(value) {
  // "700 52px/1 'Pretendard Variable', ..."
  const m = value.match(/^(\d{3})\s+([\d.]+)px\/([\d.]+)\s/);
  if (!m) return null;
  return { weight: Number(m[1]), size: Number(m[2]), lineHeight: Number(m[3]) };
}

export function parseEasing(value) {
  const m = value.match(/^cubic-bezier\(([^)]+)\)$/);
  if (!m) return null;
  const pts = m[1].split(",").map((s) => Number(s.trim()));
  return pts.length === 4 && pts.every((n) => !Number.isNaN(n)) ? pts : null;
}

export function loadTokens(srcDir = join(here, "src")) {
  const raw = {};
  for (const f of SOURCES) Object.assign(raw, parseCustomProperties(readFileSync(join(srcDir, f), "utf8")));
  const v = resolveVars(raw);
  const t = { color: {}, space: {}, radius: {}, size: {}, shadow: {}, font: {}, tracking: {}, duration: {}, easing: {}, fontFamily: null };
  for (const [name, value] of Object.entries(v)) {
    const key = name.slice(2);
    if (key === "font-sans") t.fontFamily = value;
    else if (key === "font-numeric") continue; // tabular-nums — 구현에서 적용
    else if (key.startsWith("shadow-")) t.shadow[key.slice(7)] = parseShadow(value) ?? fail(name, value);
    else if (key.startsWith("radius-")) t.radius[key.slice(7)] = px(value) ?? fail(name, value);
    else if (key.startsWith("space-")) t.space[key.slice(6)] = px(value) ?? fail(name, value);
    else if (key.startsWith("tracking-")) t.tracking[key.slice(9)] = px(value) ?? fail(name, value);
    else if (key.startsWith("text-") && parseFont(value)) t.font[key.slice(5)] = parseFont(value);
    else if (key.startsWith("dur-") || key === "toast-hold") t.duration[key.replace(/^dur-/, "")] = ms(value) ?? fail(name, value);
    else if (key.startsWith("ease-")) t.easing[key.slice(5)] = parseEasing(value) ?? fail(name, value);
    else if (parseColor(value)) t.color[key] = parseColor(value);
    else if (px(value) !== null) t.size[key] = px(value);
    else fail(name, value);
  }
  return t;
}

function fail(name, value) {
  throw new Error(`해석할 수 없는 토큰 값: ${name}: ${value}`);
}

// ---------- 출력 ----------
const camel = (s) => s.replace(/-([a-z0-9])/g, (_, c) => c.toUpperCase());
const num = (n) => (Number.isInteger(n) ? `${n}` : `${n}`);
const unit = (n) => (n / 255).toFixed(4).replace(/0+$/, "").replace(/\.$/, ".0");

function swiftColor(c) {
  return `Color(.sRGB, red: ${unit(c.r)}, green: ${unit(c.g)}, blue: ${unit(c.b)}, opacity: ${num(c.a)})`;
}

const SWIFT_WEIGHT = { 400: ".regular", 500: ".medium", 600: ".semibold", 700: ".bold", 800: ".heavy" };

export function renderSwift(t) {
  const L = [];
  L.push("// 자동 생성 파일 — 직접 고치지 마세요.");
  L.push("// 원본: packages/design-tokens/src/*.css (Claude Design tokens) · 생성: node packages/design-tokens/build.mjs");
  L.push("import SwiftUI", "");
  L.push("nonisolated enum PumTokens {");
  L.push("    nonisolated enum ColorToken {");
  for (const [k, c] of Object.entries(t.color)) {
    L.push(`        /// --${k}${c.hex ? ` ${c.hex}` : ` rgba(${c.r}, ${c.g}, ${c.b}, ${c.a})`}`);
    L.push(`        static let ${camel(k)} = ${swiftColor(c)}`);
  }
  L.push("    }", "");
  const numberEnum = (name, obj, prefix) => {
    L.push(`    nonisolated enum ${name} {`);
    for (const [k, n] of Object.entries(obj)) {
      const id = /^\d/.test(k) ? `${prefix}${k}` : camel(k);
      L.push(`        static let ${id}: CGFloat = ${num(n)}`);
    }
    L.push("    }", "");
  };
  numberEnum("Space", t.space, "s");
  numberEnum("Radius", t.radius, "r");
  numberEnum("Size", t.size, "s");
  numberEnum("Tracking", t.tracking, "t");
  L.push("    nonisolated struct Shadow: Sendable {");
  L.push("        let x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat, color: Color");
  for (const [k, s] of Object.entries(t.shadow)) {
    L.push(`        static let ${camel(k)} = Shadow(x: ${num(s.x)}, y: ${num(s.y)}, blur: ${num(s.blur)}, spread: ${num(s.spread)}, color: ${swiftColor(s.color)})`);
  }
  L.push("    }", "");
  L.push("    nonisolated struct FontToken: Sendable {");
  L.push("        let size: CGFloat, weight: Font.Weight, lineHeight: CGFloat");
  for (const [k, f] of Object.entries(t.font)) {
    L.push(`        static let ${camel(k)} = FontToken(size: ${num(f.size)}, weight: ${SWIFT_WEIGHT[f.weight] ?? fail("font-weight", f.weight)}, lineHeight: ${num(f.lineHeight)})`);
  }
  L.push("    }", "");
  L.push("    nonisolated enum Duration {");
  for (const [k, n] of Object.entries(t.duration)) L.push(`        static let ${camel(k)}: Double = ${n / 1000}`);
  L.push("    }", "");
  L.push("    nonisolated struct Easing: Sendable {");
  L.push("        let c0x: Double, c0y: Double, c1x: Double, c1y: Double");
  for (const [k, p] of Object.entries(t.easing)) {
    L.push(`        static let ${camel(k)} = Easing(c0x: ${p[0]}, c0y: ${p[1]}, c1x: ${p[2]}, c1y: ${p[3]})`);
  }
  L.push("    }", "");
  L.push(`    static let fontFamily = ${JSON.stringify(t.fontFamily)}`);
  L.push("}", "");
  return L.join("\n");
}

export function renderJson(t) {
  return JSON.stringify(t, null, 2) + "\n";
}

// ---------- 실행 ----------
function main() {
  const check = process.argv.includes("--check");
  const t = loadTokens();
  const files = { [OUTPUTS.json]: renderJson(t), [OUTPUTS.swift]: renderSwift(t) };
  let stale = [];
  for (const [path, content] of Object.entries(files)) {
    if (check) {
      if (!existsSync(path) || readFileSync(path, "utf8") !== content) stale.push(path);
    } else {
      mkdirSync(dirname(path), { recursive: true });
      writeFileSync(path, content);
      console.log(`생성: ${path.replace(root + "/", "")}`);
    }
  }
  if (check) {
    if (stale.length) {
      console.error("생성물이 원본과 다릅니다. `node packages/design-tokens/build.mjs`를 실행하세요:\n" + stale.map((p) => "  " + p.replace(root + "/", "")).join("\n"));
      process.exit(1);
    }
    console.log(`토큰 생성물 최신: 색 ${Object.keys(t.color).length} · 간격 ${Object.keys(t.space).length} · 모서리 ${Object.keys(t.radius).length} · 글자 ${Object.keys(t.font).length} · 모션 ${Object.keys(t.duration).length}`);
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
