cmake_minimum_required(VERSION 3.21)
project(AbyssalSettings VERSION 0.1.0 LANGUAGES CXX)
include(GNUInstallDirs)
configure_file(org.abyssal.Settings.desktop.in org.abyssal.Settings.desktop @ONLY)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2 Network)
set(SETTINGS_CORE src/ConfigStore.cpp src/ConfigStore.h src/DesktopSettings.cpp src/WaveSettings.cpp src/WaveSettings.h)
qt_add_executable(abyssal-settings src/main.cpp ${SETTINGS_CORE})
set(SETTINGS_UI_FILES
  qml/PanelsPage.qml
  qml/StartupPage.qml
  qml/ShortcutRecorder.qml
  qml/ShortcutEditor.qml
  qml/ShortcutsPage.qml
  registry/desktop.json
  qml/DesktopPage.qml
  qml/EnginePicker.qml
  qml/WidthPresets.qml
  qml/KeyboardLayouts.qml
  qml/Avatar.qml
  qml/WindowButton.qml
  icons/minimize.svg
  icons/maximize.svg
  icons/restore.svg
  icons/close.svg
  icons/back.svg
  icons/save.svg
  icons/windows.svg
  icons/motion.svg
  icons/input.svg
  qml/Main.qml
  qml/Field.qml
  qml/JsonForm.qml
  qml/qmldir
  qml/Theme.qml
  qml/Atmosphere.qml
  qml/SettingGroup.qml
  qml/ArchiveButton.qml
  qml/ArchiveSwitch.qml
  qml/ArchiveSlider.qml
  qml/ArchiveTextField.qml
  qml/AppLook.qml
  qml/ArchiveIcon.qml
  qml/ArchiveComboBox.qml
  qml/ArchiveSpinBox.qml
  icons/appearance.svg
  icons/appLook.svg
  icons/wallpaper.svg
  icons/panels.svg
  icons/keybinds.svg
  icons/tidewm.svg
  icons/autostart.svg
  icons/updates.svg
  icons/notifications.svg
  icons/idle.svg
  icons/account.svg
  icons/files.svg
)
qt_add_resources(abyssal-settings ui PREFIX / FILES ${SETTINGS_UI_FILES})
target_link_libraries(abyssal-settings PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Network)
install(TARGETS abyssal-settings RUNTIME DESTINATION bin)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/org.abyssal.Settings.desktop DESTINATION share/applications)
install(FILES ../assets/abyssal.svg DESTINATION share/icons/hicolor/scalable/apps RENAME org.abyssal.Settings.svg)
include(CTest)
if(BUILD_TESTING)
 find_package(Qt6 REQUIRED COMPONENTS Test)
 qt_add_executable(settings-test tests/config_test.cpp tests/config_test.h ${SETTINGS_CORE})
 qt_add_resources(settings-test registry PREFIX / FILES registry/desktop.json)
 target_link_libraries(settings-test PRIVATE Qt6::Quick Qt6::Test)
 add_test(NAME settings-store COMMAND settings-test)
 qt_add_executable(settings-ui-test tests/ui_test.cpp ${SETTINGS_CORE})
 qt_add_resources(settings-ui-test ui PREFIX / FILES ${SETTINGS_UI_FILES})
 target_compile_definitions(settings-ui-test PRIVATE SETTINGS_SOURCE_ROOT="${CMAKE_CURRENT_SOURCE_DIR}/..")
 target_link_libraries(settings-ui-test PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Test)
 add_test(NAME settings-ui COMMAND settings-ui-test)
 set_tests_properties(settings-ui PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software")
endif()
