cmake_minimum_required(VERSION 3.16)

project(CWY VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)

find_package(Qt6 REQUIRED COMPONENTS Quick SerialPort QuickControls2 LinguistTools)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appCWY
    main.cpp
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

qt_add_qml_module(appCWY
    URI CWY
    QML_FILES
        Main.qml
        NotifyOverlay.qml
        SerialPortPanel.qml
        ParamCombo.qml
        ReceivePane.qml
        SendPane.qml
        QuickSendGrid.qml
        QuickSendEditDialog.qml
        StatusBar.qml
        SettingsDialog.qml
        FluentComboBox.qml
        CustomScrollBar.qml
        MainPanel.qml
        HelpDialog.qml
        Theme.qml
        NotificationManager.qml
)

set_source_files_properties(Theme.qml NotificationManager.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_translations(appCWY
    TS_FILES translations/CWY_zh_CN.ts
    QM_FILES_OUTPUT_VARIABLE QM_FILES
)

# Deploy the generated .qm files next to the executable so the Translator
# singleton can load them from applicationDirPath()/translations.
install(FILES ${QM_FILES}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/translations
)

# Copy help markdown files next to the executable for runtime loading.
add_custom_command(TARGET appCWY POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/help $<TARGET_FILE_DIR:appCWY>/help
    COMMENT "Copying help files to build directory"
)
install(DIRECTORY ${CMAKE_SOURCE_DIR}/help/
    DESTINATION ${CMAKE_INSTALL_BINDIR}/help
)

set(CWY_RELEASE_DATE "2026-06-18" CACHE STRING "Release date shown in the installer package.xml")

# Generate installer metadata from templates so the version number only has to
# be updated in project() above.
configure_file(
    ${CMAKE_SOURCE_DIR}/Installer/config/config.xml.in
    ${CMAKE_SOURCE_DIR}/Installer/config/config.xml
    @ONLY)
configure_file(
    ${CMAKE_SOURCE_DIR}/Installer/packages/com.cwy.cwyapp/meta/package.xml.in
    ${CMAKE_SOURCE_DIR}/Installer/packages/com.cwy.cwyapp/meta/package.xml
    @ONLY)
configure_file(
    ${CMAKE_SOURCE_DIR}/Installer/build_installer.bat.in
    ${CMAKE_SOURCE_DIR}/Installer/build_installer.bat
    @ONLY)

set_target_properties(appCWY PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appCWY
    PRIVATE Qt6::Quick Qt6::SerialPort Qt6::QuickControls2
)

install(TARGETS appCWY
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Generate a deployment script for the QML application and include it at install time
qt_generate_deploy_qml_app_script(
    TARGET appCWY
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${deploy_script})
