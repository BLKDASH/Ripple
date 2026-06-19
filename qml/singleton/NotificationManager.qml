pragma Singleton
import QtQuick

// Global notification manager.
// Replaces the dynamic-scope `notify` id that components used to reach
// NotifyOverlay in Main.qml. Any QML file can now call:
//   NotificationManager.error("message")
//   NotificationManager.warning("message")
//   NotificationManager.success("message")
//   NotificationManager.info("message")
QtObject {
    id: root

    function error(msg, duration)   { show(msg, "error",   duration || 5000) }
    function warning(msg, duration) { show(msg, "warning", duration || 3500) }
    function success(msg, duration) { show(msg, "success", duration || 2500) }
    function info(msg, duration)    { show(msg, "info",    duration || 2500) }

    // Read-only from the outside; NotifyOverlay.qml binds to this model.
    property ListModel model: ListModel {}

    property int _uidSeq: 0

    function show(msg, type, duration) {
        if (!msg || msg === "")
            return
        // Prevent runaway toasts if errors flood in.
        if (root.model.count >= 8)
            root.model.remove(0)
        _uidSeq++
        root.model.append({
            uid: _uidSeq,
            message: msg,
            type: type,
            duration: duration
        })
    }

    function remove(uid) {
        for (var i = 0; i < root.model.count; i++) {
            if (root.model.get(i).uid === uid) {
                root.model.remove(i)
                break
            }
        }
    }
}
