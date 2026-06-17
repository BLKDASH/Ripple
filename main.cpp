#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTranslator>
#include <QLocale>
#include "src/serialportmanager.h"
#include "src/translator.h"
#include "src/receivemodel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setOrganizationName("CWY");
    app.setOrganizationDomain("cwy.local");
    app.setApplicationName("CWY Serial Assistant");

    QQuickStyle::setStyle("Fusion");

    // Create singleton instances explicitly so we can wire them together in C++.
    SerialPortManager *serialManager = new SerialPortManager();
    ReceiveModel *receiveModel = new ReceiveModel();

    qmlRegisterSingletonInstance("CWY.Serial", 1, 0, "SerialPort", serialManager);
    qmlRegisterSingletonInstance("CWY.Receive", 1, 0, "ReceiveModel", receiveModel);

    // Worker thread feeds the UI model directly on the main thread.
    QObject::connect(serialManager, &SerialPortManager::batchDataReady,
                     receiveModel, &ReceiveModel::appendBatch);

    QQmlApplicationEngine engine;

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
