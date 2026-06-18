#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QFile>
#include <QTextStream>
#include <QMutex>

class Logger : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString logPath READ logPath CONSTANT)

public:
    explicit Logger(QObject *parent = nullptr);
    ~Logger();

    static Logger *instance();

    QString logPath() const;

    Q_INVOKABLE void debug(const QString &message);
    Q_INVOKABLE void info(const QString &message);
    Q_INVOKABLE void warning(const QString &message);
    Q_INVOKABLE void error(const QString &message);

    static void messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg);

private:
    void rotateLogIfNeeded();
    void write(QtMsgType type, const QString &message);

    mutable QMutex m_mutex;
    QFile m_file;
    QTextStream m_stream;
    bool m_open = false;
    QString m_logPath;

    static Logger *s_instance;
};

#endif // LOGGER_H
