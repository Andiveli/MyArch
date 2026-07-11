# 💻 MyArch Dotfiles

Configs personales para replicar mi entorno en una máquina nueva.

## 📦 Paquetes necesarios

### Esenciales (trackeados en el repo)

| Categoría | Paquete |
|-----------|---------|
| **WM** | `hyprland`, `hyprlock`, `hypridle` |
| **Terminal** | `ghostty`, `kitty` |
| **Editor** | `neovim` |
| **Shell** | `zsh`, `tmux` |
| **Audio visualizer** | `cava` |
| **System info** | `fastfetch` |
| **Tiling helper** | `pyprland` |

### AUR (necesitan yay/paru)

| Paquete | Para qué |
|---------|----------|
| `pokemon-colorscripts-git` | Pokemones en fastfetch |
| `herdr-bin` | Gestor de tareas/herramientas |
| `quickshell-git` | Samael shell |

### Runtime (opcionales, según scripts de hypr)

| Paquete | Para qué |
|---------|----------|
| `wallust` | Temas basados en wallpaper |
| `swww` | Wallpaper animated |
| `wlogout` | Menú de sesión |
| `rofi` | Lanzador/menús |
| `waybar` | Barra de estado |
| `dunst` / `swaync` | Notificaciones |

## 🚀 Instalación en máquina nueva

```zsh
# 1. Clonar el repo
git clone --bare https://github.com/Andiveli/MyArch.git $HOME/dotfiles

# 2. Alias para usar los dotfiles
alias dotfiles='git --git-dir=$HOME/dotfiles --work-tree=$HOME'

# 3. Hacer checkout (puede dar conflictos si ya existen archivos)
dotfiles checkout
# Si falla, forzar: dotfiles checkout -f

# 4. Opcional: ocultar untracked files del status
dotfiles config status.showUntrackedFiles no
```

## 📁 Lo que trackea

```
.config/cava/               ← Audio visualizer
.config/fastfetch/           ← System info (con pokemon)
.config/ghostty/             ← Terminal
.config/herdr/               ← Gestor de tareas
.config/hypr/                ← Hyprland WM + scripts
.config/kitty/               ← Terminal
.config/nvim/                ← Neovim (LazyVim)
.config/pypr/                ← Pyprland (tiling)
.config/quickshell/samaelv2/ ← Samael shell
.zshrc, .tmux.conf, ...      ← Home dotfiles
```
