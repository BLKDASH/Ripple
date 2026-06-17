#include "receivemodel.h"
#include <QTextCursor>
#include <QDateTime>
#include <QDebug>

ReceiveModel::ReceiveModel(QObject *parent)
    : QObject(parent)
{
}

bool ReceiveModel::showTimestamp() const
{
    return m_showTimestamp;
}

void ReceiveModel::setShowTimestamp(bool value)
{
    if (m_showTimestamp == value)
        return;
    m_showTimestamp = value;
    emit showTimestampChanged();
    rebuild();
}

bool ReceiveModel::hexMode() const
{
    return m_hexMode;
}

void ReceiveModel::setHexMode(bool value)
{
    if (m_hexMode == value)
        return;
    m_hexMode = value;
    emit hexModeChanged();
    rebuild();
}

int ReceiveModel::autoClearRecords() const
{
    return m_autoClearRecords;
}

void ReceiveModel::setAutoClearRecords(int value)
{
    if (value < 0) value = 0;
    if (m_autoClearRecords == value)
        return;
    m_autoClearRecords = value;
    emit autoClearRecordsChanged();
}

int ReceiveModel::autoClearBytes() const
{
    return m_autoClearBytes;
}

void ReceiveModel::setAutoClearBytes(int value)
{
    if (value < 0) value = 0;
    if (m_autoClearBytes == value)
        return;
    m_autoClearBytes = value;
    emit autoClearBytesChanged();
}

void ReceiveModel::setTextDocument(QQuickTextDocument *doc)
{
    m_quickDoc = doc;
    if (doc)
        m_doc = doc->textDocument();
}

void ReceiveModel::append(const QString &textData, const QString &hexData, int length)
{
    if (!m_doc)
        return;

    m_receivedBytes += length;

    QVariantMap record;
    record["time"] = currentTimeString();
    record["text"] = textData;
    record["hex"] = hexData;
    record["length"] = length;
    m_records.append(record);

    QString text = formatRecord(textData, hexData);
    if (text.isEmpty())
        return;

    QTextCursor cursor(m_doc);
    cursor.movePosition(QTextCursor::End);
    cursor.insertText(text);

    checkAutoClear();
    emit appended(length);
}

void ReceiveModel::appendBatch(const QVariantList &batch)
{
    if (!m_doc || batch.isEmpty())
        return;

    int totalLength = 0;
    QString textBlock;
    textBlock.reserve(batch.size() * 80);

    for (const QVariant &item : batch) {
        QVariantMap record = item.toMap();
        record["time"] = currentTimeString();
        m_records.append(record);

        QString text = formatRecord(record["text"].toString(), record["hex"].toString());
        if (!text.isEmpty())
            textBlock += text;

        totalLength += record["length"].toInt();
    }

    m_receivedBytes += totalLength;

    if (!textBlock.isEmpty()) {
        QTextCursor cursor(m_doc);
        cursor.movePosition(QTextCursor::End);
        cursor.insertText(textBlock);
    }

    checkAutoClear();
    emit appended(totalLength);
}

void ReceiveModel::clear()
{
    m_records.clear();
    m_receivedBytes = 0;
    if (m_doc)
        m_doc->clear();
}

QString ReceiveModel::toPlainText() const
{
    if (!m_doc)
        return QString();
    return m_doc->toPlainText();
}

void ReceiveModel::rebuild()
{
    if (!m_doc)
        return;

    m_doc->clear();
    for (const QVariantMap &record : m_records) {
        QString text = formatRecord(record["text"].toString(), record["hex"].toString());
        if (!text.isEmpty()) {
            QTextCursor cursor(m_doc);
            cursor.movePosition(QTextCursor::End);
            cursor.insertText(text);
        }
    }
}

QString ReceiveModel::formatRecord(const QString &textData, const QString &hexData) const
{
    QString content = m_hexMode ? hexData : textData;
    if (content.isEmpty())
        return QString();

    QString prefix;
    if (m_showTimestamp)
        prefix = "[" + currentTimeString() + "] ";

    QString suffix = "\n";
    if (!m_hexMode) {
        if (content.endsWith("\r\n") || content.endsWith("\n") || content.endsWith("\r"))
            suffix = QString();
    }

    return prefix + content + suffix;
}

void ReceiveModel::checkAutoClear()
{
    bool clearByRecords = (m_autoClearRecords > 0 && m_records.size() >= m_autoClearRecords);
    bool clearByBytes = (m_autoClearBytes > 0 && m_receivedBytes >= (qint64)m_autoClearBytes * 1024 * 1024);

    if (clearByRecords || clearByBytes) {
        clear();
    }
}

QString ReceiveModel::currentTimeString() const
{
    return QDateTime::currentDateTime().toString("hh:mm:ss.zzz");
}
