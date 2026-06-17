#include "translator.h"
#include <QDir>
#include <QLocale>
#include <QDebug>

Translator::Translator(QQmlEngine *engine, QObject *parent)
    : QObject(parent)
    , m_engine(engine)
    , m_translator(new QTranslator(this))
{
    m_translationPrefix = "CWY_";
}

QString Translator::currentLanguage() const
{
    return m_currentLanguage;
}

void Translator::setCurrentLanguage(const QString &language)
{
    if (m_currentLanguage == language)
        return;

    if (m_translator) {
        QCoreApplication::removeTranslator(m_translator);
        delete m_translator;
        m_translator = new QTranslator(this);
    }

    if (language != "en") {
        QString fileName = m_translationPrefix + language;
        bool loaded = false;

        // First try executable directory
        QString appDir = QCoreApplication::applicationDirPath();
        loaded = m_translator->load(fileName, appDir + "/translations");
        if (!loaded)
            loaded = m_translator->load(fileName, appDir);

        if (loaded) {
            QCoreApplication::installTranslator(m_translator);
        } else {
            qWarning() << "Failed to load translation:" << fileName;
            delete m_translator;
            m_translator = nullptr;
        }
    }

    m_currentLanguage = language;
    emit currentLanguageChanged();

    if (m_engine)
        m_engine->retranslate();
}

QStringList Translator::availableLanguages()
{
    return QStringList{ "en", "zh_CN" };
}
