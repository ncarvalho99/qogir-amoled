// Global theme layout: only runs when "Desktop and window layout" is ticked
// while applying Qogir AMOLED, and replaces the current panels.
loadTemplate("com.github.ncarvalho99.QogirAmoledPanel")

var wallpaper = userDataPath("data", "wallpapers/Qogir-amoled")
desktops().forEach(function (desktop) {
    desktop.wallpaperPlugin = "org.kde.image"
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"]
    desktop.writeConfig("Image", "file://" + wallpaper)
})
