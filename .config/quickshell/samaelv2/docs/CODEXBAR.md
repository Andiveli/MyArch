# CodexBar (Usage pill)

samaelv2 middle pill **AI** chip → `UsageSurface` runs `codexbar usage --format json` (see `CodexBarService.qml`).

## Setup: Codex + Grok (subscriptions)

Config file: `~/.config/codexbar/config.json`

Only enable what you use — the Usage pill lists **enabled** providers only.

```bash
codexbar config enable --provider codex
codexbar config enable --provider grok
codexbar config disable --provider openai   # unless you use API billing separately
codexbar config providers | grep -E 'codex|grok|openai'
codexbar usage --format json --pretty       # should show codex + grok only
```

### Codex (ChatGPT / Codex subscription)

- OAuth / web dashboard (Codex CLI session when cookies needed).
- No OpenAI **API** key required for this provider id.

### Grok (xAI subscription)

- Enable provider; sign in via CodexBar / provider flow as usual.

### OpenAI provider id

`openai` in CodexBar is **API usage**, not your Codex subscription. Disable it if you only use **codex** + **grok**.

### Shell

Hypr: **Super+Shift+A** → `quickshell:samaelUsageToggle`.

In surface (keyboard-only):

- **Tabs**: **h** / **l**, **Tab**, **k** (prev provider), **j** → action list
- **Actions**: **j** / **k**, **Enter** or **l** run, **h** → tabs, **r** refresh anytime, **Esc** (back / close)

Provider icons from upstream [steipete/CodexBar](https://github.com/steipete/CodexBar) `Sources/CodexBar/Resources/ProviderIcon-*.svg`, vendored as **PNG** under `assets/codexbar/` (Quickshell `Image` is unreliable with local SVG). Re-rasterize after SVG updates: `rsvg-convert -w 96 -h 96 ProviderIcon-<id>.svg -o ProviderIcon-<id>.png`.

## Usage UI (samaelv2)

The surface follows CodexBar's native menu hierarchy: compact provider tabs, selected-provider header, **Session / Weekly / other quota lanes**, Extra usage, Cost, dashboard/status actions, and account/source metadata.

Linux provides two complementary CLI payloads:

- `codexbar usage --format json` — quota windows, resets, identity, credits.
- `codexbar cost --format json` — local Codex log scan with session/30-day USD estimates, tokens, cache/input/output totals, and top model.

The dollar values are local token-cost estimates, not charges against the ChatGPT subscription invoice. macOS-only web/dashboard details remain unavailable until upstream exposes them through the Linux CLI.