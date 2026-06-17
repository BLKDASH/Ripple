#ifndef SERIALPORTMANAGER_H
#define SERIALPORTMANAGER_H

#include <QObject>
#include <QSerialPortInfo>
#include <QVariantList>
#include <QThread>
#include "serialworker.h"

class SerialPortManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isOpen READ isOpen NOTIFY isOpenChanged)
    Q_PROPERTY(QString portName READ portName WRITE setPortName NOTIFY portNameChanged)
    Q_PROPERTY(int baudRate READ baudRate WRITE setBaudRate NOTIFY baudRateChanged)
    Q_PROPERTY(int dataBits READ dataBits WRITE setDataBits NOTIFY dataBitsChanged)
    Q_PROPERTY(int stopBits READ stopBits WRITE setStopBits NOTIFY stopBitsChanged)
    Q_PROPERTY(int parity READ parity WRITE setParity NOTIFY parityChanged)
    Q_PROPERTY(int flowControl READ flowControl WRITE setFlowControl NOTIFY flowControlChanged)
    Q_PROPERTY(bool autoLogEnabled READ autoLogEnabled WRITE setAutoLogEnabled NOTIFY autoLogEnabledChanged)
    Q_PROPERTY(QString autoLogPath READ autoLogPath WRITE setAutoLogPath NOTIFY autoLogPathChanged)
    Q_PROPERTY(bool recordingEnabled READ recordingEnabled WRITE setRecordingEnabled NOTIFY recordingEnabledChanged)
    Q_PROPERTY(QString recordingPath READ recordingPath WRITE setRecordingPath NOTIFY recordingPathChanged)

public:
    explicit SerialPortManager(QObject *parent = nullptr);
    ~SerialPortManager();

    bool isOpen() const;
    QString portName() const;
    int baudRate() const;
    int dataBits() const;
    int stopBits() const;
    int parity() const;
    int flowControl() const;
    bool autoLogEnabled() const;
    QString autoLogPath() const;
    bool recordingEnabled() const;
    QString recordingPath() const;

    void setPortName(const QString &name);
    void setBaudRate(int rate);
    void setDataBits(int bits);
    void setStopBits(int bits);
    void setParity(int parity);
    void setFlowControl(int flow);
    void setAutoLogEnabled(bool enabled);
    void setAutoLogPath(const QString &path);
    void setRecordingEnabled(bool enabled);
    void setRecordingPath(const QString &path);

    Q_INVOKABLE QVariantList availablePorts() const;
    Q_INVOKABLE bool openPort();
    Q_INVOKABLE void closePort();
    Q_INVOKABLE bool sendText(const QString &text);
    Q_INVOKABLE bool sendHex(const QString &hexString);
    Q_INVOKABLE void startRecording(const QString &filePath);
    Q_INVOKABLE void stopRecording();
    Q_INVOKABLE static QByteArray hexStringToBytes(const QString &hexString);
    Q_INVOKABLE static QString bytesToHexString(const QByteArray &bytes);
    Q_INVOKABLE QString readFile(const QString &filePath);
    Q_INVOKABLE QString readFileAsHex(const QString &filePath);
    Q_INVOKABLE bool saveReceiveBuffer(const QString &filePath);

signals:
    void isOpenChanged();
    void portNameChanged();
    void baudRateChanged();
    void dataBitsChanged();
    void stopBitsChanged();
    void parityChanged();
    void flowControlChanged();
    void autoLogEnabledChanged();
    void autoLogPathChanged();
    void recordingEnabledChanged();
    void recordingPathChanged();
    void bytesSent(qint64 count);
    void bytesReceived(qint64 count);
    void errorOccurred(const QString &errorString);
    void batchDataReady(const QVariantList &batch);

private:
    void syncAutoLogToWorker();
    void syncRecordingToWorker();

    QThread *m_workerThread = nullptr;
    SerialWorker *m_worker = nullptr;

    bool m_isOpen = false;
    QString m_portName;
    int m_baudRate = 115200;
    int m_dataBits = static_cast<int>(QSerialPort::Data8);
    int m_stopBits = static_cast<int>(QSerialPort::OneStop);
    int m_parity = static_cast<int>(QSerialPort::NoParity);
    int m_flowControl = static_cast<int>(QSerialPort::NoFlowControl);

    bool m_autoLogEnabled = false;
    QString m_autoLogPath;
    bool m_recordingEnabled = false;
    QString m_recordingPath;
};

#endif // SERIALPORTMANAGER_H
