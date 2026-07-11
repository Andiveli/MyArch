# Wavy progress (ported, no Caelestia QML)

`samaelv2` does not import `Caelestia.Components`, `qs.components`, or vendor QML.

| Widget | Based on (reference only) | Implementation |
|--------|---------------------------|----------------|
| `widgets/MediaWavySeekBar.qml` | Caelestia `StyledSlider` (`wavy: true`) | Canvas sine + handle/remaining track |
| `widgets/MediaWavyRing.qml` | Caelestia `CircularProgress` (`wavy: true`) | `Shape` remainder arc + Canvas wavy stroke |

Defaults aligned with `SamaelCaelestiaMedia` bar drop:

- Seek: `waveFrequency: 5`, `waveDuration: 2000`, `lineWidth ≈ barHeight * 0.7`, `amplitudeMultiplier: 0.5`
- Ring: `sweepAngle: 180`, `waveFrequency: 8`, `waveAmplitude: 0.65`, `waveDuration: 2000`

## Optional plugin (lyrics only)

Synced lyrics still use the system Qt plugin from `caelestia-shell` AUR, isolated in `singletons/LyricsService.qml`. Media UI works without it; lyrics panel shows install hint if the plugin is missing.

To remove the plugin dependency entirely later: implement `LyricsService` with LRCLIB + local `.lrc` in pure QML/JS.
