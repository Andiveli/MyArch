import QtQuick
import QtQuick.Controls
import "../singletons"

/**
 * Middle calendar — month grid + day agenda (Google iCal via CalendarService).
 * Tab / Shift+Tab: month · h/j/k/l: day · Enter: agenda list · j/k: row · l/Enter: detail · Esc: back.
 */
FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1
    property bool showConfig: false

    /** grid | list | detail */
    property string agendaPane: "grid"
    property int agendaIdx: 0

    readonly property var loc: Qt.locale()
    readonly property real s: Math.max(0.85, Style.fontPixelSize / 11)

    readonly property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    property int focusDay: today.getDate()

    readonly property int offset: firstWeekdayOffset(viewYear, viewMonth)
    readonly property int monthLen: daysInMonth(viewYear, viewMonth)
    readonly property int rows: Math.ceil((offset + monthLen) / 7)

    readonly property real cellH: 24 * s
    readonly property real rowGap: 2 * s
    readonly property real gridW: 282 * s
    readonly property real agendaW: 196 * s
    readonly property real gutter: 14 * s

    /** -1 / 0 / 1 — which month panel is centered in the viewport. */
    property int monthSlideIndex: 0
    property bool monthAnimating: false
    property int pendingMonthDelta: 0

    readonly property int prevYear: monthAdd(viewYear, viewMonth, -1).y
    readonly property int prevMonth: monthAdd(viewYear, viewMonth, -1).m
    readonly property int nextYear: monthAdd(viewYear, viewMonth, 1).y
    readonly property int nextMonth: monthAdd(viewYear, viewMonth, 1).m

    /** Month used for keyboard focus + agenda (follows visible panel during slide). */
    readonly property int navYear: monthSlideIndex === -1 ? prevYear
        : (monthSlideIndex === 1 ? nextYear : viewYear)
    readonly property int navMonth: monthSlideIndex === -1 ? prevMonth
        : (monthSlideIndex === 1 ? nextMonth : viewMonth)
    readonly property int navOffset: firstWeekdayOffset(navYear, navMonth)
    readonly property int navMonthLen: daysInMonth(navYear, navMonth)

    readonly property string selectedDate: focusDay >= 1 && focusDay <= navMonthLen
        ? dateKeyFor(navYear, navMonth, focusDay) : ""
    readonly property bool agendaShown: selectedDate.length > 0

    readonly property var dayEvents: CalendarService.forDate(selectedDate)
    readonly property var focusedEvent: {
        const ev = dayEvents
        if (!ev || !ev.length || agendaIdx < 0 || agendaIdx >= ev.length)
            return null
        return ev[agendaIdx]
    }

    readonly property real agendaColW: agendaPane === "detail" ? 248 * s : agendaW

    readonly property real gridHeight: monthCenter.implicitHeight + 28 * s

    readonly property real configW: ldConfig.item ? ldConfig.item.implicitWidth : 480 * s
    readonly property real configH: ldConfig.item ? ldConfig.item.implicitHeight : 400 * s

    implicitWidth: showConfig ? configW : (gridW + (agendaShown ? gutter + agendaColW : 0))
    implicitHeight: showConfig ? configH : Math.max(gridHeight, agendaCol.implicitHeight + 8 * s)

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    enabled: open
    focus: open

    function firstWeekdayOffset(year, month) {
        const d = new Date(year, month, 1).getDay()
        return (d + 6) % 7
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }

    function isToday(day) {
        return day === today.getDate()
            && viewMonth === today.getMonth()
            && viewYear === today.getFullYear()
    }

    function dateKey(day) {
        return dateKeyFor(viewYear, viewMonth, day)
    }

    function dateKeyFor(y, m, day) {
        const mo = m + 1
        const mm = mo < 10 ? "0" + mo : "" + mo
        const dd = day < 10 ? "0" + day : "" + day
        return y + "-" + mm + "-" + dd
    }

    function monthAdd(y, m, delta) {
        let nm = m + delta
        let ny = y
        while (nm < 0) { nm += 12; ny -= 1 }
        while (nm > 11) { nm -= 12; ny += 1 }
        return { y: ny, m: nm }
    }

    function clampFocusDay(y, m) {
        const len = daysInMonth(y, m)
        focusDay = Math.min(Math.max(1, focusDay), len)
    }

    function applyMonthDelta(delta) {
        const t = monthAdd(viewYear, viewMonth, delta)
        viewYear = t.y
        viewMonth = t.m
        clampFocusDay(t.y, t.m)
    }

    function shiftMonth(delta) {
        if (monthAnimating)
            return
        monthAnimating = true
        pendingMonthDelta = delta
        const targetIndex = delta > 0 ? 1 : -1
        monthSlideAnim.to = -gridW - targetIndex * gridW
        monthSlideAnim.start()
    }

    function commitSlideMonth() {
        if (pendingMonthDelta !== 0)
            applyMonthDelta(pendingMonthDelta)
        pendingMonthDelta = 0
        monthSlideAnim.stop()
        slideTrack.x = -gridW
        monthSlideIndex = 0
        monthAnimating = false
        Qt.callLater(() => gridFocusAnchor.forceActiveFocus())
    }

    function pickDay(y, m, day) {
        if (monthAnimating)
            return
        viewYear = y
        viewMonth = m
        focusDay = day
        monthSlideIndex = 0
        monthAnimating = false
        pendingMonthDelta = 0
        slideTrack.x = -gridW
        Qt.callLater(() => gridFocusAnchor.forceActiveFocus())
    }

    function resetToToday() {
        viewYear = today.getFullYear()
        viewMonth = today.getMonth()
        focusDay = today.getDate()
        monthSlideIndex = 0
        monthAnimating = false
        pendingMonthDelta = 0
        slideTrack.x = -gridW
    }

    function moveDay(dx, dy) {
        if (monthAnimating)
            return
        let y = navYear
        let m = navMonth
        let off = firstWeekdayOffset(y, m)
        let len = daysInMonth(y, m)
        const idx = off + focusDay - 1
        let col = idx % 7
        let row = Math.floor(idx / 7)
        col += dx
        row += dy
        while (col < 0) { col += 7; row -= 1 }
        while (col > 6) { col -= 7; row += 1 }
        const newIdx = row * 7 + col
        const newDay = newIdx - off + 1
        if (newDay >= 1 && newDay <= len) {
            viewYear = y
            viewMonth = m
            focusDay = newDay
            return
        }
        if (newDay < 1) {
            const p = monthAdd(y, m, -1)
            viewYear = p.y
            viewMonth = p.m
            focusDay = daysInMonth(p.y, p.m)
            return
        }
        const n = monthAdd(y, m, 1)
        viewYear = n.y
        viewMonth = n.m
        focusDay = 1
    }

    function fmtDayHeading(key) {
        const p = key.split("-")
        const d = new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]))
        return loc.toString(d, "ddd d MMM")
    }

    function eventMeta(ev) {
        if (!ev)
            return ""
        const t = ev.time || ""
        const e = ev.endTime || ""
        if (ev.allDay || !t.length)
            return "all day"
        return e.length ? t + "–" + e : t
    }

    onOpenChanged: {
        if (open) {
            showConfig = false
            agendaPane = "grid"
            agendaIdx = 0
            resetToToday()
            CalendarService.refresh()
            Qt.callLater(() => gridFocusAnchor.forceActiveFocus())
        } else {
            showConfig = false
            agendaPane = "grid"
        }
    }

    onSelectedDateChanged: {
        agendaIdx = 0
        if (agendaPane !== "grid" && dayEvents.length === 0)
            agendaPane = "grid"
        if (agendaPane === "list" && dayEvents.length > 0)
            agendaIdx = Math.min(agendaIdx, dayEvents.length - 1)
    }

    function clampAgendaScroll() {
        const rowH = 44 * s
        const target = agendaIdx * rowH
        const maxY = Math.max(0, agendaFlick.contentHeight - agendaFlick.height)
        agendaFlick.contentY = Math.max(0, Math.min(maxY, target - agendaFlick.height / 2 + rowH / 2))
    }

    function enterAgendaList() {
        if (!dayEvents.length)
            return
        agendaPane = "list"
        agendaIdx = 0
        Qt.callLater(() => {
            agendaFocusAnchor.forceActiveFocus()
            clampAgendaScroll()
        })
    }

    function enterAgendaDetail() {
        if (!focusedEvent)
            return
        agendaPane = "detail"
        Qt.callLater(() => agendaFocusAnchor.forceActiveFocus())
    }

    function handleGridKey(event) {
        const t = event.text
        if (event.key === Qt.Key_Escape) {
            ShellActions.closeMiddleSurface?.()
            event.accepted = true
            return
        }
        if (t === "s" || t === "S") {
            showConfig = true
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) {
            if (!monthAnimating)
                shiftMonth(1)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
            if (!monthAnimating)
                shiftMonth(-1)
            event.accepted = true
            return
        }
        if (monthAnimating)
            return
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            enterAgendaList()
            event.accepted = true
            return
        }
        if (t === "h" || event.key === Qt.Key_Left)
            moveDay(-1, 0)
        else if (t === "l" || event.key === Qt.Key_Right)
            moveDay(1, 0)
        else if (t === "j" || event.key === Qt.Key_Down)
            moveDay(0, 1)
        else if (t === "k" || event.key === Qt.Key_Up)
            moveDay(0, -1)
        else if (t === "r" || t === "R") {
            CalendarService.refresh()
            event.accepted = true
            return
        } else
            return
        event.accepted = true
    }

    function handleAgendaKey(event) {
        const t = event.text
        const n = dayEvents.length
        if (event.key === Qt.Key_Escape) {
            if (agendaPane === "detail") {
                agendaPane = "list"
                event.accepted = true
                return
            }
            agendaPane = "grid"
            Qt.callLater(() => gridFocusAnchor.forceActiveFocus())
            event.accepted = true
            return
        }
        if (agendaPane === "detail") {
            if (t === "h" || event.key === Qt.Key_Left) {
                agendaPane = "list"
                event.accepted = true
            }
            return
        }
        // list
        if (t === "h" || event.key === Qt.Key_Left) {
            agendaPane = "grid"
            Qt.callLater(() => gridFocusAnchor.forceActiveFocus())
            event.accepted = true
            return
        }
        if (t === "j" || event.key === Qt.Key_Down) {
            if (n > 0)
                agendaIdx = Math.min(n - 1, agendaIdx + 1)
            clampAgendaScroll()
            event.accepted = true
            return
        }
        if (t === "k" || event.key === Qt.Key_Up) {
            if (n > 0)
                agendaIdx = Math.max(0, agendaIdx - 1)
            clampAgendaScroll()
            event.accepted = true
            return
        }
        if (t === "l" || event.key === Qt.Key_Right
            || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            enterAgendaDetail()
            event.accepted = true
        }
    }

    Item {
        id: gridFocusAnchor
        width: 1
        height: 1
        focus: root.open && !root.showConfig && root.agendaPane === "grid"
        Keys.onPressed: event => root.handleGridKey(event)
    }

    Item {
        id: agendaFocusAnchor
        width: 1
        height: 1
        focus: root.open && !root.showConfig
            && (root.agendaPane === "list" || root.agendaPane === "detail")
        Keys.onPressed: event => root.handleAgendaKey(event)
    }

    Loader {
        id: ldConfig
        anchors.fill: parent
        active: root.open && root.showConfig
        source: "CalendarConfigSurface.qml"
        onLoaded: {
            if (!item)
                return
            item.open = Qt.binding(() => root.showConfig)
            item.morphCloseness = Qt.binding(() => root.morphCloseness)
            item.requestClose.connect(() => {
                root.showConfig = false
                Qt.callLater(() => gridFocusAnchor.forceActiveFocus())
            })
            item.saved.connect(() => { /* stay on settings until Esc — show fetch feedback */ })
        }
        onActiveChanged: if (active && item) {
            item.open = Qt.binding(() => root.showConfig)
            item.morphCloseness = Qt.binding(() => root.morphCloseness)
        }
    }

    Row {
        anchors.fill: parent
        spacing: root.gutter
        visible: !root.showConfig
        enabled: !root.showConfig

        Item {
            id: gridBlock
            width: root.gridW
            height: parent.height
            clip: true

            Row {
                anchors.top: parent.top
                anchors.right: parent.right
                spacing: 2 * root.s
                z: 2

                Repeater {
                    model: [-1, 1]
                    Rectangle {
                        id: nav
                        required property int modelData
                        width: 22 * root.s
                        height: 22 * root.s
                        radius: 6 * root.s
                        color: navArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                        border.width: navArea.containsMouse ? 1 : 0
                        border.color: WallustColors.borderColor
                        opacity: root.monthAnimating ? 0.35 : 1

                        Text {
                            anchors.centerIn: parent
                            text: nav.modelData < 0 ? "\uf053" : "\uf054"
                            opacity: navArea.containsMouse ? 1 : 0.45
                            color: WallustColors.moduleText
                            font.family: Style.fontFamily
                            font.pixelSize: 10 * root.s
                        }

                        MouseArea {
                            id: navArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !root.monthAnimating
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shiftMonth(nav.modelData)
                        }
                    }
                }
            }

            Item {
                id: monthViewport
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: hintText.top
                anchors.bottomMargin: 4 * root.s
                clip: true

                Item {
                    id: slideTrack
                    width: root.gridW * 3
                    height: parent.height
                    x: -root.gridW

                    onXChanged: {
                        const w = root.gridW
                        if (w < 1)
                            return
                        const idx = Math.round((-x - w) / w)
                        if (idx === root.monthSlideIndex)
                            return
                        root.monthSlideIndex = Math.max(-1, Math.min(1, idx))
                    }

                    PropertyAnimation {
                        id: monthSlideAnim
                        target: slideTrack
                        property: "x"
                        duration: Motion.morph
                        easing.type: Motion.easeMorph
                        easing.bezierCurve: Motion.morphCurve
                        onFinished: root.commitSlideMonth()
                    }

                    CalendarMonthPanel {
                        id: monthPrev
                        x: 0
                        y: 0
                        panelYear: root.prevYear
                        panelMonth: root.prevMonth
                        focusYear: root.navYear
                        focusMonth: root.navMonth
                        focusDay: root.focusDay
                        today: root.today
                        onCellClicked: (y, m, d) => root.pickDay(y, m, d)
                    }

                    CalendarMonthPanel {
                        id: monthCenter
                        x: root.gridW
                        y: 0
                        panelYear: root.viewYear
                        panelMonth: root.viewMonth
                        focusYear: root.navYear
                        focusMonth: root.navMonth
                        focusDay: root.focusDay
                        today: root.today
                        onCellClicked: (y, m, d) => root.pickDay(y, m, d)
                    }

                    CalendarMonthPanel {
                        id: monthNext
                        x: root.gridW * 2
                        y: 0
                        panelYear: root.nextYear
                        panelMonth: root.nextMonth
                        focusYear: root.navYear
                        focusMonth: root.navMonth
                        focusDay: root.focusDay
                        today: root.today
                        onCellClicked: (y, m, d) => root.pickDay(y, m, d)
                    }
                }
            }

            Text {
                id: hintText
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width
                wrapMode: Text.Wrap
                text: {
                    if (CalendarService.loading)
                        return "Refreshing…"
                    if (!CalendarService.configured)
                        return "Press s — paste Google iCal URL(s) · gitignored secrets file"
                    if (CalendarService.lastError.length)
                        return CalendarService.lastError
                    return "Enter agenda · Tab month · h/j/k/l day · s · r · Esc"
                }
                color: WallustColors.moduleText
                opacity: 0.4
                font.family: Style.fontFamily
                font.pixelSize: 8.5 * root.s
            }
        }

        Rectangle {
            visible: root.agendaShown
            width: 1
            height: parent.height
            color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g, WallustColors.borderColor.b, 0.35)
        }

        Column {
            id: agendaCol
            visible: root.agendaShown
            width: root.agendaColW
            spacing: 8 * root.s

            Behavior on width {
                NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
            }

            Text {
                width: parent.width
                text: root.fmtDayHeading(root.selectedDate)
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: 12 * root.s
                font.bold: true
                font.capitalization: Font.AllUppercase
                elide: Text.ElideRight
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g, WallustColors.borderColor.b, 0.35)
            }

            // —— Event detail ——
            Column {
                width: parent.width
                spacing: 8 * root.s
                visible: root.agendaPane === "detail" && root.focusedEvent
                height: visible ? implicitHeight : 0

                Text {
                    width: parent.width
                    text: root.focusedEvent ? (root.focusedEvent.text || "?") : ""
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: 12 * root.s
                    font.bold: true
                    wrapMode: Text.Wrap
                }
                Text {
                    width: parent.width
                    text: root.focusedEvent ? root.eventMeta(root.focusedEvent) : ""
                    color: WallustColors.yellow
                    font.family: Style.fontFamily
                    font.pixelSize: 10 * root.s
                    font.bold: true
                }
                Row {
                    width: parent.width
                    spacing: 6 * root.s
                    visible: root.focusedEvent && (root.focusedEvent.location || "").length > 0

                    Text {
                        id: locPin
                        anchors.top: locText.top
                        anchors.topMargin: 1 * root.s
                        text: "\uf041"
                        color: WallustColors.sky
                        font.family: Style.fontFamily
                        font.pixelSize: 10 * root.s
                    }
                    Text {
                        id: locText
                        width: parent.width - locPin.implicitWidth - 6 * root.s
                        text: root.focusedEvent ? root.focusedEvent.location : ""
                        color: WallustColors.sky
                        font.family: Style.fontFamily
                        font.pixelSize: 9.5 * root.s
                        wrapMode: Text.Wrap
                    }
                }
                Text {
                    width: parent.width
                    visible: root.focusedEvent && (root.focusedEvent.description || "").length > 0
                    text: root.focusedEvent ? root.focusedEvent.description : ""
                    color: WallustColors.moduleText
                    opacity: 0.75
                    font.family: Style.fontFamily
                    font.pixelSize: 9.5 * root.s
                    wrapMode: Text.Wrap
                }
                Text {
                    width: parent.width
                    text: "h/Esc list · Esc close"
                    color: WallustColors.moduleText
                    opacity: 0.35
                    font.family: Style.fontFamily
                    font.pixelSize: 8.5 * root.s
                }
            }

            Flickable {
                id: agendaFlick
                width: parent.width
                height: root.agendaPane === "detail" ? 0
                    : Math.min(agendaList.implicitHeight, 220 * root.s)
                visible: root.agendaPane !== "detail"
                contentHeight: agendaList.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: agendaList
                    width: agendaFlick.width
                    spacing: 4 * root.s

                    Text {
                        visible: root.dayEvents.length === 0 && !CalendarService.loading
                        text: "Nothing scheduled"
                        color: WallustColors.moduleText
                        opacity: 0.35
                        font.family: Style.fontFamily
                        font.pixelSize: 11 * root.s
                        font.italic: true
                    }

                    Repeater {
                        model: root.dayEvents

                        Rectangle {
                            id: evRow
                            required property int index
                            required property var modelData
                            width: agendaList.width
                            height: evBody.implicitHeight + 12 * root.s
                            radius: 6 * root.s
                            readonly property bool picked: root.agendaPane === "list"
                                && root.agendaIdx === index
                            color: picked ? Qt.alpha(WallustColors.buttonHover, 0.2)
                                : (evArea.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                            border.width: picked ? 1 : 0
                            border.color: Qt.alpha(WallustColors.buttonHover, 0.55)

                            HoverHandler { id: evArea }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.agendaIdx = evRow.index
                                    root.agendaPane = "list"
                                    root.enterAgendaDetail()
                                }
                            }

                            Column {
                                id: evBody
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 6 * root.s
                                spacing: 2 * root.s

                                Text {
                                    text: evRow.modelData.text || "?"
                                    width: parent.width
                                    color: WallustColors.moduleText
                                    font.family: Style.fontFamily
                                    font.pixelSize: 11 * root.s
                                    wrapMode: Text.Wrap
                                    maximumLineCount: root.agendaPane === "list" && root.agendaIdx === evRow.index ? 6 : 3
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: root.eventMeta(evRow.modelData)
                                    width: parent.width
                                    color: WallustColors.yellow
                                    font.family: Style.fontFamily
                                    font.pixelSize: 9 * root.s
                                    font.bold: true
                                    font.features: { "tnum": 1 }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: root.agendaPane === "list"
                text: "j/k · l/Enter detail · h grid · Esc"
                color: WallustColors.moduleText
                opacity: 0.35
                font.family: Style.fontFamily
                font.pixelSize: 8.5 * root.s
            }
            Text {
                width: parent.width
                visible: root.agendaPane === "grid" && root.dayEvents.length > 0
                text: "Enter list · h/l day"
                color: WallustColors.moduleText
                opacity: 0.35
                font.family: Style.fontFamily
                font.pixelSize: 8.5 * root.s
            }
        }
    }
}