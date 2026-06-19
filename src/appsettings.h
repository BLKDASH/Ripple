#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QTimer>

class AppSettings : public QObject
{
    Q_OBJECT

    // Serial configuration
    Q_PROPERTY(QString portName READ portName WRITE setPortName NOTIFY portNameChanged)
    Q_PROPERTY(int baudRate READ baudRate WRITE setBaudRate NOTIFY baudRateChanged)
    Q_PROPERTY(int dataBits READ dataBits WRITE setDataBits NOTIFY dataBitsChanged)
    Q_PROPERTY(int stopBits READ stopBits WRITE setStopBits NOTIFY stopBitsChanged)
    Q_PROPERTY(int parity READ parity WRITE setParity NOTIFY parityChanged)
    Q_PROPERTY(int flowControl READ flowControl WRITE setFlowControl NOTIFY flowControlChanged)

    // UI / application
    Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(bool showQuickSend READ showQuickSend WRITE setShowQuickSend NOTIFY showQuickSendChanged)
    Q_PROPERTY(bool autoLogEnabled READ autoLogEnabled WRITE setAutoLogEnabled NOTIFY autoLogEnabledChanged)
    Q_PROPERTY(QString autoLogFolder READ autoLogFolder WRITE setAutoLogFolder NOTIFY autoLogFolderChanged)
    Q_PROPERTY(int windowWidth READ windowWidth WRITE setWindowWidth NOTIFY windowWidthChanged)
    Q_PROPERTY(int windowHeight READ windowHeight WRITE setWindowHeight NOTIFY windowHeightChanged)

    // Send pane
    Q_PROPERTY(bool sendHexMode READ sendHexMode WRITE setSendHexMode NOTIFY sendHexModeChanged)
    Q_PROPERTY(bool sendAppendCr READ sendAppendCr WRITE setSendAppendCr NOTIFY sendAppendCrChanged)
    Q_PROPERTY(bool sendAppendLf READ sendAppendLf WRITE setSendAppendLf NOTIFY sendAppendLfChanged)
    Q_PROPERTY(bool sendCyclicSend READ sendCyclicSend WRITE setSendCyclicSend NOTIFY sendCyclicSendChanged)
    Q_PROPERTY(int sendCyclicInterval READ sendCyclicInterval WRITE setSendCyclicInterval NOTIFY sendCyclicIntervalChanged)

    // Quick send grid
    Q_PROPERTY(QString quickSendJson READ quickSendJson WRITE setQuickSendJson NOTIFY quickSendJsonChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);
    ~AppSettings() override;

    /// On first launch (no persisted value), detect system language & theme.
    void ensureDefaults();

    QString configPath() const;
    Q_INVOKABLE void sync();

    // Serial
    QString portName() const;
    void setPortName(const QString &value);

    int baudRate() const;
    void setBaudRate(int value);

    int dataBits() const;
    void setDataBits(int value);

    int stopBits() const;
    void setStopBits(int value);

    int parity() const;
    void setParity(int value);

    int flowControl() const;
    void setFlowControl(int value);

    // UI
    bool darkTheme() const;
    void setDarkTheme(bool value);

    QString language() const;
    void setLanguage(const QString &value);

    bool showQuickSend() const;
    void setShowQuickSend(bool value);

    bool autoLogEnabled() const;
    void setAutoLogEnabled(bool value);

    QString autoLogFolder() const;
    void setAutoLogFolder(const QString &value);

    int windowWidth() const;
    void setWindowWidth(int value);

    int windowHeight() const;
    void setWindowHeight(int value);

    // Send
    bool sendHexMode() const;
    void setSendHexMode(bool value);

    bool sendAppendCr() const;
    void setSendAppendCr(bool value);

    bool sendAppendLf() const;
    void setSendAppendLf(bool value);

    bool sendCyclicSend() const;
    void setSendCyclicSend(bool value);

    int sendCyclicInterval() const;
    void setSendCyclicInterval(int value);

    // Quick send
    QString quickSendJson() const;
    void setQuickSendJson(const QString &value);

signals:
    void portNameChanged();
    void baudRateChanged();
    void dataBitsChanged();
    void stopBitsChanged();
    void parityChanged();
    void flowControlChanged();

    void darkThemeChanged();
    void languageChanged();
    void showQuickSendChanged();
    void autoLogEnabledChanged();
    void autoLogFolderChanged();
    void windowWidthChanged();
    void windowHeightChanged();

    void sendHexModeChanged();
    void sendAppendCrChanged();
    void sendAppendLfChanged();
    void sendCyclicSendChanged();
    void sendCyclicIntervalChanged();

    void quickSendJsonChanged();

private:
    void setValue(const QString &group, const QString &key, const QVariant &value);

    QSettings *m_settings = nullptr;
    QTimer *m_syncTimer = nullptr;
};

#endif // APPSETTINGS_H
