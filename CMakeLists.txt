cmake_minimum_required(VERSION 3.16)

project(Ripple VERSION 1.0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)

find_package(Qt6 REQUIRED COMPONENTS Quick SerialPort QuickControls2 LinguistTools)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appRipple
    main.cpp
    icon/app.rc
    src/appsettings.h
    src/appsettings.cpp
    src/serialportmanager.h
    src/serialportmanager.cpp
    src/serialworker.h
    src/serialworker.cpp
    src/translator.h
    src/translator.cpp
    src/receivemodel.h
    src/receivemodel.cpp
    src/logger.h
    src/logger.cpp
)

set_source_files_properties(icon/ripple-icon.svg
    PROPERTIES QT_RESOURCE_ALIAS "ripple-icon.svg")

qt_add_qml_module(appRipple
    URI Ripple
    RESOURCES
        icon/ripple-icon.svg
    QML_FILES
        qml/Main.qml
        qml/MainPanel.qml
        qml/components/NotifyOverlay.qml
        qml/serial/SerialPortPanel.qml
        qml/serial/ParamCombo.qml
        qml/receive/ReceivePane.qml
        qml/send/SendPane.qml
        qml/send/QuickSendGrid.qml
        qml/send/QuickSendEditDialog.qml
        qml/dialogs/SettingsDialog.qml
        qml/dialogs/HelpDialog.qml
        qml/components/CustomScrollBar.qml
        qml/components/FluentComboBox.qml
        qml/components/StatusBar.qml
        qml/singleton/Theme.qml
        qml/singleton/NotificationManager.qml
)

set_source_files_properties(
    qml/singleton/Theme.qml
    qml/singleton/NotificationManager.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_translations(appRipple
    TS_FILES translations/Ripple_zh_CN.ts
    QM_FILES_OUTPUT_VARIABLE QM_FILES
)

# Deploy the generated .qm files next to the executable so the Translator
# singleton can load them from applicationDirPath()/translations.
install(FILES ${QM_FILES}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/translations
)

# Copy help HTML files next to the executable for runtime loading.
add_custom_command(TARGET appRipple POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/help $<TARGET_FILE_DIR:appRipple>/help
    COMMENT "Copying help files to build directory"
)
install(DIRECTORY ${CMAKE_SOURCE_DIR}/help/
    DESTINATION ${CMAKE_INSTALL_BINDIR}/help
)

# Generate the Inno Setup deployment script from template so the version number
# only has to be updated in project() above.
configure_file(
    ${CMAKE_SOURCE_DIR}/Installer/deploy.bat.in
    ${CMAKE_SOURCE_DIR}/Installer/deploy.bat
    @ONLY)
configure_file(
    ${CMAKE_SOURCE_DIR}/Installer/innoSetup.iss.in
    ${CMAKE_SOURCE_DIR}/Installer/innoSetup.iss
    @ONLY)

set_target_properties(appRipple PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appRipple
    PRIVATE Qt6::Quick Qt6::SerialPort Qt6::QuickControls2
)

install(TARGETS appRipple
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Generate a deployment script for the QML application and include it at install time
qt_generate_deploy_qml_app_script(
    TARGET appRipple
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${deploy_script})
