#include "translator.h"
#include <QDir>
#include <QLocale>
#include <QDebug>
#include <QFile>

Translator::Translator(QQmlEngine *engine, QObject *parent)
    : QObject(parent)
    , m_engine(engine)
    , m_translator(new QTranslator(this))
{
    m_translationPrefix = "Ripple_";
}

QString Translator::currentLanguage() const
{
    return m_currentLanguage;
}

void Translator::setCurrentLanguage(const QString &language)
{
    if (m_currentLanguage == language)
        return;

    // 确保始终有一个可用的 QTranslator 实例
    if (m_translator) {
        QCoreApplication::removeTranslator(m_translator);
        delete m_translator;
    }
    m_translator = new QTranslator(this);

    if (language != "en") {
        QString fileName = m_translationPrefix + language;
        bool loaded = false;

        // 1. 优先从资源文件加载（打包后可用）
        loaded = m_translator->load(":/i18n/" + fileName + ".qm");

        // 2. 尝试可执行文件目录下的 translations/ 子目录
        if (!loaded) {
            QString appDir = QCoreApplication::applicationDirPath();
            loaded = m_translator->load(fileName, appDir + "/translations");
        }

        // 3. 尝试可执行文件目录
        if (!loaded) {
            QString appDir = QCoreApplication::applicationDirPath();
            loaded = m_translator->load(fileName, appDir);
        }

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
