import { test } from "node:test";
import assert from "node:assert/strict";
import { loadTokens, parseShadow, parseFont, parseEasing, resolveVars } from "../build.mjs";

const t = loadTokens();

test("별칭이 원본 색으로 풀린다", () => {
  assert.equal(t.color.accent.hex, "#2F5BEA");
  assert.equal(t.color["accent-soft"].hex, "#E6ECFD"); // DEC-005
  assert.equal(t.color["text-primary"].hex, "#171B26");
  assert.equal(t.color["bg-app"].hex, "#F3F4F7");
});

test("투명도 있는 색을 유지한다", () => {
  assert.deepEqual(t.color["border-hairline"], { r: 15, g: 23, b: 42, a: 0.06, hex: null });
});

test("모서리는 토큰 값(DEC-005)", () => {
  assert.deepEqual(t.radius, { xs: 6, sm: 8, md: 12, lg: 14, xl: 16, pill: 999 });
});

test("크기 · 간격", () => {
  assert.equal(t.size["tap-min"], 44);
  assert.equal(t.size["button-h"], 54);
  assert.equal(t.size["button-h-sm"], 44);
  assert.equal(t.space["20"], 20);
});

test("글자 11단계", () => {
  assert.equal(Object.keys(t.font).length, 11);
  assert.deepEqual(t.font.body, { weight: 500, size: 15, lineHeight: 1.5 });
  assert.deepEqual(t.font.display, { weight: 700, size: 52, lineHeight: 1 });
});

test("모션 시간 · 곡선", () => {
  assert.deepEqual(t.duration, { press: 100, fast: 160, base: 240, sheet: 320, progress: 400, "toast-hold": 3000 });
  assert.deepEqual(t.easing.standard, [0.2, 0, 0, 1]);
  assert.deepEqual(t.easing.sheet, [0.32, 0.72, 0, 1]);
});

test("그림자: 외곽선과 띄움", () => {
  assert.deepEqual(parseShadow("0 0 0 1.5px #171B26"), { x: 0, y: 0, blur: 0, spread: 1.5, color: { r: 23, g: 27, b: 38, a: 1, hex: "#171B26" } });
  assert.equal(t.shadow.float.blur, 30);
  assert.equal(t.shadow.float.y, 10);
});

test("해석 실패는 숨기지 않는다", () => {
  assert.equal(parseFont("bold 12px Arial"), null);
  assert.equal(parseEasing("ease-in"), null);
  assert.throws(() => resolveVars({ "--a": "var(--missing)" }), /정의되지 않은 토큰/);
});
