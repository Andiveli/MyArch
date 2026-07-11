# 🚀 Mi Configuración de Neovim (LazyVim)

Una configuración robusta de Neovim basada en LazyVim, optimizada para desarrollo full-stack con soporte AI y herramientas modernas.

## 📋 Requisitos del Sistema

### Dependencias Esenciales

```bash
# Neovim (v0.9.0+)
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
sudo mv nvim.appimage /usr/local/bin/nvim
```

### Lenguajes y Runtimes

#### Node.js (v18+ obligatorio, v22+ recomendado)
```bash
# Homebrew
brew install node

# O Volta (recomendado para desarrollo web)
curl https://get.volta.sh | bash
volta install node@latest

# Verificación
node --version  # debe ser v18.0.0+
npm --version
```

#### Python (v3.8+)
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install python3 python3-pip

# Verificación
python3 --version
pip3 --version
```

#### Go (v1.18+)
```bash
# Ubuntu/Debian
sudo apt install golang-go

# Verificación
go version
```

#### PHP (v8.0+)
```bash
# Ubuntu/Debian
sudo apt install php php-cli php-xml php-curl

# Verificación
php --version
```

#### Java (v17+)
```bash
# SDKMAN (recomendado)
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java

# Verificación
java --version
```

## 🔧 Herramientas Adicionales

### Formateadores y Linters

```bash
# JavaScript/TypeScript
npm install -g prettier eslint typescript

# Prettier (requerido por Kulala)
npm install -g prettier

# JSON processing (para Kulala)
sudo apt install jq

# XML/HTML processing (opcional pero recomendado para Kulala)
sudo apt install libxml2-utils  # xmllint

# Lenguaje C/C++
# Clangd para soporte C/C++ en Neovim
sudo apt install clangd
```

### Herramientas de Desarrollo

```bash
# Git (requerido para lazy.nvim y plugins)
sudo apt install git

# Curl/Wget para descargas
sudo apt install curl wget

# Ripgrep (búsquedas rápidas) - LazyVim lo requiere
sudo apt install ripgrep

# FD (find moderno) - opcional pero recomendado
sudo apt install fd-find

# Para screenshots de código (Silicon plugin)
sudo apt install silicon

# Para development con PlatformIO (Arduino/embedded)
# Si usas PlatformIO, instala:
python3 -c "$(curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py)"
```

### Fuentes

```bash
# JetBrains Mono Nerd Font (requerido para Silicon plugin)
# Descargar e instalar desde: https://github.com/ryanoasis/nerd-fonts/releases
# O usar configurador de fuentes de tu distro
sudo apt install fonts-jetbrains-mono
```

## 🤖 Plugins con Requisitos Especiales

### AI y Desarrollo Asistido

#### GitHub Copilot
```bash
# Instalar extensión de GitHub CLI (opcional)
# 1. Instalar GitHub CLI: brew install gh (Mac) o snap install gh (Linux)
# 2. Autenticarse: gh auth login
# 3. Neovim configurará Copilot automáticamente
```

#### Claude Code
```bash
# Requiere API key de Anthropic
# Exportar variable de entorno:
export ANTHROPIC_API_KEY="tu-api-key-aqui"

# O ponerla en ~/.bashrc o ~/.zshrc
echo 'export ANTHROPIC_API_KEY="tu-api-key-aqui"' >> ~/.bashrc
```

### Desarrollo Web

#### Kulala.nvim (API Testing)
```bash
# Dependencias opcionales pero recomendadas:
npm install -g prettier jq  # formateo JSON/GraphQL
sudo apt install xmllint   # formateo XML/HTML
```

#### Silicon (Screenshots de código)
```bash
# Ubuntu/Debian:
sudo apt install silicon

# Requiere JetBrains Mono Nerd Font instalado
```

### Productividad

#### Obsidian.nvim
```bash
# Crear directorio de notas si no existe
mkdir -p ~/Notas/limbo
mkdir -p ~/Notas/extras
mkdir -p ~/Notas/templates
```

#### PlatformIO.nvim (Desarrollo Embedded)
```bash
# Instalar PlatformIO CLI
python3 -c "$(curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py)"

# Añadir a PATH (usualmente ~/.local/bin/platformio)
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
```

## 🚀 Instalación

### 1. Clonar Configuración
```bash
git clone <tu-repo> ~/.config/nvim
cd ~/.config/nvim
```

### 2. Iniciar Neovim y Esperar
```bash
nvim
```
Lazy.nvim instalará automáticamente todos los plugins la primera vez.

### 3. Configurar API Keys (Opcional)
```bash
# Para Copilot
gh auth login  # si usas GitHub CLI

# Para Claude
export ANTHROPIC_API_KEY="tu-key"
```

## 🔍 Verificación Post-Instalación

### Comprobar herramientas esenciales:
```bash
# Verificar dependencias principales
nvim --version
node --version
python3 --version
go version
php --version
java --version

# Verificar herramientas de desarrollo
which git curl wget ripgrep clangd prettier jq silicon
```

### Comandos útiles en Neovim:
```vim
:Lazy health    # Verificar estado de plugins
:checkhealth    # Diagnóstico general de Neovim
:NodeInfo       # Información de Node.js configurado
:Mason          # Gestor de herramientas LSP
```

## 🎯 Características Principales

- **Lenguajes**: TypeScript, JavaScript, Angular, React, Go, Python, PHP, Java, C/C++
- **AI Integrado**: GitHub Copilot, Claude Code, Copilot Chat
- **Testing API**: Kulala.nvim con soporte completo para REST/GraphQL
- **Productividad**: Obsidian para notas, Silicon para screenshots
- **Navegación**: Oil.nvim, Telescope, Harpoon2
- **Desarrollo Embedded**: PlatformIO support

## 🛠️ Troubleshooting

### Problemas Comunes

1. **Node.js demasiado antiguo**: Usa `volta install node@latest` o actualiza con tu gestor
2. **Clangd no encontrado**: `sudo apt install clangd`
3. **Silicon no funciona**: Asegúrate de tener JetBrains Mono Nerd Font instalado
4. **Copilot no responde**: Verifica `gh auth login` o API key

### Limpieza si algo falla:
```bash
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim
# Y reinicia Neovim para reinstalar todo
```

---

**Nota**: Esta configuración está optimizada para desarrollo profesional. Si experimentas lentitud, revisa los plugins deshabilitados en `lua/config/lazy.lua` y los deshabilitados en `lua/plugins/disabled.lua`.

**Creado con ❤️ por tu arquitecto frontend favorito** 🤙
