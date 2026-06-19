import QtQuick
import QtQuick.Controls

// Thin wrapper around ComboBox. The actual light/dark palette for the
// FluentWinUI3 style now comes from QStyleHints::colorScheme, which is kept in
// sync with Ripple.Theme.darkTheme in main.cpp. Keeping this component makes it
// easy to apply a uniform tweak to every combo box later if needed.
ComboBox {
    id: root
}
