#include "serialportmanager.h"
#include <QCoreApplication>
#include <QDate>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>
#include <QMetaObject>
#include <QCollator>
#include <algorithm>

SerialPortManager::SerialPortManager(QObject *parent)
    : QObject(parent)
    , m_workerThread(new QThread(this))
    , m_worker(new SerialWorker())
{
    m_worker->moveToThread(m_workerThread);

    // Worker signals forwarded to QML
    connect(m_worker, &SerialWorker::isOpenChanged, this, [this](bool open) {
        if (m_isOpen != open) {
            m_isOpen = open;
            emit isOpenChanged();
        }
    });
    connect(m_worker, &SerialWorker::bytesSent, this, &SerialPortManager::bytesSent);
    connect(m_worker, &SerialWorker::bytesReceived, this, &SerialPortManager::bytesReceived);
    connect(m_worker, &SerialWorker::errorOccurred, this, &SerialPortManager::errorOccurred);
    connect(m_worker, &SerialWorker::batchDataReady, this, &SerialPortManager::batchDataReady);
    connect(m_worker, &SerialWorker::recordingChanged, this, [this](bool recording) {
        if (m_recordingEnabled != recording) {
            m_recordingEnabled = recording;
            emit recordingEnabledChanged();
        }
    });

    m_workerThread->start();

    // Initialize worker objects on the worker thread
    QMetaObject::invokeMethod(m_worker, &SerialWorker::init, Qt::QueuedConnection);
}

SerialPortManager::~SerialPortManager()
{
    // Ask the worker to shut down cleanly on its own thread.
    QMetaObject::invokeMethod(m_worker, &SerialWorker::quit, Qt::QueuedConnection);

    // Request the worker thread's event loop to finish after pending events
    // (including the queued quit() call) are processed.
    m_workerThread->quit();
    if (!m_workerThread->wait(5000)) {
        qWarning() << "Worker thread did not stop within timeout; resources may leak";
        // Do NOT call terminate() — it can leave the serial port handle and
        // recording files in an inconsistent state.
    }

    delete m_worker;
    delete m_workerThread;
}

bool SerialPortManager::isOpen() const
{
    return m_isOpen;
}

QString SerialPortManager::portName() const { return m_portName; }
int SerialPortManager::baudRate() const { return m_baudRate; }
int SerialPortManager::dataBits() const { return m_dataBits; }
int SerialPortManager::stopBits() const { return m_stopBits; }
int SerialPortManager::parity() const { return m_parity; }
int SerialPortManager::flowControl() const { return m_flowControl; }
bool SerialPortManager::autoLogEnabled() const { return m_autoLogEnabled; }
QString SerialPortManager::autoLogFolder() const { return m_autoLogFolder; }
bool SerialPortManager::recordingEnabled() const { return m_recordingEnabled; }
QString SerialPortManager::recordingPath() const { return m_recordingPath; }

void SerialPortManager::setPortName(const QString &name)
{
    if (m_portName == name) return;
    m_portName = name;
    emit portNameChanged();
}

void SerialPortManager::setBaudRate(int rate)
{
    if (m_baudRate == rate) return;
    m_baudRate = rate;
    emit baudRateChanged();
}

void SerialPortManager::setDataBits(int bits)
{
    if (m_dataBits == bits) return;
    m_dataBits = bits;
    emit dataBitsChanged();
}

void SerialPortManager::setStopBits(int bits)
{
    if (m_stopBits == bits) return;
    m_stopBits = bits;
    emit stopBitsChanged();
}

void SerialPortManager::setParity(int parity)
{
    if (m_parity == parity) return;
    m_parity = parity;
    emit parityChanged();
}

void SerialPortManager::setFlowControl(int flow)
{
    if (m_flowControl == flow) return;
    m_flowControl = flow;
    emit flowControlChanged();
}

void SerialPortManager::setAutoLogEnabled(bool enabled)
{
    if (m_autoLogEnabled == enabled) return;
    m_autoLogEnabled = enabled;
    emit autoLogEnabledChanged();
    syncAutoLogToWorker();
}

void SerialPortManager::setAutoLogFolder(const QString &folder)
{
    if (m_autoLogFolder == folder) return;
    m_autoLogFolder = folder;
    emit autoLogFolderChanged();
    syncAutoLogToWorker();
}

void SerialPortManager::setRecordingEnabled(bool enabled)
{
    if (m_recordingEnabled == enabled) return;
    m_recordingEnabled = enabled;
    emit recordingEnabledChanged();
    syncRecordingToWorker();
}

void SerialPortManager::setRecordingPath(const QString &path)
{
    if (m_recordingPath == path) return;
    m_recordingPath = path;
    emit recordingPathChanged();
}

QVariantList SerialPortManager::availablePorts() const
{
    QVariantList ports;
    QList<QSerialPortInfo> infos = QSerialPortInfo::availablePorts();

    QCollator collator;
    collator.setNumericMode(true);
    std::sort(infos.begin(), infos.end(), [&collator](const QSerialPortInfo &a, const QSerialPortInfo &b) {
        return collator.compare(a.portName(), b.portName()) < 0;
    });

    for (const QSerialPortInfo &info : std::as_const(infos)) {
        QVariantMap port;
        port["name"] = info.portName();
        port["description"] = info.description();
        port["systemLocation"] = info.systemLocation();
        port["manufacturer"] = info.manufacturer();
        ports.append(port);
    }
    return ports;
}

bool SerialPortManager::openPort()
{
    qInfo() << "Request open port:" << m_portName
            << "baud=" << m_baudRate;
    QString name = m_portName;
    int baud = m_baudRate;
    int data = m_dataBits;
    int stop = m_stopBits;
    int par = m_parity;
    int flow = m_flowControl;
    QMetaObject::invokeMethod(m_worker, [this, name, baud, data, stop, par, flow]() {
        m_worker->openPort(name, baud, data, stop, par, flow);
    }, Qt::QueuedConnection);
    return true;
}

void SerialPortManager::closePort()
{
    qInfo() << "Request close port";
    QMetaObject::invokeMethod(m_worker, &SerialWorker::closePort, Qt::QueuedConnection);
}

bool SerialPortManager::sendText(const QString &text)
{
    QByteArray data = text.toUtf8();
    QMetaObject::invokeMethod(m_worker, [this, data]() {
        m_worker->sendData(data);
    }, Qt::QueuedConnection);
    return true;
}

bool SerialPortManager::sendHex(const QString &hexString)
{
    QByteArray data = hexStringToBytes(hexString);
    if (data.isEmpty() && !hexString.trimmed().isEmpty()) {
        qWarning() << "Invalid HEX format:" << hexString;
        emit errorOccurred(tr("Invalid HEX format"));
        return false;
    }
    QMetaObject::invokeMethod(m_worker, [this, data]() {
        m_worker->sendData(data);
    }, Qt::QueuedConnection);
    return true;
}

void SerialPortManager::startRecording(const QString &filePath)
{
    qInfo() << "Request start recording:" << filePath;
    setRecordingPath(filePath);
    setRecordingEnabled(true);
}

void SerialPortManager::stopRecording()
{
    qInfo() << "Request stop recording";
    setRecordingEnabled(false);
}

void SerialPortManager::syncAutoLogToWorker()
{
    QString folder = m_autoLogFolder;
    bool enabled = m_autoLogEnabled;
    QMetaObject::invokeMethod(m_worker, [this, folder, enabled]() {
        m_worker->setAutoLogFolder(folder, enabled);
    }, Qt::QueuedConnection);
}

void SerialPortManager::syncRecordingToWorker()
{
    QString path = m_recordingPath;
    bool enabled = m_recordingEnabled;
    if (enabled && !path.isEmpty()) {
        QMetaObject::invokeMethod(m_worker, [this, path]() {
            m_worker->startRecording(path);
        }, Qt::QueuedConnection);
    } else {
        QMetaObject::invokeMethod(m_worker, &SerialWorker::stopRecording, Qt::QueuedConnection);
    }
}

bool SerialPortManager::wouldConflictWithAutoLog(const QString &filePath) const
{
    if (!m_autoLogEnabled || m_autoLogFolder.isEmpty())
        return false;

    QString todayLog = QDate::currentDate().toString("yyyy-MM-dd") + QStringLiteral(".log");
    return QFileInfo(filePath).absoluteFilePath()
           == QFileInfo(m_autoLogFolder + QStringLiteral("/") + todayLog).absoluteFilePath();
}

bool SerialPortManager::wouldAutoLogConflict(bool autoLogEnabled, const QString &autoLogFolder) const
{
    if (!autoLogEnabled || autoLogFolder.isEmpty() || !m_recordingEnabled || m_recordingPath.isEmpty())
        return false;

    QString todayLog = QDate::currentDate().toString("yyyy-MM-dd") + QStringLiteral(".log");
    return QFileInfo(m_recordingPath).absoluteFilePath()
           == QFileInfo(autoLogFolder + QStringLiteral("/") + todayLog).absoluteFilePath();
}

bool SerialPortManager::wouldRecordingConflict(const QString &filePath) const
{
    if (!m_autoLogEnabled || m_autoLogFolder.isEmpty())
        return false;

    QString todayLog = QDate::currentDate().toString("yyyy-MM-dd") + QStringLiteral(".log");
    return QFileInfo(filePath).absoluteFilePath()
           == QFileInfo(m_autoLogFolder + QStringLiteral("/") + todayLog).absoluteFilePath();
}

QByteArray SerialPortManager::hexStringToBytes(const QString &hexString)
{
    QString cleaned = hexString;
    cleaned.remove(' ');
    cleaned.remove('\t');
    cleaned.remove('\n');
    cleaned.remove('\r');

    if (cleaned.isEmpty())
        return QByteArray();

    if (cleaned.length() % 2 != 0)
        return QByteArray();

    bool ok = false;
    QByteArray result;
    for (int i = 0; i < cleaned.length(); i += 2) {
        uint8_t byte = static_cast<uint8_t>(cleaned.mid(i, 2).toUInt(&ok, 16));
        if (!ok)
            return QByteArray();
        result.append(static_cast<char>(byte));
    }
    return result;
}

QString SerialPortManager::bytesToHexString(const QByteArray &bytes)
{
    QString result;
    result.reserve(bytes.size() * 3 + bytes.size() / 16);
    for (int i = 0; i < bytes.size(); ++i) {
        result.append(QString("%1 ").arg(static_cast<uchar>(bytes.at(i)), 2, 16, QChar('0')));
        if ((i + 1) % 16 == 0)
            result.append('\n');
    }
    if (!result.endsWith('\n') && !result.isEmpty())
        result.append('\n');
    return result;
}

QString SerialPortManager::readFile(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return QString();
    QTextStream stream(&file);
    QString content = stream.readAll();
    file.close();
    return content;
}

QString SerialPortManager::readFileAsHex(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return QString();
    QByteArray data = file.readAll();
    file.close();
    return bytesToHexString(data);
}

bool SerialPortManager::writeFile(const QString &filePath, const QString &content)
{
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        qWarning() << "Failed to open file for writing:" << filePath << file.errorString();
        return false;
    }

    QTextStream stream(&file);
    stream << content;
    const bool ok = (stream.status() == QTextStream::Ok);
    file.close();

    if (!ok)
        qWarning() << "Failed to write file:" << filePath;
    return ok;
}

QString SerialPortManager::applicationDirPath()
{
    return QCoreApplication::applicationDirPath();
}
