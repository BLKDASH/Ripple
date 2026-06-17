#ifndef TRANSLATOR_H
#define TRANSLATOR_H

#include <QObject>
#include <QTranslator>
#include <QQmlEngine>
#include <QCoreApplication>

class Translator : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentLanguage READ currentLanguage WRITE setCurrentLanguage NOTIFY currentLanguageChanged)

public:
    explicit Translator(QQmlEngine *engine, QObject *parent = nullptr);

    QString currentLanguage() const;
    Q_INVOKABLE void setCurrentLanguage(const QString &language);
    Q_INVOKABLE static QStringList availableLanguages();

signals:
    void currentLanguageChanged();

private:
    QQmlEngine *m_engine = nullptr;
    QTranslator *m_translator = nullptr;
    QString m_currentLanguage = "en";
    QString m_translationPrefix;
};

#endif // TRANSLATOR_H
