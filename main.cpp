#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStyleHints>
#include <QTranslator>
#include <QLocale>
#include "src/appsettings.h"
#include "src/serialportmanager.h"
#include "src/translator.h"
#include "src/receivemodel.h"
#include "src/logger.h"

class ThemeSyncHelper : public QObject
{
    Q_OBJECT
public:
    ThemeSyncHelper(QObject *theme, QStyleHints *styleHints, QObject *parent = nullptr)
        : QObject(parent), m_theme(theme), m_styleHints(styleHints) {}

public slots:
    void sync()
    {
        m_styleHints->setColorScheme(m_theme->property("darkTheme").toBool()
                                         ? Qt::ColorScheme::Dark
                                         : Qt::ColorScheme::Light);
    }

private:
    QObject *m_theme;
    QStyleHints *m_styleHints;
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setOrganizationName("CWY");
    app.setOrganizationDomain("cwy.local");
    app.setApplicationName("CWY Serial Assistant");

    QQuickStyle::setStyle("FluentWinUI3");

    // Create singleton instances explicitly so we can wire them together in C++.
    // AppSettings must be created before SerialPortManager so the latter can
    // restore persisted serial defaults during startup.
    Logger *logger = new Logger(&app);
    AppSettings *appSettings = new AppSettings(&app);
    SerialPortManager *serialManager = new SerialPortManager(&app);
    ReceiveModel *receiveModel = new ReceiveModel(&app);

    // Restore persisted serial configuration before QML loads.
    serialManager->setPortName(appSettings->portName());
    serialManager->setBaudRate(appSettings->baudRate());
    serialManager->setDataBits(appSettings->dataBits());
    serialManager->setStopBits(appSettings->stopBits());
    serialManager->setParity(appSettings->parity());
    serialManager->setFlowControl(appSettings->flowControl());

    // Persist any serial parameter changes made from QML.
    QObject::connect(serialManager, &SerialPortManager::portNameChanged, appSettings,
                     [serialManager, appSettings]() { appSettings->setPortName(serialManager->portName()); });
    QObject::connect(serialManager, &SerialPortManager::baudRateChanged, appSettings,
                     [serialManager, appSettings]() { appSettings->setBaudRate(serialManager->baudRate()); });
    QObject::connect(serialManager, &SerialPortManager::dataBitsChanged, appSettings,
                     [serialManager, appSettings]() { appSettings->setDataBits(serialManager->dataBits()); });
    QObject::connect(serialManager, &SerialPortManager::stopBitsChanged, appSettings,
                     [serialManager, appSettings]() { appSettings->setStopBits(serialManager->stopBits()); });
    QObject::connect(serialManager, &SerialPortManager::parityChanged, appSettings,
                     [serialManager, appSettings]() { appSettings->setParity(serialManager->parity()); });
    QObject::connect(serialManager, &SerialPortManager::flowControlChanged, appSettings,
                     [serialManager, appSettings]() { appSettings->setFlowControl(serialManager->flowControl()); });
    QObject::connect(serialManager, &SerialPortManager::autoLogEnabledChanged, appSettings,
                     [serialManager, appSettings]() { appSettings->setAutoLogEnabled(serialManager->autoLogEnabled()); });
    QObject::connect(serialManager, &SerialPortManager::autoLogPathChanged, appSettings,
                     [serialManager, appSettings]() { appSettings->setAutoLogPath(serialManager->autoLogPath()); });

    qmlRegisterSingletonInstance("CWY.Logger", 1, 0, "Logger", logger);
    qmlRegisterSingletonInstance("CWY.AppSettings", 1, 0, "AppSettings", appSettings);
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
    const int themeTypeId =
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

    // Keep the FluentWinUI3 style in sync with the in-app theme toggle so that
    // native-looking controls pick up the correct light/dark palette automatically.
    QStyleHints *styleHints = app.styleHints();
    styleHints->setColorScheme(appSettings->darkTheme() ? Qt::ColorScheme::Dark
                                                        : Qt::ColorScheme::Light);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("CWY", "Main");

    if (QObject *theme = engine.singletonInstance<QObject *>(themeTypeId)) {
        auto *helper = new ThemeSyncHelper(theme, styleHints, &app);
        QObject::connect(theme, SIGNAL(darkThemeChanged()),
                         helper, SLOT(sync()), Qt::QueuedConnection);
    }

    return QGuiApplication::exec();
}

#include "main.moc"
