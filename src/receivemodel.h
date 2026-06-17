#ifndef RECEIVEMODEL_H
#define RECEIVEMODEL_H

#include <QObject>
#include <QTextDocument>
#include <QQuickTextDocument>

class ReceiveModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool showTimestamp READ showTimestamp WRITE setShowTimestamp NOTIFY showTimestampChanged)
    Q_PROPERTY(bool hexMode READ hexMode WRITE setHexMode NOTIFY hexModeChanged)
    Q_PROPERTY(int autoClearRecords READ autoClearRecords WRITE setAutoClearRecords NOTIFY autoClearRecordsChanged)
    Q_PROPERTY(int autoClearBytes READ autoClearBytes WRITE setAutoClearBytes NOTIFY autoClearBytesChanged)

public:
    explicit ReceiveModel(QObject *parent = nullptr);

    bool showTimestamp() const;
    void setShowTimestamp(bool value);

    bool hexMode() const;
    void setHexMode(bool value);

    int autoClearRecords() const;
    void setAutoClearRecords(int value);

    int autoClearBytes() const;
    void setAutoClearBytes(int value);

    Q_INVOKABLE void setTextDocument(QQuickTextDocument *doc);
    Q_INVOKABLE void append(const QString &textData, const QString &hexData, int length);
    Q_INVOKABLE void appendBatch(const QVariantList &batch);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QString toPlainText() const;
    Q_INVOKABLE void rebuild();

signals:
    void showTimestampChanged();
    void hexModeChanged();
    void autoClearRecordsChanged();
    void autoClearBytesChanged();
    void appended(int length);

private:
    QString formatRecord(const QString &textData, const QString &hexData) const;
    void checkAutoClear();
    QString currentTimeString() const;

    QQuickTextDocument *m_quickDoc = nullptr;
    QTextDocument *m_doc = nullptr;
    bool m_showTimestamp = false;
    bool m_hexMode = false;
    int m_autoClearRecords = 0;
    int m_autoClearBytes = 0;
    qint64 m_receivedBytes = 0;

    // Keep a raw buffer so we can rebuild the view without re-receiving data.
    QList<QVariantMap> m_records;
};

#endif // RECEIVEMODEL_H
