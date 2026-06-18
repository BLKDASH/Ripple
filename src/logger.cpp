#include "logger.h"
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QDateTime>
#include <QDebug>
#include <iostream>

Logger *Logger::s_instance = nullptr;

Logger::Logger(QObject *parent)
    : QObject(parent)
{
    s_instance = this;

    QString dirPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(dirPath);
    if (!dir.exists())
        dir.mkpath(dirPath);

    m_logPath = dirPath + QStringLiteral("/cwy.log");
    rotateLogIfNeeded();
    m_file.setFileName(m_logPath);
    m_open = m_file.open(QIODevice::Append | QIODevice::Text);
    if (m_open) {
        m_stream.setDevice(&m_file);
        write(QtInfoMsg, QStringLiteral("=== CWY Serial Assistant started ==="));
    }

    qInstallMessageHandler(Logger::messageHandler);
}

Logger::~Logger()
{
    qInstallMessageHandler(nullptr);
    s_instance = nullptr;
}

Logger *Logger::instance()
{
    return s_instance;
}

QString Logger::logPath() const
{
    return m_logPath;
}

void Logger::rotateLogIfNeeded()
{
    static const qint64 MaxLogSize = 5 * 1024 * 1024; // 5 MB

    QFileInfo info(m_logPath);
    if (!info.exists() || info.size() < MaxLogSize)
        return;

    QString oldPath = m_logPath + QStringLiteral(".old");
    QFile::remove(oldPath);
    QFile::rename(m_logPath, oldPath);
}

void Logger::debug(const QString &message)
{
    write(QtDebugMsg, message);
}

void Logger::info(const QString &message)
{
    write(QtInfoMsg, message);
}

void Logger::warning(const QString &message)
{
    write(QtWarningMsg, message);
}

void Logger::error(const QString &message)
{
    write(QtCriticalMsg, message);
}

void Logger::messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    Q_UNUSED(context)
    if (s_instance && s_instance->m_open) {
        s_instance->write(type, msg);
    }

    // In Debug builds also echo to stderr so Qt Creator's Application Output
    // panel shows the log while developing. Release builds only write to file.
#ifdef QT_DEBUG
    const char *level = "???";
    switch (type) {
    case QtDebugMsg: level = "DBG"; break;
    case QtInfoMsg: level = "INF"; break;
    case QtWarningMsg: level = "WRN"; break;
    case QtCriticalMsg: level = "ERR"; break;
    case QtFatalMsg: level = "FTL"; break;
    }
    std::cerr << "[" << level << "] " << qPrintable(msg) << std::endl;
#else
    Q_UNUSED(type)
#endif
}

void Logger::write(QtMsgType type, const QString &message)
{
    QMutexLocker locker(&m_mutex);
    if (!m_open)
        return;

    const char *level = "???";
    switch (type) {
    case QtDebugMsg: level = "DBG"; break;
    case QtInfoMsg: level = "INF"; break;
    case QtWarningMsg: level = "WRN"; break;
    case QtCriticalMsg: level = "ERR"; break;
    case QtFatalMsg: level = "FTL"; break;
    }

    m_stream << QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd hh:mm:ss.zzz"))
             << QStringLiteral(" [") << level << QStringLiteral("] ") << message << QLatin1Char('\n');
    m_stream.flush();
}
