#include "appsettings.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>

static const char *GROUP_SERIAL = "Serial";
static const char *GROUP_UI = "UI";
static const char *GROUP_SEND = "Send";
static const char *GROUP_QUICKSEND = "QuickSend";

static QString resolveConfigPath()
{
    // 1. Environment variable override (highest priority).
    const QByteArray envPath = qgetenv("CWY_SETTINGS_PATH");
    if (!envPath.isEmpty())
        return QString::fromLocal8Bit(envPath);

    // 2. Portable mode: CWY.ini next to the executable.
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString portablePath = appDir + QStringLiteral("/CWY.ini");
    if (QFileInfo::exists(portablePath))
        return portablePath;

    // 3. Default: AppDataLocation.
    const QString appDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!appDataDir.isEmpty())
        QDir().mkpath(appDataDir);
    return appDataDir + QStringLiteral("/CWY.ini");
}

AppSettings::AppSettings(QObject *parent)
    : QObject(parent)
    , m_settings(new QSettings(resolveConfigPath(), QSettings::IniFormat, this))
{
    m_syncTimer = new QTimer(this);
    m_syncTimer->setInterval(30000); // flush to disk every 30 seconds
    connect(m_syncTimer, &QTimer::timeout, this, &AppSettings::sync);
    m_syncTimer->start();

    // Ensure pending writes are flushed before the application exits.
    if (QCoreApplication::instance())
        connect(QCoreApplication::instance(), &QCoreApplication::aboutToQuit,
                this, &AppSettings::sync);
}

AppSettings::~AppSettings()
{
    sync();
}

QString AppSettings::configPath() const
{
    return m_settings ? m_settings->fileName() : QString();
}

void AppSettings::sync()
{
    if (m_settings)
        m_settings->sync();
}

void AppSettings::setValue(const QString &group, const QString &key, const QVariant &value)
{
    if (!m_settings)
        return;
    m_settings->beginGroup(group);
    m_settings->setValue(key, value);
    m_settings->endGroup();
}

// ── Serial ────────────────────────────────────────────────────────────────

QString AppSettings::portName() const
{
    return m_settings->value(QStringLiteral("Serial/portName"), QString()).toString();
}

void AppSettings::setPortName(const QString &value)
{
    if (portName() == value)
        return;
    setValue(QLatin1String(GROUP_SERIAL), QStringLiteral("portName"), value);
    emit portNameChanged();
}

int AppSettings::baudRate() const
{
    return m_settings->value(QStringLiteral("Serial/baudRate"), 115200).toInt();
}

void AppSettings::setBaudRate(int value)
{
    if (baudRate() == value)
        return;
    setValue(QLatin1String(GROUP_SERIAL), QStringLiteral("baudRate"), value);
    emit baudRateChanged();
}

int AppSettings::dataBits() const
{
    return m_settings->value(QStringLiteral("Serial/dataBits"), 8).toInt();
}

void AppSettings::setDataBits(int value)
{
    if (dataBits() == value)
        return;
    setValue(QLatin1String(GROUP_SERIAL), QStringLiteral("dataBits"), value);
    emit dataBitsChanged();
}

int AppSettings::stopBits() const
{
    return m_settings->value(QStringLiteral("Serial/stopBits"), 1).toInt();
}

void AppSettings::setStopBits(int value)
{
    if (stopBits() == value)
        return;
    setValue(QLatin1String(GROUP_SERIAL), QStringLiteral("stopBits"), value);
    emit stopBitsChanged();
}

int AppSettings::parity() const
{
    return m_settings->value(QStringLiteral("Serial/parity"), 0).toInt();
}

void AppSettings::setParity(int value)
{
    if (parity() == value)
        return;
    setValue(QLatin1String(GROUP_SERIAL), QStringLiteral("parity"), value);
    emit parityChanged();
}

int AppSettings::flowControl() const
{
    return m_settings->value(QStringLiteral("Serial/flowControl"), 0).toInt();
}

void AppSettings::setFlowControl(int value)
{
    if (flowControl() == value)
        return;
    setValue(QLatin1String(GROUP_SERIAL), QStringLiteral("flowControl"), value);
    emit flowControlChanged();
}

// ── UI / Application ──────────────────────────────────────────────────────

bool AppSettings::darkTheme() const
{
    return m_settings->value(QStringLiteral("UI/darkTheme"), false).toBool();
}

void AppSettings::setDarkTheme(bool value)
{
    if (darkTheme() == value)
        return;
    setValue(QLatin1String(GROUP_UI), QStringLiteral("darkTheme"), value);
    emit darkThemeChanged();
}

QString AppSettings::language() const
{
    return m_settings->value(QStringLiteral("UI/language"), QStringLiteral("zh_CN")).toString();
}

void AppSettings::setLanguage(const QString &value)
{
    if (language() == value)
        return;
    setValue(QLatin1String(GROUP_UI), QStringLiteral("language"), value);
    emit languageChanged();
}

bool AppSettings::showQuickSend() const
{
    return m_settings->value(QStringLiteral("UI/showQuickSend"), false).toBool();
}

void AppSettings::setShowQuickSend(bool value)
{
    if (showQuickSend() == value)
        return;
    setValue(QLatin1String(GROUP_UI), QStringLiteral("showQuickSend"), value);
    emit showQuickSendChanged();
}

bool AppSettings::autoLogEnabled() const
{
    return m_settings->value(QStringLiteral("UI/autoLogEnabled"), false).toBool();
}

void AppSettings::setAutoLogEnabled(bool value)
{
    if (autoLogEnabled() == value)
        return;
    setValue(QLatin1String(GROUP_UI), QStringLiteral("autoLogEnabled"), value);
    emit autoLogEnabledChanged();
}

QString AppSettings::autoLogFolder() const
{
    return m_settings->value(QStringLiteral("UI/autoLogFolder"), QString()).toString();
}

void AppSettings::setAutoLogFolder(const QString &value)
{
    if (autoLogFolder() == value)
        return;
    setValue(QLatin1String(GROUP_UI), QStringLiteral("autoLogFolder"), value);
    emit autoLogFolderChanged();
}

int AppSettings::windowWidth() const
{
    return m_settings->value(QStringLiteral("UI/windowWidth"), 1000).toInt();
}

void AppSettings::setWindowWidth(int value)
{
    if (windowWidth() == value || value <= 0)
        return;
    setValue(QLatin1String(GROUP_UI), QStringLiteral("windowWidth"), value);
    emit windowWidthChanged();
}

int AppSettings::windowHeight() const
{
    return m_settings->value(QStringLiteral("UI/windowHeight"), 700).toInt();
}

void AppSettings::setWindowHeight(int value)
{
    if (windowHeight() == value || value <= 0)
        return;
    setValue(QLatin1String(GROUP_UI), QStringLiteral("windowHeight"), value);
    emit windowHeightChanged();
}

// ── Send pane ─────────────────────────────────────────────────────────────

bool AppSettings::sendHexMode() const
{
    return m_settings->value(QStringLiteral("Send/sendHexMode"), false).toBool();
}

void AppSettings::setSendHexMode(bool value)
{
    if (sendHexMode() == value)
        return;
    setValue(QLatin1String(GROUP_SEND), QStringLiteral("sendHexMode"), value);
    emit sendHexModeChanged();
}

bool AppSettings::sendAppendCr() const
{
    return m_settings->value(QStringLiteral("Send/sendAppendCr"), false).toBool();
}

void AppSettings::setSendAppendCr(bool value)
{
    if (sendAppendCr() == value)
        return;
    setValue(QLatin1String(GROUP_SEND), QStringLiteral("sendAppendCr"), value);
    emit sendAppendCrChanged();
}

bool AppSettings::sendAppendLf() const
{
    return m_settings->value(QStringLiteral("Send/sendAppendLf"), false).toBool();
}

void AppSettings::setSendAppendLf(bool value)
{
    if (sendAppendLf() == value)
        return;
    setValue(QLatin1String(GROUP_SEND), QStringLiteral("sendAppendLf"), value);
    emit sendAppendLfChanged();
}

bool AppSettings::sendCyclicSend() const
{
    return m_settings->value(QStringLiteral("Send/sendCyclicSend"), false).toBool();
}

void AppSettings::setSendCyclicSend(bool value)
{
    if (sendCyclicSend() == value)
        return;
    setValue(QLatin1String(GROUP_SEND), QStringLiteral("sendCyclicSend"), value);
    emit sendCyclicSendChanged();
}

int AppSettings::sendCyclicInterval() const
{
    return m_settings->value(QStringLiteral("Send/sendCyclicInterval"), 1000).toInt();
}

void AppSettings::setSendCyclicInterval(int value)
{
    if (sendCyclicInterval() == value)
        return;
    setValue(QLatin1String(GROUP_SEND), QStringLiteral("sendCyclicInterval"), value);
    emit sendCyclicIntervalChanged();
}

// ── Quick send grid ───────────────────────────────────────────────────────

QString AppSettings::quickSendJson() const
{
    return m_settings->value(QStringLiteral("QuickSend/quickSendJson"), QString()).toString();
}

void AppSettings::setQuickSendJson(const QString &value)
{
    if (quickSendJson() == value)
        return;
    setValue(QLatin1String(GROUP_QUICKSEND), QStringLiteral("quickSendJson"), value);
    emit quickSendJsonChanged();
}
