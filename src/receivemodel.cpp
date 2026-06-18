#include "receivemodel.h"
#include <QDateTime>
#include <QDebug>

ReceiveModel::ReceiveModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ReceiveModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return static_cast<int>(m_lines.size());
}

QVariant ReceiveModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_lines.size())
        return {};

    if (role == Qt::DisplayRole)
        return m_lines.at(index.row());

    return {};
}

QHash<int, QByteArray> ReceiveModel::roleNames() const
{
    return {{Qt::DisplayRole, "display"}};
}

// ── Properties ──────────────────────────────────────────────

bool ReceiveModel::showTimestamp() const { return m_showTimestamp; }
void ReceiveModel::setShowTimestamp(bool value)
{
    if (m_showTimestamp == value) return;
    m_showTimestamp = value;
    qInfo() << "ReceiveModel showTimestamp changed:" << value;
    emit showTimestampChanged();
    regenerateAllLines();
}

bool ReceiveModel::hexMode() const { return m_hexMode; }
void ReceiveModel::setHexMode(bool value)
{
    if (m_hexMode == value) return;
    m_hexMode = value;
    qInfo() << "ReceiveModel hexMode changed:" << value;
    emit hexModeChanged();
    regenerateAllLines();
}

int ReceiveModel::maxRecords() const { return m_maxRecords; }
void ReceiveModel::setMaxRecords(int value)
{
    if (value < 100) value = 100;
    if (m_maxRecords == value) return;
    m_maxRecords = value;
    emit maxRecordsChanged();
    enforceBufferLimits();
}

int ReceiveModel::maxBufferMb() const { return m_maxBufferMb; }
void ReceiveModel::setMaxBufferMb(int value)
{
    if (value < 1) value = 1;
    if (m_maxBufferMb == value) return;
    m_maxBufferMb = value;
    emit maxBufferMbChanged();
    enforceBufferLimits();
}

// ── Data ingestion ──────────────────────────────────────────

void ReceiveModel::append(const QByteArray &rawData, int length)
{
    QVariantList batch;
    QVariantMap record;
    record["raw"] = rawData;
    record["length"] = length > 0 ? length : rawData.size();
    record["time"] = QDateTime::currentDateTime().toMSecsSinceEpoch();
    batch.append(record);
    appendBatch(batch);
}

void ReceiveModel::appendBatch(const QVariantList &batch)
{
    if (batch.isEmpty())
        return;

    int totalLength = 0;
    int newRowCount = 0;

    struct PendingRecord {
        QByteArray raw;
        QDateTime timestamp;
        QStringList lines;
        int lineCount = 0;
    };
    QVector<PendingRecord> pending;
    pending.reserve(batch.size());

    // First pass: parse and measure everything without touching the model.
    for (const QVariant &item : batch) {
        QVariantMap record = item.toMap();
        QByteArray rawData = record.value("raw").toByteArray();
        qint64 timestampMs = record.value("time").toLongLong();
        QDateTime timestamp = timestampMs > 0
            ? QDateTime::fromMSecsSinceEpoch(timestampMs)
            : QDateTime::currentDateTime();
        int length = rawData.size();
        if (length <= 0)
            length = record.value("length").toInt();
        if (length <= 0)
            continue;

        totalLength += length;
        m_totalBytes += length;

        QStringList lines = formatRecordLines(rawData, timestamp);
        if (lines.isEmpty())
            continue;

        int lineCount = static_cast<int>(lines.size());
        pending.append({rawData, timestamp, lines, lineCount});
        newRowCount += lineCount;
    }

    if (newRowCount > 0) {
        // Modify the containers only while the insert notification is active,
        // so rowCount() and data() stay consistent with the model's public state.
        int firstNewRow = static_cast<int>(m_lines.size());
        beginInsertRows(QModelIndex(), firstNewRow, firstNewRow + newRowCount - 1);
        for (const auto &p : pending) {
            m_lines.append(p.lines);
            m_records.push_back({p.raw, p.timestamp, p.lineCount});
        }
        endInsertRows();
    }

    // Trim oldest records if buffer limits are exceeded. This is done after the
    // insert so that beginInsertRows / beginRemoveRows are never nested, and so
    // the insert indices are always valid even when rows are removed from the
    // front.
    enforceBufferLimits();

    emit appended(totalLength);
}

void ReceiveModel::clear()
{
    if (m_lines.isEmpty())
        return;

    qInfo() << "ReceiveModel cleared, lines=" << m_lines.size();
    beginRemoveRows(QModelIndex(), 0, static_cast<int>(m_lines.size()) - 1);
    m_lines.clear();
    m_records.clear();
    m_totalBytes = 0;
    endRemoveRows();
}

QString ReceiveModel::allText() const
{
    return m_lines.join('\n');
}

QString ReceiveModel::lineAt(int row) const
{
    if (row < 0 || row >= m_lines.size())
        return {};
    return m_lines.at(row);
}

int ReceiveModel::lineCount() const
{
    return static_cast<int>(m_lines.size());
}

// ── Buffer enforcement ──────────────────────────────────────

void ReceiveModel::enforceBufferLimits()
{
    if (m_maxRecords <= 0 && m_maxBufferMb <= 0)
        return;

    qint64 maxBytes = static_cast<qint64>(m_maxBufferMb) * 1024 * 1024;
    int recordCount = static_cast<int>(m_records.size());

    // Decide how many records to trim.  Remove down to ~75 % of the limit
    // so we batch deletions instead of trimming one record per append.
    int targetRecords = m_maxRecords;
    if (m_maxRecords > 0 && recordCount > m_maxRecords)
        targetRecords = qMax(100, m_maxRecords - m_maxRecords / 4);

    qint64 targetBytes = maxBytes;
    if (m_maxBufferMb > 0 && m_totalBytes > maxBytes)
        targetBytes = qMax(qint64(1024 * 1024), maxBytes - maxBytes / 4);

    // Count how many records (and their display lines) to remove.
    int removeRecs = 0;
    int removeLines = 0;
    for (auto it = m_records.begin(); it != m_records.end(); ++it) {
        bool overRecords = (m_maxRecords > 0
                            && recordCount - removeRecs > targetRecords);
        bool overBytes   = (m_maxBufferMb > 0
                            && m_totalBytes   > targetBytes);
        if (!overRecords && !overBytes)
            break;
        m_totalBytes -= it->raw.size();
        removeLines  += it->lineCount;
        removeRecs++;
    }

    if (removeRecs <= 0)
        return;

    qInfo() << "ReceiveModel trimming buffer: records=" << removeRecs
            << "lines=" << removeLines
            << "remainingRecords=" << (recordCount - removeRecs)
            << "remainingBytes=" << m_totalBytes;

    // Remove from the model in one batch.
    beginRemoveRows(QModelIndex(), 0, removeLines - 1);
    m_lines.erase(m_lines.begin(), m_lines.begin() + removeLines);
    m_records.erase(m_records.begin(), m_records.begin() + removeRecs);
    endRemoveRows();
}

// ── Rebuild on mode switch ──────────────────────────────────

void ReceiveModel::regenerateAllLines()
{
    if (m_records.empty())
        return;

    QStringList newLines;
    newLines.reserve(static_cast<int>(m_lines.size())); // rough estimate

    for (const Record &rec : m_records) {
        QStringList lines = formatRecordLines(rec.raw, rec.timestamp);
        if (!lines.isEmpty())
            newLines.append(lines);
    }

    // Replace atomically through the model API
    beginResetModel();
    m_lines = std::move(newLines);
    endResetModel();
}

// ── Formatting helpers ──────────────────────────────────────

QStringList ReceiveModel::formatRecordLines(const QByteArray &rawData, const QDateTime &timestamp) const
{
    QString text = formatRecordText(rawData, timestamp);
    if (text.isEmpty())
        return {};

    // Split into individual display lines. Preserve empty lines in the middle
    // (e.g. \n\n) but drop only trailing empties caused by a trailing newline.
    QStringList lines = text.split('\n');
    while (!lines.isEmpty() && lines.last().isEmpty())
        lines.removeLast();
    return lines;
}

QString ReceiveModel::formatRecordText(const QByteArray &rawData, const QDateTime &timestamp) const
{
    if (rawData.isEmpty())
        return {};

    QString content = m_hexMode ? bytesToHexString(rawData)
                                : bytesToTextString(rawData);
    if (content.isEmpty())
        return {};

    QString prefix;
    if (m_showTimestamp) {
        prefix = QStringLiteral("[%1] ").arg(timestamp.isValid()
            ? timestamp.toString(QStringLiteral("hh:mm:ss.zzz"))
            : currentTimeString());
    }

    QString suffix;
    // In hex mode every formatted line already ends with \n.
    // In text mode append \n only if the content doesn't already end with one.
    if (!m_hexMode) {
        if (!content.endsWith('\n') && !content.endsWith('\r'))
            suffix = QStringLiteral("\n");
    }

    return prefix + content + suffix;
}

QString ReceiveModel::currentTimeString() const
{
    return QDateTime::currentDateTime().toString(QStringLiteral("hh:mm:ss.zzz"));
}

QString ReceiveModel::bytesToHexString(const QByteArray &bytes)
{
    if (bytes.isEmpty())
        return {};

    static const char hexDigits[] = "0123456789abcdef";
    QString result;
    result.reserve(bytes.size() * 3 + bytes.size() / 16 + 1);

    for (int i = 0; i < bytes.size(); ++i) {
        uchar uc = static_cast<uchar>(bytes.at(i));
        result.append(hexDigits[uc >> 4]);
        result.append(hexDigits[uc & 0x0F]);
        result.append(' ');
        if ((i + 1) % 16 == 0)
            result.append('\n');
    }
    if (!result.endsWith('\n'))
        result.append('\n');
    return result;
}

QString ReceiveModel::bytesToTextString(const QByteArray &bytes)
{
    return QString::fromUtf8(bytes);
}
