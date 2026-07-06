import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  id: root

  // --- Theme definitions ---
  readonly property var _macosTheme: ({
    accent: "#0a84ff",
    bgPanel: "#e6242424",
    bgRow: "#16ffffff",
    bgRowHover: "#1fffffff",
    textPrimary: "#f2f2f2",
    textSecondary: "#98989d",
    textAccent: "#ffffff",
    textSelected: "#ffffff",
    descriptionSelected: "#e6ffffff",
    borderColor: "#26ffffff",
    dividerColor: "#14ffffff",
    bevelLight: "#00ffffff",
    bevelDark: "#00ffffff",
    bevelDarker: "#00ffffff",
    hasBevelBorder: false,
    showTitleBar: false,
    hasShadow: true,
    shadowColor: "#66000000",
    glassHighlight: "#0dffffff",
    panelScaleClosed: 0.96,
    animOpacityDuration: 140,
    animOpacityEasing: Easing.OutCubic,
    animScaleDuration: 260,
    animScaleEasing: Easing.OutCubic,
    animHeightDuration: 180,
    animHeightEasing: Easing.OutCubic,
    radius: 20,
    radiusInner: 9,
    surface: "#14ffffff",
    surfaceBorder: "#14ffffff",
    fontFamily: "",
    monoFontFamily: "monospace",
    searchLetterSpacing: -0.2,
    descriptionFontSize: 11,
    modePillBg: "#1affffff",
    modePillBorder: "#22ffffff",
    codeBlockBg: "#1affffff",
    codeBlockBorder: "#1fffffff",
    codeBlockRadius: 8,
    codeLangBg: Qt.rgba(0.29,0.87,0.5,0.15),
    codeLangText: "#4ade80",
    codeTextColor: "#e5e5e5",
    codeCopyBg: Qt.rgba(0.29,0.87,0.5,0.12),
    codeCopyBgHover: Qt.rgba(0.29,0.87,0.5,0.25),
    codeCopyBorder: Qt.rgba(0.29,0.87,0.5,0.25),
    codeCopyBorderHover: Qt.rgba(0.29,0.87,0.5,0.5),
    codeCopyText: Qt.rgba(0.29,0.87,0.5,0.8),
    codeCopyTextDone: "#4ade80",
    inputBg: "#14ffffff",
    buttonText: "#ffffff",
    feedbackColor: "#4ade80",
    selectionTextColor: "#ffffff",
    descriptionSelectedColor: "#e6ffffff",
    aliasColor: "#f472b6",
    aliasSelectedColor: "#ffffff",
    typePillBg: "#12ffffff",
    typePillBorder: "#12ffffff",
    typePillSelectedBg: "#26ffffff",
    iconBg: Qt.rgba(0.96,0.45,0.71,0.18),
    iconRadius: 9,
    titleBarGradientFrom: "#000000",
    titleBarGradientTo: "#000000",
    titleBarText: "#ffffff",
    titleBarLabel: "Spotlight",
    categoryColors: {
      video:  "#60a5fa",
      audio:  "#a78bfa",
      image:  "#fb923c",
      doc:    "#4ade80",
      dir:    "#94a3b8",
      other:  "#64748b",
      app:    "#f472b6",
      youtube:"#a78bfa",
      shell:  "#4ade80",
      web:    "#60a5fa",
    },
  })

  readonly property var _win95Theme: ({
    accent: "#000080",
    bgPanel: "#c0c0c0",
    bgRow: "#c0c0c0",
    bgRowHover: "#d4d0c8",
    textPrimary: "#000000",
    textSecondary: "#404040",
    textAccent: "#ffffff",
    textSelected: "#ffffff",
    descriptionSelected: "#d4d0c8",
    borderColor: "#000000",
    dividerColor: "#808080",
    bevelLight: "#ffffff",
    bevelDark: "#808080",
    bevelDarker: "#000000",
    hasBevelBorder: true,
    showTitleBar: true,
    hasShadow: false,
    shadowColor: "#66000000",
    glassHighlight: "#0dffffff",
    panelScaleClosed: 1.0,
    animOpacityDuration: 60,
    animOpacityEasing: Easing.Linear,
    animScaleDuration: 0,
    animScaleEasing: Easing.Linear,
    animHeightDuration: 0,
    animHeightEasing: Easing.Linear,
    radius: 0,
    radiusInner: 0,
    surface: "#c0c0c0",
    surfaceBorder: "#808080",
    fontFamily: "Tahoma",
    monoFontFamily: "Courier New",
    searchLetterSpacing: 0,
    descriptionFontSize: 10,
    modePillBg: "#c0c0c0",
    modePillBorder: "#808080",
    codeBlockBg: "#ffffff",
    codeBlockBorder: "#808080",
    codeBlockRadius: 0,
    codeLangBg: "#808080",
    codeLangText: "#ffffff",
    codeTextColor: "#000000",
    codeCopyBg: "#c0c0c0",
    codeCopyBgHover: "#d4d0c8",
    codeCopyBorder: "#808080",
    codeCopyBorderHover: "#808080",
    codeCopyText: "#000000",
    codeCopyTextDone: "#008000",
    inputBg: "#ffffff",
    buttonText: "#ffffff",
    feedbackColor: "#008000",
    selectionTextColor: "#ffffff",
    descriptionSelectedColor: "#d4d0c8",
    aliasColor: "#800080",
    aliasSelectedColor: "#ffffff",
    typePillBg: "#c0c0c0",
    typePillBorder: "#000000",
    typePillSelectedBg: "#c0c0c0",
    iconBg: "#c0c0c0",
    iconRadius: 0,
    titleBarGradientFrom: "#000080",
    titleBarGradientTo: "#1084d0",
    titleBarText: "#ffffff",
    titleBarLabel: "Spotlight95",
    categoryColors: {
      video:  "#000080",
      audio:  "#800080",
      image:  "#804000",
      doc:    "#008000",
      dir:    "#404040",
      other:  "#404040",
      app:    "#800000",
      youtube:"#800080",
      shell:  "#008000",
      web:    "#000080",
    },
  })

  property var theme: _win95Theme
  property string themeName: "win95"

  readonly property color accent: theme.accent
  readonly property color bgPanel: theme.bgPanel
  readonly property color bgRow: theme.bgRow
  readonly property color bgRowHover: theme.bgRowHover
  readonly property color textPrimary: theme.textPrimary
  readonly property color textSecondary: theme.textSecondary
  readonly property color textAccent: theme.textAccent
  readonly property color textSelected: theme.textSelected
  readonly property color descriptionSelected: theme.descriptionSelected
  readonly property color borderColor: theme.borderColor
  readonly property color dividerColor: theme.dividerColor
  readonly property color bevelLight: theme.bevelLight
  readonly property color bevelDark: theme.bevelDark
  readonly property color bevelDarker: theme.bevelDarker
  readonly property bool hasBevelBorder: theme.hasBevelBorder
  readonly property bool showTitleBar: theme.showTitleBar
  readonly property bool hasThemeShadow: theme.hasShadow
  readonly property real panelScaleClosed: theme.panelScaleClosed
  readonly property int animOpacityDuration: theme.animOpacityDuration
  readonly property int animOpacityEasing: theme.animOpacityEasing
  readonly property int animScaleDuration: theme.animScaleDuration
  readonly property int animScaleEasing: theme.animScaleEasing
  readonly property int animHeightDuration: theme.animHeightDuration
  readonly property int animHeightEasing: theme.animHeightEasing
  readonly property int radius: theme.radius
  readonly property int radiusInner: theme.radiusInner
  readonly property color surface: theme.surface
  readonly property color surfaceBorder: theme.surfaceBorder
  readonly property string fontFamily: theme.fontFamily
  readonly property string monoFontFamily: theme.monoFontFamily
  readonly property real searchLetterSpacing: theme.searchLetterSpacing
  readonly property int descriptionFontSize: theme.descriptionFontSize
  readonly property color modePillBg: theme.modePillBg
  readonly property color modePillBorder: theme.modePillBorder
  readonly property color codeBlockBg: theme.codeBlockBg
  readonly property color codeBlockBorder: theme.codeBlockBorder
  readonly property int codeBlockRadius: theme.codeBlockRadius
  readonly property color codeLangBg: theme.codeLangBg
  readonly property color codeLangText: theme.codeLangText
  readonly property color codeTextColor: theme.codeTextColor
  readonly property color codeCopyBg: theme.codeCopyBg
  readonly property color codeCopyBgHover: theme.codeCopyBgHover
  readonly property color codeCopyBorder: theme.codeCopyBorder
  readonly property color codeCopyBorderHover: theme.codeCopyBorderHover
  readonly property color codeCopyText: theme.codeCopyText
  readonly property color codeCopyTextDone: theme.codeCopyTextDone
  readonly property color inputBg: theme.inputBg
  readonly property color buttonText: theme.buttonText
  readonly property color feedbackColor: theme.feedbackColor
  readonly property color selectionTextColor: theme.selectionTextColor
  readonly property color descriptionSelectedColor: theme.descriptionSelectedColor
  readonly property color aliasColor: theme.aliasColor
  readonly property color aliasSelectedColor: theme.aliasSelectedColor
  readonly property color typePillBg: theme.typePillBg
  readonly property color typePillBorder: theme.typePillBorder
  readonly property color typePillSelectedBg: theme.typePillSelectedBg
  readonly property color iconBg: theme.iconBg
  readonly property int iconRadius: theme.iconRadius
  readonly property color shadowColor: theme.shadowColor
  readonly property color glassHighlight: theme.glassHighlight
  readonly property color titleBarGradientFrom: theme.titleBarGradientFrom
  readonly property color titleBarGradientTo: theme.titleBarGradientTo
  readonly property color titleBarText: theme.titleBarText
  readonly property string titleBarLabel: theme.titleBarLabel

  readonly property var categoryInfo: ({
    video:  { label: "VIDEO",  color: theme.categoryColors.video },
    audio:  { label: "AUDIO",  color: theme.categoryColors.audio },
    image:  { label: "IMAGE",  color: theme.categoryColors.image },
    doc:    { label: "DOC",    color: theme.categoryColors.doc },
    dir:    { label: "DIR",    color: theme.categoryColors.dir },
    other:  { label: "FILE",   color: theme.categoryColors.other },
    app:    { label: "APP",    color: theme.categoryColors.app },
    youtube:{ label: "YT",    color: theme.categoryColors.youtube },
    shell:  { label: "SHELL", color: theme.categoryColors.shell },
    web:    { label: "WEB",   color: theme.categoryColors.web },
  })

  function applyTheme(name) {
    if (name === "macos") {
      root.theme = _macosTheme
      root.themeName = "macos"
    } else {
      root.theme = _win95Theme
      root.themeName = "win95"
    }
    root.writeTheme()
  }

  property bool open: false
  property string mode: "app"
  property string searchQuery: ""
  property var results: []
  property int selectedIndex: 0
  property bool searching: false

  property string answerTitle: ""
  property string answerText: ""
  property var answerSegments: []
  property string answerUrl: ""
  property string answerSource: ""
  property string groqKey: ""
  property bool hasGroqKey: false
  property string secretsPath: home + "/.config/quickshell/spotlight-data/secrets.json"
  property bool secretsLoaded: false
  property string groqKeyInput: ""

  property var apps: []
  property var appAliases: ({})
  property var aliasById: ({})
  property string aliasesPath: home + "/.config/quickshell/spotlight-data/aliases.json"
  property bool appsLoaded: false
  property bool aliasesLoaded: false
  property bool capturesLoaded: false
  property bool commandsLoaded: false
  property string aliasInputDesktopId: ""
  property string aliasInputText: ""
  property bool aliasSavedFeedback: false
  property bool captureSavedFeedback: false
  property string captureFeedbackText: ""
  property var captures: ({})
  property string capturesPath: home + "/.config/quickshell/spotlight-data/captures.json"
  property var commands: ({})
  property string commandsPath: home + "/.config/quickshell/spotlight-data/commands.json"
  property string themePath: home + "/.config/quickshell/spotlight-data/theme.json"

  readonly property string home: Quickshell.env("HOME") || ""

  IpcHandler {
    target: "spotlight"
    function toggle() { root.open = !root.open }
    function show() { root.open = true }
    function hide() { root.open = false }
    function themeMacos() { root.applyTheme("macos") }
    function themeWin95() { root.applyTheme("win95") }
  }

  onOpenChanged: {
    if (open) {
      root.searchQuery = ""
      root.results = []
      root.selectedIndex = 0
      root.mode = "app"
      root.answerTitle = ""
      root.answerText = ""
      root.answerUrl = ""
      root.answerSource = ""
      root.aliasInputDesktopId = ""
      if (!root.appsLoaded)
        root.loadApps()
      if (!root.aliasesLoaded)
        root.loadAliases()
      if (!root.capturesLoaded)
        root.loadCaptures()
      if (!root.commandsLoaded)
        root.loadCommands()
      root.loadSecrets()
      root.loadTheme()
    }
  }

  function processInput(raw) {
    root.selectedIndex = 0

    if (raw.length > 0 && raw[0] === '\\')
      raw = '/' + raw.slice(1)

    if (raw.length < 1) {
      root.mode = "app"
      root.searchQuery = ""
      root.results = []
      root.searching = false
      root.answerTitle = ""
      root.answerText = ""
      root.answerUrl = ""
      root.answerSource = ""
      searchTimer.stop()
      return
    }

    if (raw.slice(0, 6) === "/theme" && raw.length >= 7 && raw[6] === " ") {
      var t = raw.slice(7).trim().toLowerCase()
      if (t === "macos" || t === "win95") {
        root.applyTheme(t)
        root.mode = "answer"
        root.searchQuery = ""
        root.results = []
        root.searching = false
        root.answerTitle = ""
        root.answerUrl = ""
        root.answerSource = ""
        root.answerText = t === "macos" ? "Theme: macOS" : "Theme: Windows 95"
      }
      return
    }

    var newMode = ""
    var stripped = raw
    if (raw.length >= 3 && raw.slice(0, 3) === "/f ") { newMode = "file"; stripped = raw.slice(3) }
    else if (raw.length >= 3 && raw.slice(0, 3) === "/s ") { newMode = "answer"; stripped = raw.slice(3) }
    else if (raw.length >= 3 && raw.slice(0, 3) === "/g ") { newMode = "google"; stripped = raw.slice(3) }
    else if (raw.length >= 4 && raw.slice(0, 4) === "/yt ") { newMode = "youtube"; stripped = raw.slice(4) }
    else if (raw.length >= 3 && raw.slice(0, 3) === "/w ") { newMode = "web"; stripped = raw.slice(3) }
    else if (raw.length >= 5 && raw.slice(0, 5) === "/cap ") { newMode = "capture"; stripped = raw.slice(5) }
    else if (raw.length >= 4 && raw.slice(0, 4) === "/sh ") { newMode = "shell"; stripped = raw.slice(4) }
    else if (raw.length >= 4 && raw.slice(0, 4) === "/sc ") { newMode = "shellcap"; stripped = raw.slice(4) }

    if (newMode !== "") {
      if (root.mode !== newMode) {
        root.results = []
        root.answerTitle = ""
        root.answerText = ""
        root.answerUrl = ""
        root.answerSource = ""
      }
      root.mode = newMode
      root.searchQuery = stripped

      if (newMode === "file") {
        if (stripped.length > 0)
          searchTimer.restart()
        else
          searchTimer.stop()
      } else if (newMode === "youtube") {
        if (stripped.length > 0)
          searchTimer.restart()
        else
          searchTimer.stop()
      } else if (newMode === "answer") {
        searchTimer.stop()
      } else {
        searchTimer.stop()
      }
      return
    }

    if (root.mode === "file") {
      root.searchQuery = raw
      if (raw.length > 0)
        searchTimer.restart()
      else
        searchTimer.stop()
      return
    }
    if (root.mode === "youtube") {
      root.searchQuery = raw
      if (raw.length > 0)
        searchTimer.restart()
      else
        searchTimer.stop()
      return
    }
    if (root.mode === "answer" || root.mode === "google" || root.mode === "web" || root.mode === "capture" || root.mode === "shell" || root.mode === "shellcap") {
      root.searchQuery = raw
      return
    }

    root.mode = "app"
    root.answerTitle = ""
    root.answerText = ""
    root.searchQuery = raw
    searchTimer.stop()
  }

  onSearchQueryChanged: {
    if (root.mode === "shell") {
      root.results = root.filterShell(root.searchQuery)
    } else if (root.mode === "web") {
      root.results = root.filterCaptures(root.searchQuery)
    } else if (root.mode === "app" && root.searchQuery.length > 0) {
      root.results = root.filterApps(root.searchQuery)
    }
  }

  Timer {
    id: searchTimer
    interval: root.mode === "youtube" ? 400 : 250
    onTriggered: {
      if (root.mode === "file")
        root.runSearch()
      else if (root.mode === "youtube")
        root.runYoutubeSearch()
    }
  }

  Process {
    id: searchProc
    stdout: StdioCollector {
      onStreamFinished: {
        root.searching = false
        var lines = text.split("\n")
        var arr = []
        var q = root.searchQuery.toLowerCase()

        for (var i = 0; i < lines.length; i++) {
          var line = lines[i]
          if (!line) continue
          var tab = line.indexOf("\t")
          if (tab < 0) continue
          var cat = line.slice(0, tab)
          var path = line.slice(tab + 1)
          var slash = path.lastIndexOf("/")
          var name = slash >= 0 ? path.slice(slash + 1) : path
          var dir = slash >= 0 ? path.slice(0, slash) : ""
          var ext = name.lastIndexOf(".")
          var displayName = ext > 0 ? name.slice(0, ext) : name

          arr.push({
            type: "file",
            category: cat,
            path: path,
            name: displayName,
            ext: ext > 0 ? name.slice(ext).toLowerCase() : "",
            dir: root.home && dir.indexOf(root.home) === 0 ? "~" + dir.slice(root.home.length) : dir,
            info: root.categoryInfo[cat] || root.categoryInfo["other"],
          })
        }

        if (q.length > 0) {
          arr.sort(function(a, b) {
            var aPre = a.name.toLowerCase().indexOf(q) === 0 ? 0 : 1
            var bPre = b.name.toLowerCase().indexOf(q) === 0 ? 0 : 1
            if (aPre !== bPre) return aPre - bPre
            return a.name.length - b.name.length
          })
        }

        root.results = arr.slice(0, 30)
      }
    }
    stderr: StdioCollector {}
  }

  Process {
    id: secretLoadProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          if (data.groq_key) {
            root.groqKey = data.groq_key
            root.hasGroqKey = true
          }
        } catch (e) {}
        root.secretsLoaded = true
      }
    }
    stderr: StdioCollector {}
  }

  Process {
    id: secretSaveProc
    stderr: StdioCollector {}
  }

  Process {
    id: ytSearchProc
    stdout: StdioCollector {
      onStreamFinished: {
        root.searching = false
        try {
          var data = JSON.parse(text)
          var arr = []
          for (var i = 0; i < data.length; i++) {
            var d = data[i]
            arr.push({
              type: "youtube",
              category: "youtube",
              videoId: d.id,
              name: d.title,
              author: d.author || "",
              duration: d.duration || "",
              info: root.categoryInfo["youtube"],
            })
          }
          root.results = arr
        } catch (e) {
          root.results = []
        }
      }
    }
    stderr: StdioCollector {}
  }

  Process {
    id: appScanProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.apps = JSON.parse(text)
          root.appsLoaded = true
        } catch (e) {}
      }
    }
    stderr: StdioCollector {}
  }

  Process {
    id: aliasLoadProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          root.appAliases = data || ({})
        } catch (e) {
          root.appAliases = ({})
        }
        root.aliasesLoaded = true
        root.rebuildAliasById()
      }
    }
    stderr: StdioCollector {}
  }

  Process {
    id: aliasSaveProc
    stderr: StdioCollector {}
  }

  Process {
    id: captureLoadProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          root.captures = data || ({})
        } catch (e) {
          root.captures = ({})
        }
        root.capturesLoaded = true
      }
    }
    stderr: StdioCollector {}
  }

  Process {
    id: captureSaveProc
    stderr: StdioCollector {}
  }

  Process {
    id: commandLoadProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          root.commands = data || ({})
        } catch (e) {
          root.commands = ({})
        }
        root.commandsLoaded = true
      }
    }
    stderr: StdioCollector {}
  }

  Process {
    id: commandSaveProc
    stderr: StdioCollector {}
  }

  Process {
    id: themeLoadProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          if (data.theme)
            root.applyTheme(data.theme)
        } catch (e) {}
      }
    }
    stderr: StdioCollector {}
  }

  Process {
    id: themeSaveProc
    stderr: StdioCollector {}
  }

  function loadApps() {
    appScanProc.running = false
    appScanProc.command = ["python3", "-c",
      "import os, json, re\n" +
      "dirs = [os.path.expanduser('~/.local/share/applications'),\n" +
      "  '/usr/share/applications', '/usr/local/share/applications',\n" +
      "  '/var/lib/flatpak/exports/share/applications',\n" +
      "  os.path.expanduser('~/.local/share/flatpak/exports/share/applications')]\n" +
      "icon_dirs = [os.path.expanduser('~/.local/share/icons/hicolor/48x48/apps'),\n" +
      "  os.path.expanduser('~/.local/share/icons/hicolor/64x64/apps'),\n" +
      "  os.path.expanduser('~/.local/share/icons/hicolor/scalable/apps'),\n" +
      "  '/usr/share/icons/hicolor/48x48/apps', '/usr/share/icons/hicolor/64x64/apps',\n" +
      "  '/usr/share/icons/hicolor/scalable/apps', '/usr/share/icons/hicolor/32x32/apps',\n" +
      "  '/usr/share/icons/Adwaita/48x48/apps', '/usr/share/icons/Adwaita/scalable/apps',\n" +
      "  '/usr/share/pixmaps']\n" +
      "exts = ['.png','.svg','.xpm']\n" +
      "def resolve_icon(name):\n" +
      "  if not name: return ''\n" +
      "  if name.startswith('/'): return name if os.path.isfile(name) else ''\n" +
      "  for d in icon_dirs:\n" +
      "    if not os.path.isdir(d): continue\n" +
      "    for e in exts:\n" +
      "      p = os.path.join(d, name + e)\n" +
      "      if os.path.isfile(p): return p\n" +
      "    p = os.path.join(d, name)\n" +
      "    if os.path.isfile(p): return p\n" +
      "  return ''\n" +
      "seen = set()\n" +
      "result = []\n" +
      "for d in dirs:\n" +
      "  if not os.path.isdir(d): continue\n" +
      "  for f in os.listdir(d):\n" +
      "    if not f.endswith('.desktop'): continue\n" +
      "    if f in seen: continue\n" +
      "    seen.add(f)\n" +
      "    fp = os.path.join(d, f)\n" +
      "    try:\n" +
      "      entry = {'desktopId': f, 'name': '', 'exec': '', 'icon': '', 'iconPath': '', 'comment': '', 'categories': '', 'terminal': False}\n" +
      "      inDesktop = False\n" +
      "      skip = False\n" +
      "      for line in open(fp, 'r', errors='ignore'):\n" +
      "        line = line.strip()\n" +
      "        if line.startswith('['):\n" +
      "          inDesktop = line == '[Desktop Entry]'\n" +
      "          continue\n" +
      "        if not inDesktop or not line or line.startswith('#'): continue\n" +
      "        if '=' not in line: continue\n" +
      "        k, v = line.split('=', 1)\n" +
      "        k, v = k.strip(), v.strip()\n" +
      "        if k == 'Type' and v != 'Application': skip = True; break\n" +
      "        if k == 'NoDisplay' and v == 'true': skip = True; break\n" +
      "        if k == 'Name' and not entry['name']: entry['name'] = v\n" +
      "        elif k == 'Exec': entry['exec'] = v\n" +
      "        elif k == 'Icon': entry['icon'] = v\n" +
      "        elif k == 'Comment': entry['comment'] = v\n" +
      "        elif k == 'Categories': entry['categories'] = v\n" +
      "        elif k == 'Terminal': entry['terminal'] = v == 'true'\n" +
      "      if skip or not entry['name'] or not entry['exec']: continue\n" +
      "      entry['exec'] = re.sub(r'%[fFuUdDnNickvm]', '', entry['exec'].replace('%%', '\\x00')).replace('\\x00', '%').strip()\n" +
      "      entry['iconPath'] = resolve_icon(entry['icon'])\n" +
      "      result.append(entry)\n" +
      "    except: pass\n" +
      "print(json.dumps(result))"]
    appScanProc.running = true
  }

  function loadAliases() {
    aliasLoadProc.running = false
    aliasLoadProc.command = ["sh", "-c", "cat \"" + root.aliasesPath + "\" 2>/dev/null || echo '{}'"]
    aliasLoadProc.running = true
  }

  function loadCaptures() {
    captureLoadProc.running = false
    captureLoadProc.command = ["sh", "-c", "cat \"" + root.capturesPath + "\" 2>/dev/null || echo '{}'"]
    captureLoadProc.running = true
  }

  function loadCommands() {
    commandLoadProc.running = false
    commandLoadProc.command = ["sh", "-c", "cat \"" + root.commandsPath + "\" 2>/dev/null || echo '{}'"]
    commandLoadProc.running = true
  }

  function loadTheme() {
    themeLoadProc.running = false
    themeLoadProc.command = ["sh", "-c", "cat \"" + root.themePath + "\" 2>/dev/null || echo '{}'"]
    themeLoadProc.running = true
  }

  function filterCaptures(q) {
    if (q.length < 1) {
      var all = []
      for (var key in root.captures) {
        all.push({
          type: "web",
          category: "web",
          code: key,
          url: root.captures[key],
          info: root.categoryInfo["web"],
        })
      }
      all.sort(function(a, b) { return a.code.localeCompare(b.code) })
      return all.slice(0, 12)
    }
    var ql = q.toLowerCase()
    var matched = []
    for (var code in root.captures) {
      var url = root.captures[code]
      if (code.toLowerCase().indexOf(ql) >= 0 || url.toLowerCase().indexOf(ql) >= 0) {
        matched.push({
          type: "web",
          category: "web",
          code: code,
          url: url,
          info: root.categoryInfo["web"],
        })
      }
    }
    matched.sort(function(a, b) {
      var aPre = a.code.toLowerCase().indexOf(ql) === 0 ? 0 : 1
      var bPre = b.code.toLowerCase().indexOf(ql) === 0 ? 0 : 1
      if (aPre !== bPre) return aPre - bPre
      return a.code.localeCompare(b.code)
    })
    return matched.slice(0, 12)
  }

  function filterShell(q) {
    if (q.length < 1) {
      var all = []
      for (var key in root.commands) {
        all.push({
          type: "shell",
          category: "shell",
          code: key,
          command: root.commands[key],
          info: root.categoryInfo["shell"],
        })
      }
      return all.slice(0, 12)
    }
    var ql = q.toLowerCase()
    var matched = []
    for (var code in root.commands) {
      var cmd = root.commands[code]
      if (code.toLowerCase().indexOf(ql) >= 0 || cmd.toLowerCase().indexOf(ql) >= 0) {
        matched.push({
          type: "shell",
          category: "shell",
          code: code,
          command: cmd,
          info: root.categoryInfo["shell"],
        })
      }
    }
    matched.sort(function(a, b) {
      var aPre = a.code.toLowerCase().indexOf(ql) === 0 ? 0 : 1
      var bPre = b.code.toLowerCase().indexOf(ql) === 0 ? 0 : 1
      if (aPre !== bPre) return aPre - bPre
      var aCmdPre = a.command.toLowerCase().indexOf(ql) === 0 ? 0 : 1
      var bCmdPre = b.command.toLowerCase().indexOf(ql) === 0 ? 0 : 1
      if (aCmdPre !== bCmdPre) return aCmdPre - bCmdPre
      return a.code.length - b.code.length
    })
    return matched.slice(0, 12)
  }

  function saveAlias(alias, desktopId) {
    var al = alias.trim().toLowerCase()
    if (al.length < 1) return
    root.appAliases[al] = desktopId
    root.aliasSavedFeedback = true
    feedbackTimer.restart()
    root.rebuildAliasById()
    writeAliases()
  }

  function removeAlias(alias) {
    var al = alias.trim().toLowerCase()
    if (root.appAliases[al]) {
      delete root.appAliases[al]
      root.rebuildAliasById()
      writeAliases()
    }
  }

  function writeAliases() {
    aliasSaveProc.running = false
    var json = JSON.stringify(root.appAliases)
    aliasSaveProc.command = [
      "python3", "-c",
      "import sys, os; p=sys.argv[1]; os.makedirs(os.path.dirname(p), exist_ok=True); open(p,'w').write(sys.argv[2])",
      root.aliasesPath,
      json
    ]
    aliasSaveProc.running = true
  }

  function saveCapture(code, url) {
    var c = code.trim().toLowerCase()
    if (c.length < 1 || !url || url.trim().length < 1) return
    root.captures[c] = url.trim()
    root.captureFeedbackText = "Saved! :" + c + " \u2192 " + url.trim()
    root.captureSavedFeedback = true
    captureFeedbackTimer.restart()
    writeCaptures()
  }

  function removeCapture(code) {
    var c = code.trim().toLowerCase()
    if (root.captures[c]) {
      delete root.captures[c]
      writeCaptures()
    }
  }

  function writeCaptures() {
    captureSaveProc.running = false
    var json = JSON.stringify(root.captures)
    captureSaveProc.command = [
      "python3", "-c",
      "import sys, os; p=sys.argv[1]; os.makedirs(os.path.dirname(p), exist_ok=True); open(p,'w').write(sys.argv[2])",
      root.capturesPath,
      json
    ]
    captureSaveProc.running = true
  }

  function resolveCapture(code) {
    return root.captures[code.trim().toLowerCase()] || ""
  }

  function saveCommand(code, command) {
    var c = code.trim().toLowerCase()
    if (c.length < 1 || !command || command.trim().length < 1) return
    root.commands[c] = command.trim()
    root.captureFeedbackText = "Shell saved! :" + c + " \u2192 " + command.trim()
    root.captureSavedFeedback = true
    captureFeedbackTimer.restart()
    writeCommands()
  }

  function writeCommands() {
    commandSaveProc.running = false
    var json = JSON.stringify(root.commands)
    commandSaveProc.command = [
      "python3", "-c",
      "import sys, os; p=sys.argv[1]; os.makedirs(os.path.dirname(p), exist_ok=True); open(p,'w').write(sys.argv[2])",
      root.commandsPath,
      json
    ]
    commandSaveProc.running = true
  }

  function writeTheme() {
    themeSaveProc.running = false
    var json = JSON.stringify({"theme": root.themeName})
    themeSaveProc.command = [
      "python3", "-c",
      "import sys, os; p=sys.argv[1]; os.makedirs(os.path.dirname(p), exist_ok=True); open(p,'w').write(sys.argv[2])",
      root.themePath,
      json
    ]
    themeSaveProc.running = true
  }

  function resolveAlias(alias) {
    return root.appAliases[alias.trim().toLowerCase()] || ""
  }

  function aliasForDesktopId(desktopId) {
    return root.aliasById[desktopId] || ""
  }

  function rebuildAliasById() {
    var rev = {}
    for (var key in root.appAliases)
      rev[root.appAliases[key]] = key
    root.aliasById = rev
  }

  function filterApps(q) {
    if (!root.apps || root.apps.length === 0 || q.length < 1) return []
    var matched = []
    var aliasDesktopId = root.resolveAlias(q)

    for (var i = 0; i < root.apps.length; i++) {
      var app = root.apps[i]
      var alias = root.aliasForDesktopId(app.desktopId)
      if (app.name.toLowerCase().indexOf(q) >= 0 ||
          (app.comment && app.comment.toLowerCase().indexOf(q) >= 0) ||
          (app.categories && app.categories.toLowerCase().indexOf(q) >= 0) ||
          (alias && alias.indexOf(q) >= 0)) {
        matched.push({
          type: "app",
          category: "app",
          desktopId: app.desktopId,
          name: app.name,
          exec: app.exec,
          icon: app.icon,
          iconPath: app.iconPath,
          comment: app.comment,
          categories: app.categories,
          alias: alias,
          terminal: app.terminal,
          info: root.categoryInfo["app"],
        })
      }
    }

    if (aliasDesktopId) {
      for (var i = 0; i < matched.length; i++) {
        if (matched[i].desktopId === aliasDesktopId) {
          var item = matched.splice(i, 1)[0]
          matched.unshift(item)
          break
        }
      }
    }

    return matched.slice(0, 8)
  }

  function runSearch() {
    var q = root.searchQuery.trim()
    if (q.length < 1) { results = []; return }
    root.searching = true
    searchProc.running = false
    searchProc.command = ["sh", "-c", root.searchScript, "sh", q]
    searchProc.running = true
  }

  function loadSecrets() {
    if (root.secretsLoaded) return
    secretLoadProc.running = false
    secretLoadProc.command = ["sh", "-c", "cat \"" + root.secretsPath + "\" 2>/dev/null || echo '{}'"]
    secretLoadProc.running = true
  }

  function saveGroqKey(key) {
    root.groqKey = key
    root.hasGroqKey = true
    root.groqKeyInput = ""
    root.answerText = "Groq key saved! You can now use /s mode."
    root.answerTitle = ""
    root.answerUrl = ""
    root.answerSource = ""
    var json = JSON.stringify({"groq_key": key})
    secretSaveProc.running = false
    secretSaveProc.command = [
      "python3", "-c",
      "import sys, os; p=sys.argv[1]; os.makedirs(os.path.dirname(p), exist_ok=True); open(p,'w').write(sys.argv[2])",
      root.secretsPath,
      json
    ]
    secretSaveProc.running = true
  }

  function parseAnswer(text) {
    if (!text) return []
    var segments = []
    var pattern = /```(\w+)?\s*\n?([\s\S]*?)```/g
    var lastIndex = 0
    var match
    while ((match = pattern.exec(text)) !== null) {
      if (match.index > lastIndex) {
        var t = text.slice(lastIndex, match.index).trim()
        if (t) segments.push({type: "text", content: t})
      }
      segments.push({type: "code", lang: match[1] || "", content: match[2].trim()})
      lastIndex = match.index + match[0].length
    }
    if (lastIndex < text.length) {
      var remaining = text.slice(lastIndex).trim()
      if (remaining) segments.push({type: "text", content: remaining})
    }
    return segments
  }

  onAnswerTextChanged: root.answerSegments = root.parseAnswer(root.answerText)

  function runWebSearch() {
    var q = root.searchQuery.trim()
    if (q.length < 1 || !root.hasGroqKey) { return }
    root.searching = true

    var xhr = new XMLHttpRequest()
    xhr.open("POST", "https://api.groq.com/openai/v1/chat/completions")
    xhr.setRequestHeader("Authorization", "Bearer " + root.groqKey)
    xhr.setRequestHeader("Content-Type", "application/json")
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        root.searching = false
        try {
          var data = JSON.parse(xhr.responseText)
          if (data.choices && data.choices.length > 0) {
            root.answerText = data.choices[0].message.content || ""
            root.answerTitle = ""
            root.answerUrl = ""
            root.answerSource = "Groq AI"
          } else {
            root.answerText = data.error?.message || "No answer found"
            root.answerTitle = ""
            root.answerUrl = ""
            root.answerSource = ""
          }
        } catch (e) {
          root.answerTitle = ""
          root.answerText = "Error: " + e.message
          root.answerUrl = ""
          root.answerSource = ""
        }
      }
    }
    xhr.send(JSON.stringify({
      model: "llama-3.3-70b-versatile",
      messages: [
        {role: "system", content: "Give clear helpful answers. Use markdown formatting. For commands, show them in code blocks with language labels (like ```bash or ```python) so they are ready to copy. Keep answers concise but complete."},
        {role: "user", content: q}
      ],
      temperature: 0.3,
      max_tokens: 800
    }))
  }

  readonly property string searchScript:
    'q=$1; fd --hidden --no-ignore --type f --type d -a ' +
    '-E .cache -E .git -E .cargo -E .rustup -E .npm -E .gradle -E .mozilla -E .var -E node_modules ' +
    '-E gtk-icons -E ".local/straight" -E "go/pkg" -E yay -E quickshell-shells ' +
    '-c never -- "$q" "$HOME" 2>/dev/null | ' +
    'head -50 | while IFS= read -r p; do ' +
    '  if [ -d "$p" ]; then printf "dir\t%s\\n" "$p"; ' +
    '  else ' +
    '    ext=$(echo "${p##*.}" | tr "A-Z" "a-z"); ' +
    '    case "$ext" in ' +
    '      mp4|avi|mkv|mov|wmv|flv|webm|m4v|mpg|mpeg|3gp) printf "video\t%s\\n" "$p" ;; ' +
    '      mp3|wav|flac|aac|ogg|wma|m4a|opus|aiff|alac) printf "audio\t%s\\n" "$p" ;; ' +
    '      jpg|jpeg|png|gif|bmp|svg|webp|ico|tiff|tif|heic|heif|raw) printf "image\t%s\\n" "$p" ;; ' +
    '      pdf|txt|md|json|xml|html|css|js|ts|py|c|cpp|h|hpp|java|rb|go|rs|lua|sh|yaml|yml|toml|ini|cfg|conf|log|doc|docx|xls|xlsx|ppt|pptx|csv) printf "doc\t%s\\n" "$p" ;; ' +
    '      *) printf "other\t%s\\n" "$p" ;; ' +
    '    esac; ' +
    '  fi; ' +
    'done'

  function runYoutubeSearch() {
    var q = root.searchQuery.trim()
    if (q.length < 1) { root.results = []; return }
    root.searching = true
    var binPath = Quickshell.shellPath("modules/launcher/bin/yt-search")
    ytSearchProc.running = false
    ytSearchProc.command = [binPath, q]
    ytSearchProc.running = true
  }

  function launch(item) {
    if (!item) return
    root.open = false
    if (item.type === "app") {
      if (item.terminal)
        Quickshell.execDetached(["ghostty", "-e", "/bin/sh", "-c", item.exec])
      else
        Quickshell.execDetached(["/bin/sh", "-c", item.exec + " &"])
      return
    }
    if (item.type === "youtube") {
      Qt.openUrlExternally("https://www.youtube.com/watch?v=" + item.videoId)
      return
    }
    if (item.type === "shell") {
      Quickshell.execDetached(["ghostty", "-e", "/bin/sh", "-c", item.command])
      return
    }
    switch (item.category) {
      case "video":
      case "audio":
        Quickshell.execDetached(["mpv", item.path])
        break
      case "dir":
        Quickshell.execDetached(["ghostty", "-e", "yazi", item.path])
        break
      default:
        Quickshell.execDetached(["xdg-open", item.path])
        break
    }
  }

  function openGoogle(query) {
    Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(query))
    root.open = false
  }

  function openYoutube(query) {
    Qt.openUrlExternally("https://www.youtube.com/results?search_query=" + encodeURIComponent(query))
    root.open = false
  }

  Timer {
    id: feedbackTimer
    interval: 1200
    onTriggered: root.aliasSavedFeedback = false
  }

  Timer {
    id: captureFeedbackTimer
    interval: 2000
    onTriggered: {
      root.captureSavedFeedback = false
      root.captureFeedbackText = ""
    }
  }

  readonly property string modePillText: {
    if (root.mode === "answer") return "ASK"
    if (root.mode === "file") return "FILE"
    if (root.mode === "google") return "GOOGLE"
    if (root.mode === "youtube") return "YOUTUBE"
    if (root.mode === "web") return "WEB"
    if (root.mode === "capture") return "CAP"
    if (root.mode === "shell") return "SHELL"
    if (root.mode === "shellcap") return "SC"
    return "APP"
  }

  readonly property string placeholderText: {
    if (root.mode === "answer") return "Ask anything..."
    if (root.mode === "file") return "Search files..."
    if (root.mode === "google") return "Search Google..."
    if (root.mode === "youtube") return "Search YouTube..."
    if (root.mode === "web") return "Type code to open..."
    if (root.mode === "capture") return "<url> <code>..."
    if (root.mode === "shell") return "Search commands..."
    if (root.mode === "shellcap") return "<command> <code>..."
    return "Search apps..."
  }

  SpotlightWindow {
    backend: root
  }
}
