#ifndef SERIALWORKER_H
#define SERIALWORKER_H

#include <QObject>
#include <QSerialPort>
#include <QTimer>
#include <QFile>
#include <QTextStream>
#include <QVariantList>
#include <QVariantMap>

class SerialWorker : public QObject
{
    Q_OBJECT
public:
    explicit SerialWorker(QObject *parent = nullptr);
    ~SerialWorker();

public slots:
    void init();
    void openPort(const QString &name, int baudRate, int dataBits, int stopBits, int parity, int flowControl);
    void closePort();
    void sendData(const QByteArray &data);
    void startRecording(const QString &filePath);
    void stopRecording();
    void setAutoLog(const QString &filePath, bool enabled);

signals:
    void batchDataReady(const QVariantList &batch);
    void bytesSent(qint64 count);
    void bytesReceived(qint64 count);
    void errorOccurred(const QString &errorString);
    void isOpenChanged(bool open);
    void recordingChanged(bool recording);

private slots:
    void readData();
    void handleError(QSerialPort::SerialPortError error);
    void endWarmup();
    void flushBatch();

private:
    void writeRecord(const QByteArray &data, const QString &textData);
    void writeAutoLog(const QByteArray &data, const QString &textData);
    static QString bytesToHexString(const QByteArray &bytes);

    QSerialPort *m_serialPort = nullptr;
    QTimer *m_warmupTimer = nullptr;
    QTimer *m_batchTimer = nullptr;
    bool m_inWarmup = false;

    // Recording
    QFile *m_recordFile = nullptr;
    QTextStream *m_recordStream = nullptr;
    QString m_recordPath;
    bool m_recordingEnabled = false;

    // Auto log
    QFile *m_autoLogFile = nullptr;
    QTextStream *m_autoLogStream = nullptr;
    QString m_autoLogPath;
    bool m_autoLogEnabled = false;

    // Batch buffering for UI updates
    QVariantList m_pendingBatch;
    static constexpr int BatchSizeThreshold = 50;
    static constexpr int BatchTimeoutMs = 10;
};

#endif // SERIALWORKER_H
