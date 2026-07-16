# CodexBar (Usage pill)

samaelv2 middle pill **AI** chip → `UsageSurface` runs `codexbar usage --format json` (see `CodexBarService.qml`).

## Providers: Codex + OpenAI

Config file (CodexBar): `~/.config/codexbar/config.json`

### Enable both (CLI)

```bash
codexbar config enable --provider codex
codexbar config enable --provider openai
codexbar config providers | grep -E 'codex|openai'
```

### Codex (OpenAI subscription / Plus)

- Uses **OAuth / web dashboard** (Codex CLI cookies when needed).
- No API key in config for the default Codex provider.
- Check: `codexbar usage --format json --provider codex --pretty`

### OpenAI (API usage)

OpenAI provider needs an **API key** stored in CodexBar config:

```bash
# Option A — env var (do not commit)
printf '%s' "$OPENAI_API_KEY" | codexbar config set-api-key --provider openai --stdin

# Option B — paste once (interactive)
codexbar config set-api-key --provider openai --api-key 'sk-...'
```

Verify:

```bash
codexbar usage --format json --provider openai --pretty
```

If you see `No available fetch strategy for openai`, the key is missing or invalid.

### Shell shortcut

Hypr: **Super+Shift+A** → `quickshell:samaelUsageToggle` (Usage / CodexBar menu).

Inside surface: **Tab** / **j** / **k** switch provider, **r** refresh, **Esc** close.

## Other providers

Same pattern: `codexbar config enable --provider grok` (etc.) and `set-api-key` where required.