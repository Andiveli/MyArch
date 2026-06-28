// Performance & high refresh rate tuning for Zen (Firefox) on Linux/Hyprland
// Goal: match or beat Edge smoothness on interactive canvas/WebGL apps (Onshape, Monkeytype)

// === Frame rate / compositor timing ===
// Explicitly target your monitor's refresh rate. 0 = auto (sometimes sticks to 60),
// 60 = match your 60Hz panel for consistent pacing. Some use -1 for unlimited.
user_pref("layout.frame_rate", 0); // auto — monitor es 60.069Hz, capaz auto-detect da mejor timing que fijar 60

// Newer content frame scheduling pref (harmless to set both)
user_pref("layout.display-list.frame-rate", 0);

// === WebRender Compositor — OFF ===
// Forzarlo rompe scroll en Skylake (blocklisteado por Mozilla) siempre,
// con vsync ON u OFF. Nos quedamos con basic compositor.
user_pref("gfx.webrender.compositor", false);
user_pref("gfx.webrender.compositor.force-enabled", false);

// === Canvas & 2D acceleration (critical for Onshape) ===
// Soft-enable, pero force=false para respetar blocklist de Skylake
user_pref("gfx.canvas.accelerated", true);
user_pref("gfx.canvas.accelerated.force-enabled", false);

// Out-of-process canvas rasterization (helps move work off main thread)
user_pref("gfx.canvas.accelerated.cache-size", 512);

// === Layers / GPU acceleration ===
// force-enabled=false para que Firefox decida según el blocklist
user_pref("layers.acceleration.force-enabled", false);

// === Input & scroll smoothness ===
user_pref("general.smoothScroll", true);
user_pref("general.smoothScroll.mouseWheel", true);
user_pref("general.smoothScroll.other", true);

// APZ (Async Pan/Zoom) — better input responsiveness for web apps
user_pref("apz.allow_zooming", true);
user_pref("apz.drag.enabled", false); // OFF — reduce posible latencia extra en input events

// For CAD-like apps sometimes people prefer less "physics" overscroll
user_pref("apz.overscroll.enabled", false);

// === WebGL hints (Onshape uses WebGL heavily) ===
user_pref("webgl.force-enabled", true);
user_pref("webgl.disabled", false);

// === Misc that can affect perceived smoothness ===
user_pref("ui.prefersReducedMotion", 0); // ensure animations are not reduced

// Wayland-specific vsync control.
user_pref("widget.wayland.vsync.enabled", false); // OFF — con immediate de Hyprland, Firefox no necesita su propio vsync

// WebGL / DMABUF acceleration on Wayland (helps Onshape canvas/WebGL)
user_pref("widget.wayland-dmabuf-webgl.enabled", true);
user_pref("widget.wayland-dmabuf-vaapi.enabled", true);

// === Frame pacing extras ===
// HW vsync explícito para Wayland (más parejo que el software fallback)
user_pref("gfx.vsync.hw-vsync.enabled", true);
// OpenGL compositor thread — mueve compositing a su propio hilo, menos latency
user_pref("layers.offmainthreadcomposition.async-pan-zoom", true);

// Notes:
// - After editing, fully restart Zen.
// - Check about:support > Graphics section: WebRender (shader) activo, compositor NO forzado.
// - Con `immediate` de Hyprland activo, el scroll NO debería romperse porque el
//   compositor de Firefox ya no está forzado — el bug ERA el compositor, no immediate.
// - Si ves tearing, desactivar `immediate` y reportar.
