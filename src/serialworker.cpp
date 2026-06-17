#include "serialworker.h"
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

SerialWorker::SerialWorker(QObject *parent)
    : QObject(parent)
{
}

SerialWorker::~SerialWorker()
{
    stopRecording();
    setAutoLog(QString(), false);
    if (m_serialPort && m_serialPort->isOpen())
        m_serialPort->close();
    delete m_serialPort;
    delete m_warmupTimer;
    delete m_batchTimer;
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
        emit errorOccurred(m_serialPort->errorString());
        emit isOpenChanged(false);
        return;
    }

    // Discard any stale/noise data that may be present right after opening.
    m_serialPort->clear(QSerialPort::Input);
    m_serialPort->readAll();

    // Ignore incoming data for a short warmup period to let the line stabilize.
    m_inWarmup = true;
    m_warmupTimer->start(150);

    emit isOpenChanged(true);
}

void SerialWorker::closePort()
{
    if (!m_serialPort || !m_serialPort->isOpen())
        return;

    m_serialPort->close();
    emit isOpenChanged(false);
}

void SerialWorker::sendData(const QByteArray &data)
{
    if (!m_serialPort || !m_serialPort->isOpen()) {
        emit errorOccurred(tr("Serial port is not open"));
        return;
    }

    qint64 written = m_serialPort->write(data);
    if (written == -1) {
        emit errorOccurred(m_serialPort->errorString());
        return;
    }
    m_serialPort->flush();
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
        emit errorOccurred(tr("Failed to open recording file: %1").arg(filePath));
        delete m_recordFile;
        m_recordFile = nullptr;
        return;
    }

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
        emit recordingChanged(false);
    }
}

void SerialWorker::setAutoLog(const QString &filePath, bool enabled)
{
    // Close existing auto-log file
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

    m_autoLogEnabled = enabled;
    m_autoLogPath = filePath;

    if (enabled && !filePath.isEmpty()) {
        m_autoLogFile = new QFile(filePath, this);
        if (m_autoLogFile->open(QIODevice::Append | QIODevice::Text)) {
            m_autoLogStream = new QTextStream(m_autoLogFile);
        } else {
            emit errorOccurred(tr("Failed to open auto-log file: %1").arg(filePath));
            delete m_autoLogFile;
            m_autoLogFile = nullptr;
            m_autoLogEnabled = false;
        }
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

    QString textData = QString::fromUtf8(data);
    QString hexData = bytesToHexString(data);

    // Synchronous file append for recording
    if (m_recordingEnabled)
        writeRecord(data, textData);

    // Asynchronous auto-log (still synchronous in worker thread, but off GUI thread)
    if (m_autoLogEnabled)
        writeAutoLog(data, textData);

    // Accumulate for batched UI update
    QVariantMap record;
    record["text"] = textData;
    record["hex"] = hexData;
    record["length"] = data.size();
    m_pendingBatch.append(record);

    if (m_pendingBatch.size() >= BatchSizeThreshold) {
        flushBatch();
    } else if (!m_batchTimer->isActive()) {
        m_batchTimer->start(BatchTimeoutMs);
    }

    emit bytesReceived(data.size());
}

void SerialWorker::writeRecord(const QByteArray &data, const QString &textData)
{
    if (!m_recordFile || !m_recordFile->isOpen())
        return;

    if (m_recordPath.endsWith(".bin", Qt::CaseInsensitive)) {
        m_recordFile->write(data);
        m_recordFile->flush();
    } else if (m_recordStream) {
        *m_recordStream << "[" << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz") << "] ";
        *m_recordStream << normalizeLogLine(textData) << "\n";
        m_recordStream->flush();
    }
}

void SerialWorker::writeAutoLog(const QByteArray &data, const QString &textData)
{
    Q_UNUSED(data)
    if (!m_autoLogFile || !m_autoLogFile->isOpen() || !m_autoLogStream)
        return;

    *m_autoLogStream << "[" << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz") << "] ";
    *m_autoLogStream << normalizeLogLine(textData) << "\n";
    m_autoLogStream->flush();
}

void SerialWorker::flushBatch()
{
    if (m_pendingBatch.isEmpty())
        return;

    m_batchTimer->stop();
    QVariantList batch;
    batch.swap(m_pendingBatch);
    emit batchDataReady(batch);
}

void SerialWorker::handleError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError)
        return;

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

QString SerialWorker::bytesToHexString(const QByteArray &bytes)
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
