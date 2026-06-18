#ifndef RECEIVEMODEL_H
#define RECEIVEMODEL_H

#include <QAbstractListModel>
#include <QByteArray>
#include <QStringList>
#include <QDateTime>
#include <deque>

class ReceiveModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool showTimestamp READ showTimestamp WRITE setShowTimestamp NOTIFY showTimestampChanged)
    Q_PROPERTY(bool hexMode READ hexMode WRITE setHexMode NOTIFY hexModeChanged)
    Q_PROPERTY(int maxRecords READ maxRecords WRITE setMaxRecords NOTIFY maxRecordsChanged)
    Q_PROPERTY(int maxBufferMb READ maxBufferMb WRITE setMaxBufferMb NOTIFY maxBufferMbChanged)

public:
    enum Roles {
        DisplayRole = Qt::DisplayRole,
    };

    explicit ReceiveModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Properties
    bool showTimestamp() const;
    void setShowTimestamp(bool value);
    bool hexMode() const;
    void setHexMode(bool value);
    int maxRecords() const;
    void setMaxRecords(int value);
    int maxBufferMb() const;
    void setMaxBufferMb(int value);

    // Q_INVOKABLE — kept for QML compatibility
    Q_INVOKABLE void append(const QByteArray &rawData, int length);
    Q_INVOKABLE void appendBatch(const QVariantList &batch);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QString allText() const;
    Q_INVOKABLE QString lineAt(int row) const;
    Q_INVOKABLE int lineCount() const;

signals:
    void showTimestampChanged();
    void hexModeChanged();
    void maxRecordsChanged();
    void maxBufferMbChanged();
    void appended(int totalBytes);

private:
    struct Record {
        QByteArray raw;
        QDateTime timestamp;
        int lineCount = 0;
    };

    QStringList formatRecordLines(const QByteArray &rawData, const QDateTime &timestamp) const;
    QString formatRecordText(const QByteArray &rawData, const QDateTime &timestamp) const;
    void enforceBufferLimits();
    void regenerateAllLines();
    QString currentTimeString() const;
    static QString bytesToHexString(const QByteArray &bytes);
    static QString bytesToTextString(const QByteArray &bytes);

    std::deque<Record> m_records;
    QStringList m_lines;
    bool m_showTimestamp = false;
    bool m_hexMode = false;
    int m_maxRecords = 50000;
    int m_maxBufferMb = 32;
    qint64 m_totalBytes = 0;
};

#endif // RECEIVEMODEL_H
