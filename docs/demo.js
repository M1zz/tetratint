// TetraTint 웹 체험: 라이트 색 하나로 4가지 변형을 만들고 배경 대비를 잰다.
// 규칙은 앱과 같다. ColorMath(RGB · HSL · WCAG 휘도)와 AppearanceSet.VariantDeriver,
// 배지 기준은 VariantCard.contrastBadge(4.5 이상 AA, 3 이상 UI 3:1, 그 밑은 낮음), 프리셋은 SystemColorData.tints.
(() => {
  const root = document.getElementById("demo");
  if (!root) return;
  const T = JSON.parse(root.dataset.text);
  const PRESETS = ["#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#00C7BE", "#30B0C7",
                   "#32ADE6", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55", "#A2845E"];
  const clamp = (v, lo, hi) => Math.min(Math.max(v, lo), hi);

  const parseHex = s => {
    let h = s.trim().replace(/^#/, "");
    if (h.length === 3) h = [...h].map(c => c + c).join("");
    return /^[0-9a-f]{6}$/i.test(h) ? [0, 2, 4].map(i => parseInt(h.slice(i, i + 2), 16)) : null;
  };
  const toHex = rgb => "#" + rgb.map(v => Math.round(clamp(v, 0, 255)).toString(16).padStart(2, "0")).join("").toUpperCase();
  function toHSL([r, g, b]) {
    r /= 255; g /= 255; b /= 255;
    const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2;
    let h = 0, s = 0;
    if (mx !== mn) {
      const d = mx - mn;
      s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
      h = mx === r ? (g - b) / d + (g < b ? 6 : 0) : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
      h /= 6;
    }
    return { h: h * 360, s: s * 100, l: l * 100 };
  }
  function toRGB({ h, s, l }) {
    const hh = h / 360, ss = clamp(s / 100, 0, 1), ll = clamp(l / 100, 0, 1);
    if (ss === 0) return [ll * 255, ll * 255, ll * 255];
    const q = ll < 0.5 ? ll * (1 + ss) : ll + ss - ll * ss, p = 2 * ll - q;
    const hue = t => { if (t < 0) t += 1; if (t > 1) t -= 1;
      return t < 1 / 6 ? p + (q - p) * 6 * t : t < 1 / 2 ? q : t < 2 / 3 ? p + (q - p) * (2 / 3 - t) * 6 : p; };
    return [hue(hh + 1 / 3) * 255, hue(hh) * 255, hue(hh - 1 / 3) * 255];
  }
  const lum = rgb => { const c = rgb.map(v => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; });
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]; };
  const contrast = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); };
  const WHITE = [255, 255, 255], BLACK = [0, 0, 0];

  // VariantDeriver.derive(fromLight:)
  function derive(base) {
    const hsl = toHSL(base);
    const dark = { h: hsl.h, s: clamp(hsl.s + 3, 0, 100), l: clamp(hsl.l + 5, 2, 96) };
    let l = hsl.l, n = 0;
    const s = clamp(hsl.s + 8, 0, 100);
    if (contrast(parseHex(toHex(base)), WHITE) >= 4.5) l = clamp(l - 5, 3, 100);
    while (contrast(toRGB({ h: hsl.h, s, l }), WHITE) < 4.5 && l > 3 && n++ < 150) l -= 1;
    const lightHC = toHex(toRGB({ h: hsl.h, s, l }));
    let dl = dark.l; n = 0;
    if (contrast(toRGB(dark), BLACK) >= 7) dl = clamp(dl + 5, 0, 97);
    while (contrast(toRGB({ ...dark, l: dl }), BLACK) < 7 && dl < 97 && n++ < 150) dl += 1;
    return [toHex(base), lightHC, toHex(toRGB(dark)), toHex(toRGB({ ...dark, l: dl }))];
  }

  const CARDS = [[T.light, WHITE], [T.lightHC, WHITE], [T.dark, BLACK], [T.darkHC, BLACK]];
  root.innerHTML = `
    <div class="tt-input">
      <label class="tt-pick"><input type="color" value="#007aff" aria-label="${T.picker}"><span aria-hidden="true"></span></label>
      <input type="text" class="tt-hex" value="#007AFF" spellcheck="false" autocomplete="off" aria-label="${T.hex}">
    </div>
    <div class="tt-presets" role="group" aria-label="${T.presets}">
      ${PRESETS.map(c => `<button type="button" style="--c:${c}" data-hex="${c}" aria-label="${c}"></button>`).join("")}
    </div>
    <div class="tt-cards" aria-live="polite">${CARDS.map(([name], i) =>
      `<div class="tt-card${i > 1 ? " dark" : ""}"><div class="tt-name">${name}</div><div class="tt-row"><span class="tt-swatch"></span><b class="tt-code"></b></div>
       <div class="tt-ratio"></div><div class="tt-sample"><span class="tt-btn">${T.button}</span><span class="tt-tint">${T.tint}</span></div><span class="tt-badge"></span></div>`).join("")}</div>
    <p class="muted small tt-note">${T.footnote}</p>`;

  const $ = s => root.querySelector(s), picker = $("input[type=color]"), hex = $(".tt-hex");
  function render(rgb) {
    derive(rgb).forEach((h, i) => {
      const card = root.querySelectorAll(".tt-card")[i], c = parseHex(h), r = contrast(c, CARDS[i][1]);
      const [label, cls] = r >= 4.5 ? [T.aa, "aa"] : r >= 3 ? ["UI 3:1", "ui"] : [T.low, "low"];
      card.style.setProperty("--v", h);
      card.style.setProperty("--on", contrast(c, WHITE) >= 3 ? "#fff" : "#000");
      card.querySelector(".tt-code").textContent = h;
      card.querySelector(".tt-ratio").textContent = T.ratio.replace("%@", r.toFixed(2));
      const badge = card.querySelector(".tt-badge");
      badge.textContent = label; badge.className = "tt-badge " + cls;
    });
    picker.value = toHex(rgb).toLowerCase();
    $(".tt-pick span").style.background = toHex(rgb);
    root.querySelectorAll(".tt-presets button").forEach(b => b.setAttribute("aria-pressed", b.dataset.hex === toHex(rgb)));
  }
  picker.addEventListener("input", () => { hex.value = picker.value.toUpperCase(); render(parseHex(picker.value)); });
  hex.addEventListener("input", () => { const c = parseHex(hex.value); hex.classList.toggle("bad", !c); if (c) render(c); });
  root.addEventListener("click", e => {
    const b = e.target.closest("[data-hex]");
    if (b) { hex.value = b.dataset.hex; hex.classList.remove("bad"); render(parseHex(b.dataset.hex)); }
  });
  render(parseHex("#007AFF"));
})();
