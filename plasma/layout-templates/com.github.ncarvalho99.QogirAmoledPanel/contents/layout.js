// Qogir's top bar, ported from the upstream Qogir-kde desktop layout.
var panel = new Panel
panel.location = "top"
panel.height = 2 * Math.floor(gridUnit * 1.8 / 2)
panel.floating = false

var kickoff = panel.addWidget("org.kde.plasma.kickoff")
kickoff.currentConfigGroup = ["Shortcuts"]
kickoff.writeConfig("global", "Alt+F1")

panel.addWidget("org.kde.plasma.appmenu")
panel.addWidget("org.kde.plasma.panelspacer")
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.splitdigitalclock")
panel.addWidget("org.kde.milou")
