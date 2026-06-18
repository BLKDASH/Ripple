#include "serialworker.h"
#include <QDate>
#include <QDateTime>
#include <QDebug>

static QString normalizeLogLine(const QString &text)
{
    QString line = text;
    line.replace("\r\n", "\n");
    line.replace('\r', '\n');
    while (line.endsWith('\n'))
        line.chop(1);
    return line;
}

static QString hexPreview(const QByteArray &data, int maxBytes = 64)
{
    QByteArray preview = data.left(maxBytes);
    QString hex = QString::fromLatin1(preview.toHex(' '));
    if (data.size() > maxBytes)
        hex += QStringLiteral(" ... (%1 more bytes)").arg(data.size() - maxBytes);
    return QStringLiteral("[Binary data (%1 bytes): %2]").arg(data.size()).arg(hex);
}

// Try to interpret the raw bytes as UTF-8 text. If a significant fraction of
// the decoded characters are Unicode replacement characters, the data is almost
// certainly binary and should be logged as a hex preview to avoid polluting the
// log file with replacement characters.
static QString formatLogData(const QByteArray &data)
{
    const QString text = QString::fromUtf8(data);
    int replacementCount = 0;
    for (const QChar &c : text) {
        if (c.unicode() == QChar::ReplacementCharacter)
            replacementCount++;
    }

    // Heuristic: more than 5 % replacement characters means binary data.
    if (!text.isEmpty() && replacementCount * 20 > text.size())
        return hexPreview(data);

    return text;
}

SerialWorker::SerialWorker(QObject *parent)
    : QObject(parent)
{
}

SerialWorker::~SerialWorker()
{
    stopRecording();
    closeAutoLogFile();
    if (m_serialPort && m_serialPort->isOpen())
        m_serialPort->close();
    // Use deleteLater() as a safety net — normal cleanup is done in quit()
    // on the worker thread to avoid cross-thread timer warnings.
    if (m_serialPort) {
        m_serialPort->deleteLater();
        m_serialPort = nullptr;
    }
    if (m_warmupTimer) {
        m_warmupTimer->deleteLater();
        m_warmupTimer = nullptr;
    }
    if (m_batchTimer) {
        m_batchTimer->deleteLater();
        m_batchTimer = nullptr;
    }
}

void SerialWorker::init()
{
    // Called on the worker thread after moveToThread
    m_serialPort = new QSerialPort(this);
    m_warmupTimer = new QTimer(this);
    m_batchTimer = new QTimer(this);

    m_warmupTimer->setSingleShot(true);
    connect(m_warmupTimer, &QTimer::timeout, this, &SerialWorker::endWarmup);

    connect(m_serialPort, &QSerialPort::readyRead, this, &SerialWorker::readData);
    connect(m_serialPort, &QSerialPort::errorOccurred, this, &SerialWorker::handleError);

    m_batchTimer->setSingleShot(true);
    connect(m_batchTimer, &QTimer::timeout, this, &SerialWorker::flushBatch);
}

void SerialWorker::quit()
{
    // Flush any pending UI batch before the event loop stops.
    flushBatch();

    closePort();
    stopRecording();
    closeAutoLogFile();

    // Clean up objects that were created on this worker thread.
    // Deleting them here instead of the destructor avoids
    // "Timers cannot be stopped from another thread" warnings.
    delete m_serialPort;
    m_serialPort = nullptr;
    delete m_warmupTimer;
    m_warmupTimer = nullptr;
    delete m_batchTimer;
    m_batchTimer = nullptr;
}

void SerialWorker::openPort(const QString &name, int baudRate, int dataBits, int stopBits, int parity, int flowControl)
{
    if (!m_serialPort)
        return;

    if (m_serialPort->isOpen())
        closePort();

    if (name.isEmpty()) {
        emit errorOccurred(tr("No serial port selected"));
        return;
    }

    m_serialPort->setPortName(name);
    m_serialPort->setBaudRate(static_cast<qint32>(baudRate));
    m_serialPort->setDataBits(static_cast<QSerialPort::DataBits>(dataBits));
    m_serialPort->setStopBits(static_cast<QSerialPort::StopBits>(stopBits));
    m_serialPort->setParity(static_cast<QSerialPort::Parity>(parity));
    m_serialPort->setFlowControl(static_cast<QSerialPort::FlowControl>(flowControl));

    if (!m_serialPort->open(QIODevice::ReadWrite)) {
        // handleError() is already connected to QSerialPort::errorOccurred
        // and will emit errorOccurred — avoid double emission here.
        qWarning() << "Failed to open serial port" << name;
        emit isOpenChanged(false);
        return;
    }

    qInfo() << "Serial port opened:" << name
            << "baud=" << baudRate
            << "data=" << dataBits
            << "stop=" << stopBits
            << "parity=" << parity
            << "flow=" << flowControl;

    // Discard any stale/noise data that may be present right after opening.
    m_serialPort->clear(QSerialPort::Input);
    m_serialPort->readAll();

    // Ignore incoming data for a short warmup period to let the line stabilize.
    m_inWarmup = true;
    m_warmupTimer->start(150);

    emit isOpenChanged(true);
    openAutoLogFile();
}

void SerialWorker::closePort()
{
    if (!m_serialPort || !m_serialPort->isOpen())
        return;

    qInfo() << "Serial port closed:" << m_serialPort->portName();
    m_serialPort->close();
    emit isOpenChanged(false);
    closeAutoLogFile();
}

void SerialWorker::sendData(const QByteArray &data)
{
    if (!m_serialPort || !m_serialPort->isOpen()) {
        emit errorOccurred(tr("Serial port is not open"));
        return;
    }

    qint64 written = m_serialPort->write(data);
    if (written == -1) {
        qWarning() << "Serial write failed:" << m_serialPort->errorString();
        emit errorOccurred(m_serialPort->errorString());
        return;
    }
    // Do not call QSerialPort::flush() here — it blocks the worker thread's
    // event loop and can stall readyRead/batch timer processing at high baud
    // rates. The OS transmit buffer already holds the data after write().
    emit bytesSent(written);
}

void SerialWorker::startRecording(const QString &filePath)
{
    if (m_recordFile) {
        stopRecording();
    }

    m_recordFile = new QFile(filePath, this);
    QIODevice::OpenMode mode = QIODevice::Append;
    if (!filePath.endsWith(".bin", Qt::CaseInsensitive))
        mode |= QIODevice::Text;

    if (!m_recordFile->open(mode)) {
        qWarning() << "Failed to open recording file:" << filePath;
        emit errorOccurred(tr("Failed to open recording file: %1").arg(filePath));
        delete m_recordFile;
        m_recordFile = nullptr;
        return;
    }

    qInfo() << "Recording started:" << filePath;

    if (!filePath.endsWith(".bin", Qt::CaseInsensitive))
        m_recordStream = new QTextStream(m_recordFile);

    m_recordPath = filePath;
    m_recordingEnabled = true;
    emit recordingChanged(true);
}

void SerialWorker::stopRecording()
{
    if (m_recordStream) {
        m_recordStream->flush();
        delete m_recordStream;
        m_recordStream = nullptr;
    }
    if (m_recordFile) {
        m_recordFile->close();
        delete m_recordFile;
        m_recordFile = nullptr;
    }
    m_recordPath.clear();
    if (m_recordingEnabled) {
        m_recordingEnabled = false;
        qInfo() << "Recording stopped";
        emit recordingChanged(false);
    }
}

void SerialWorker::setAutoLogFolder(const QString &folder, bool enabled)
{
    // Close any existing auto-log file
    closeAutoLogFile();

    m_autoLogEnabled = enabled;
    m_autoLogFolder = folder;

    if (enabled && !folder.isEmpty()) {
        qInfo() << "Auto-log folder set:" << folder;
    } else if (!enabled) {
        qInfo() << "Auto-log disabled";
    }

    // If port is currently open, open the log file immediately
    if (m_serialPort && m_serialPort->isOpen() && enabled && !folder.isEmpty()) {
        openAutoLogFile();
    }
}

void SerialWorker::openAutoLogFile()
{
    if (!m_autoLogEnabled || m_autoLogFolder.isEmpty())
        return;

    if (m_autoLogFile)
        closeAutoLogFile();

    QString fileName = QDate::currentDate().toString("yyyy-MM-dd") + QStringLiteral(".log");
    QString filePath = m_autoLogFolder + QStringLiteral("/") + fileName;

    m_autoLogFile = new QFile(filePath, this);
    if (m_autoLogFile->open(QIODevice::Append | QIODevice::Text)) {
        m_autoLogStream = new QTextStream(m_autoLogFile);
        qInfo() << "Auto-log opened:" << filePath;
    } else {
        qWarning() << "Failed to open auto-log file:" << filePath;
        emit errorOccurred(tr("Failed to open auto-log file: %1").arg(filePath));
        delete m_autoLogFile;
        m_autoLogFile = nullptr;
    }
}

void SerialWorker::closeAutoLogFile()
{
    if (m_autoLogStream) {
        m_autoLogStream->flush();
        delete m_autoLogStream;
        m_autoLogStream = nullptr;
    }
    if (m_autoLogFile) {
        m_autoLogFile->close();
        delete m_autoLogFile;
        m_autoLogFile = nullptr;
    }
}

void SerialWorker::readData()
{
    if (!m_serialPort || !m_serialPort->isOpen())
        return;

    QByteArray data = m_serialPort->readAll();
    if (data.isEmpty())
        return;

    if (m_inWarmup)
        return;

    // Capture the actual arrival time on the worker thread, before any
    // batching or UI formatting delays. Use milliseconds since epoch so it
    // survives the queued cross-thread signal in a QVariantMap.
    qint64 arrivalTimeMs = QDateTime::currentDateTime().toMSecsSinceEpoch();
    QDateTime arrivalTime = QDateTime::fromMSecsSinceEpoch(arrivalTimeMs);

    // Synchronous file append for recording
    if (m_recordingEnabled)
        writeRecord(data, arrivalTime);

    // Asynchronous auto-log (still synchronous in worker thread, but off GUI thread)
    if (m_autoLogEnabled)
        writeAutoLog(data, arrivalTime);

    // Accumulate for batched UI update
    QVariantMap record;
    record["raw"] = data;
    record["length"] = data.size();
    record["time"] = arrivalTimeMs;
    m_pendingBatch.append(record);
    m_pendingBatchBytes += data.size();

    if (m_pendingBatch.size() >= BatchRecordThreshold ||
        m_pendingBatchBytes >= BatchByteThreshold) {
        flushBatch();
    } else if (!m_batchTimer->isActive()) {
        m_batchTimer->start(BatchTimeoutMs);
    }

    emit bytesReceived(data.size());
}

void SerialWorker::writeRecord(const QByteArray &data, const QDateTime &arrivalTime)
{
    if (!m_recordFile || !m_recordFile->isOpen())
        return;

    if (m_recordPath.endsWith(".bin", Qt::CaseInsensitive)) {
        // Binary recording: write raw bytes. Flushing is deferred until the
        // recording is stopped to avoid killing throughput at high baud rates.
        m_recordFile->write(data);
    } else if (m_recordStream) {
        *m_recordStream << "[" << arrivalTime.toString("yyyy-MM-dd hh:mm:ss.zzz") << "] ";
        *m_recordStream << normalizeLogLine(formatLogData(data)) << "\n";
    }
}

void SerialWorker::writeAutoLog(const QByteArray &data, const QDateTime &arrivalTime)
{
    if (!m_autoLogFile || !m_autoLogFile->isOpen() || !m_autoLogStream)
        return;

    *m_autoLogStream << "[" << arrivalTime.toString("yyyy-MM-dd hh:mm:ss.zzz") << "] ";
    *m_autoLogStream << normalizeLogLine(formatLogData(data)) << "\n";
}

void SerialWorker::flushBatch()
{
    if (m_pendingBatch.isEmpty())
        return;

    m_batchTimer->stop();
    QVariantList batch;
    batch.swap(m_pendingBatch);
    m_pendingBatchBytes = 0;
    emit batchDataReady(batch);
}

void SerialWorker::handleError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError)
        return;

    qWarning() << "Serial error:" << error << m_serialPort->errorString();
    emit errorOccurred(m_serialPort->errorString());

    if (error == QSerialPort::ResourceError) {
        closePort();
    }
}

void SerialWorker::endWarmup()
{
    m_inWarmup = false;
    if (m_serialPort && m_serialPort->isOpen())
        m_serialPort->readAll();
}

