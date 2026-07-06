# 💻 Dotfiles - Configuración Personal

> **¡CUIDADO!** Antes de tocar esto, hacé backup. Si rompés algo, es por tu cuenta.

## 📋 ¿Qué tenés acá?

Estos son los archivos que realmente importan y están trackeados en Git:

```
alacritty/     - Terminal
dunst/         - Notificaciones
ghostty/       - Terminal (alternativa)
gtk-*/         - Temas GTK
hypr/          - Hyprland (Window Manager)
kitty/         - Terminal
nvim/          - Neovim + LazyVim
opencode/      - Tema para Discord
rofi/          - Application Launcher
swaync/        - Centro de notificaciones
waybar/        - Barra de estado
wlogout/       - Pantalla de logout
zellij/        - Terminal Multiplexer
quickshell/    - Quickshell (producción: `qs -c samael` — ver quickshell/README.md)
```

## 🚀 Instalación

### 1. Instalar dependencias

```bash
# En Arch/Manjaro:
sudo pacman -S alacritty dunst ghostty hyprland kitty neovim rofi swaync waybar wlogout zellij

# Fonts (importantes para los iconos):
sudo pacman -S ttf-jetbrains-mono-nerd

# Notificación del sistema:
sudo pacman -S libnotify

# Para Hyprland y sus dependencies:
sudo pacman -S hyprland hyprpaper hyprlock hypridle hyprcursor xdg-desktop-portal-hyprland
```

### 2. Clonar y symlink

```bash
# Clonar el repo (NO directamente en ~/.config)
git clone <TU-REPO-URL> ~/dotfiles-temp

# Backup de tus configs existentes
mkdir -p ~/.config-backup/$(date +%Y%m%d_%H%M%S)
cp -r ~/.config/alacritty ~/.config-backup/$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
# Hacer esto para cada carpeta...

# Crear symlinks
cd ~/dotfiles-temp
stow -t ~/.config alacritty dunst ghostty hypr kitty nvim opencode rofi swaync waybar wlogout zellij
```

### 3. Post-instalación

```bash
# Recargar las configuraciones
# Para Hyprland (si está corriendo):
hyprctl reload

# Para que se carguen los temas GTK:
gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Mocha-Standard-Blue-Dark"
```

## 🔄 Cómo VOLVER ATRÁS (ROLLBACK)

### Opción A: Usando el backup

```bash
# Recuperar todo del backup
cp -r ~/.config-backup/$(date +%Y%m%d_%H%M%S)/* ~/.config/

# O si sabés qué carpeta querés revertir:
rm -rf ~/.config/hypr
cp -r ~/.config-backup/$(date +%Y%m%d_%H%M%S)/hypr ~/.config/
```

### Opción B: Volver al último commit del repo

```bash
cd ~/dotfiles-temp
git log --oneline -5  # Ver los commits
git reset --hard <hash-del-commit-bueno>

# Re-aplicar los symlinks
stow -t ~/.config -R alacritty dunst ghostty hypr kitty nvim opencode rofi swaync waybar wlogout zellij
```

### Opción C: Desinstalar todo (nuclear option)

```bash
# Borrar las configs trackeadas
rm -rf ~/.config/alacritty ~/.config/dunst ~/.config/ghostty ~/.config/hypr ~/.config/kitty ~/.config/nvim ~/.config/opencode ~/.config/rofi ~/.config/swaync ~/.config/waybar ~/.config/wlogout ~/.config/zellij

# Restaurar desde backup (si lo tenés)
cp -r ~/.config-backup/TU-BACKUP/* ~/.config/
```

## ⚠️ ANTES DE EXPERIMENTAR CON HYPRLAND

Si vas a probar otra config de Hyprland:

1. **HACÉ BACKUP AHORA:**
   ```bash
   cp -r ~/.config/hypr ~/.config/hypr-backup-$(date +%Y%m%d_%H%M%S)
   ```

2. **Guardá el hash actual:**
   ```bash
   cd ~/dotfiles-temp
   git rev-parse HEAD > ~/.hypr-working-hash
   ```

3. **Para volver:**
   ```bash
   rm -rf ~/.config/hypr
   cp -r ~/.config/hypr-backup-$(cat ~/.hypr-working-hash) ~/.config/hypr
   ```

## 🔧 Personalización rápida

### Cambiar壁纸 en Hyprland
```bash
# Editá el wallpaper default
nano ~/.config/hypr/UserConfigs/Startup_Apps.conf
# Buscá la línea que dice "wallpaper =" y cambiá la ruta

# Recargá
hyprctl reload
```

### Temas en Neovim
```bash
# Los temas están en ~/.config/nvim/lua/plugins/colorscheme.lua
# Editá esa línea y reiniciá nvim
```

### Fonts
Si no ves bien los iconos, instalá:
```bash
sudo pacman -S noto-fonts-emoji ttf-font-awesome
yay -S ttf-nerd-fonts-symbols-2048-em
```

## 🐛 Troubleshooting

### Hyprland no inicia
- Verificá que tu GPU esté soportada: `lspci | grep VGA`
- Revisá el log: `journalctl -b -0 | grep -i hypr`
- Probá con la config de backup: ver sección "ROLLBACK"

### Los symlinks no funcionan
- Verificá que no existan las carpetas originales
- Usá `stow -vvv -t ~/.config hypr` para ver qué está pasando

### Neovim da errores
- Borrá `~/.config/nvim/lazy-lock.json` y reiniciá nvim
- O re-instalá todo: `rm -rf ~/.local/share/nvim`

---

**Recordatorio:** Si todo se va al carajo, tu respaldo es tu mejor amigo. ¡No digas que no te avisé!