#ifndef SERIALWORKER_H
#define SERIALWORKER_H

#include <QObject>
#include <QSerialPort>
#include <QTimer>
#include <QDateTime>
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
    void quit();
    void openPort(const QString &name, int baudRate, int dataBits, int stopBits, int parity, int flowControl);
    void closePort();
    void sendData(const QByteArray &data);
    void startRecording(const QString &filePath);
    void stopRecording();
    void setAutoLogFolder(const QString &folder, bool enabled);

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
    void writeRecord(const QByteArray &data, const QDateTime &arrivalTime);
    void writeAutoLog(const QByteArray &data, const QDateTime &arrivalTime);
    void openAutoLogFile();
    void closeAutoLogFile();

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
    QString m_autoLogFolder;
    bool m_autoLogEnabled = false;

    // Batch buffering for UI updates
    QVariantList m_pendingBatch;
    qint64 m_pendingBatchBytes = 0;
    static constexpr int BatchRecordThreshold = 200;
    static constexpr int BatchByteThreshold = 4096;
    static constexpr int BatchTimeoutMs = 50;
};

#endif // SERIALWORKER_H
