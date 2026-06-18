#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTranslator>
#include <QLocale>
#include "src/serialportmanager.h"
#include "src/translator.h"
#include "src/receivemodel.h"
#include "src/logger.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setOrganizationName("CWY");
    app.setOrganizationDomain("cwy.local");
    app.setApplicationName("CWY Serial Assistant");

    QQuickStyle::setStyle("FluentWinUI3");

    // Create singleton instances explicitly so we can wire them together in C++.
    Logger *logger = new Logger(&app);
    SerialPortManager *serialManager = new SerialPortManager();
    ReceiveModel *receiveModel = new ReceiveModel();

    qmlRegisterSingletonInstance("CWY.Logger", 1, 0, "Logger", logger);
    qmlRegisterSingletonInstance("CWY.Serial", 1, 0, "SerialPort", serialManager);
    qmlRegisterSingletonInstance("CWY.Receive", 1, 0, "ReceiveModel", receiveModel);

    // Worker thread feeds the UI model directly on the main thread.
    QObject::connect(serialManager, &SerialPortManager::batchDataReady,
                     receiveModel, &ReceiveModel::appendBatch);

    QQmlApplicationEngine engine;

    // Register Theme and NotificationManager as singleton types under their own
    // URIs. This is more reliable than relying on qt_add_qml_module's singleton
    // property which may not emit the `singleton` keyword in qmldir on all Qt
    // versions.
    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/qt/qml/CWY/Theme.qml")),
                             "CWY.Theme", 1, 0, "Theme");
    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/qt/qml/CWY/NotificationManager.qml")),
                             "CWY.NotificationManager", 1, 0, "NotificationManager");

    Translator translator(&engine);
    qmlRegisterSingletonType<Translator>("CWY.I18n", 1, 0, "Translator",
        [&translator](QQmlEngine *qmlEngine, QJSEngine *scriptEngine) -> QObject * {
            Q_UNUSED(qmlEngine)
            Q_UNUSED(scriptEngine)
            return &translator;
        });

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("CWY", "Main");

    return QGuiApplication::exec();
}
