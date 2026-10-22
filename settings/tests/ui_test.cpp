#include "../src/ConfigStore.h"
#include <QDir>
#include <QFile>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlExpression>
#include <QQuickItem>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTemporaryDir>
#include <QtTest>
#include <functional>

class UiTest : public QObject {
  Q_OBJECT
  QTemporaryDir temp;
  QString config;
  QStringList warnings;
  static UiTest *current;
  static QQuickItem *findItem(QQuickItem *item, const QString &name) {
    if (item->objectName() == name)
      return item;
    for (auto child : item->childItems())
      if (auto result = findItem(child, name))
        return result;
    return nullptr;
  }
  static void messages(QtMsgType type, const QMessageLogContext &,
                       const QString &message) {
    if (type == QtWarningMsg && current)
      current->warnings << message;
  }
  void write(const QString &path, const QByteArray &text) {
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write(text);
  }
private slots:
  void initTestCase() {
    config =
        qEnvironmentVariable("SETTINGS_NESTED_CONFIG", temp.path() + "/config");
    qputenv("XDG_CONFIG_HOME", config.toUtf8());
    qputenv("XDG_STATE_HOME", (temp.path() + "/state").toUtf8());
    QQuickStyle::setStyle("Basic");
    QGuiApplication::setDesktopFileName("org.abyssal.Settings");
    current = this;
    qInstallMessageHandler(messages);
  }
  void cleanupTestCase() {
    qInstallMessageHandler(nullptr);
    current = nullptr;
  }
  void pages_data() {
    QTest::addColumn<QString>("theme");
    QTest::addColumn<QString>("density");
    QTest::addColumn<QSize>("size");
    for (const auto &theme :
         {"abyssal-tide", "trench-violet", "kelp-forest", "ember-vent"})
      for (const auto &density : {"compact", "normal", "roomy"})
        for (const auto &size : {QSize(860, 560), QSize(1920, 1080)})
          QTest::newRow(qPrintable(
              QString("%1-%2-%3").arg(theme, density).arg(size.width())))
              << QString(theme) << QString(density) << size;
  }
  void pages() {
    QFETCH(QString, theme);
    QFETCH(QString, density);
    QFETCH(QSize, size);
    warnings.clear();
    write(config + "/abyssal/appearance.json",
          "{\"theme\":\"" + theme.toUtf8() + "\"}");
    write(config + "/abyssal/settings.json",
          "{\"reduceMotion\":true,\"density\":\"" + density.toUtf8() + "\"}");
    ConfigStore store(SETTINGS_SOURCE_ROOT);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("Store", &store);
    engine.rootContext()->setContextProperty("initialPage", "appearance");
    engine.load(QUrl("qrc:/qml/Main.qml"));
    QVERIFY2(!engine.rootObjects().isEmpty(), qPrintable(warnings.join('\n')));
    auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    QVERIFY(window);
    window->resize(size);
    for (const auto &page :
         {"appearance", "appLook", "wallpaper", "panels", "keybinds", "windows",
          "motion", "input", "autostart", "updates", "notifications", "idle",
          "account", "files"}) {
      window->setProperty("page", page);
      QTest::qWait(20);
      QVERIFY2(warnings.isEmpty(),
               qPrintable(QString(page) + ": " + warnings.join('\n')));
      std::function<void(QQuickItem *)> checkBounds = [&](QQuickItem *item) {
        const auto name = item->objectName();
        if (item->isVisible() &&
            (name == "stepper" || name == "slider" || name == "choice" ||
             name.startsWith("engine-"))) {
          const auto rect = item->mapRectToScene(item->boundingRect());
          QVERIFY2(rect.left() >= -0.5 && rect.right() <= window->width() + 0.5,
                   qPrintable(QString(page) + ": clipped " + name));
        }
        for (auto child : item->childItems())
          checkBounds(child);
      };
      checkBounds(window->contentItem());
    }
    // A theme switch must recolour the existing window, including the
    // background.
    store.setValue("appearance", "theme",
                   theme == "kelp-forest" ? "ember-vent" : "kelp-forest");
    store.setValue("settings", "backgroundStyle", "solid");
    window->setProperty("page", "appLook");
    QTest::qWait(100);
    QVERIFY2(warnings.isEmpty(), qPrintable(warnings.join('\n')));
    QVERIFY(store.dirtyCount() > 0);
    // Discard must restore both theme and this app's preview preferences.
    store.reload();
    QTest::qWait(100);
    QCOMPARE(store.dirtyCount(), 0);
    QCOMPARE(store.value("appearance", "theme").toString(), theme);
    QVERIFY2(warnings.isEmpty(), qPrintable(warnings.join('\n')));
    window->hide();
  }
  void minimizeAndRestore() {
    warnings.clear();
    write(config + "/abyssal/settings.json", R"({"reduceMotion":true})");
    ConfigStore store(SETTINGS_SOURCE_ROOT);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("Store", &store);
    engine.rootContext()->setContextProperty("initialPage", "windows");
    engine.load(QUrl("qrc:/qml/Main.qml"));
    QVERIFY(!engine.rootObjects().isEmpty());
    auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    QVERIFY(window);
    QTest::qWait(100);
    auto button = findItem(window->contentItem(), "minimizeWindow");
    QVERIFY(button);
    store.setValue("settings", "fontSize", 14);
    const auto dirty = store.dirtyCount();
    QVERIFY(dirty > 0);
    window->setProperty("hideOnMinimize", true);
    auto clickMinimize = [&] {
      QTest::mouseClick(window, Qt::LeftButton, Qt::NoModifier,
                       button->mapToScene(button->boundingRect().center()).toPoint());
    };
    clickMinimize();
    QTRY_VERIFY(!window->isVisible());
    QCOMPARE(window->property("hiddenByMinimize").toBool(), true);
    QVERIFY(QMetaObject::invokeMethod(window, "restoreWindow"));
    QTRY_VERIFY(window->isVisible());
    QCOMPARE(window->property("page").toString(), QString("windows"));
    QCOMPARE(store.dirtyCount(), dirty);
    QCOMPARE(store.value("settings", "fontSize").toInt(), 14);
    // The offscreen platform accepts all requested window states. A real
    // compositor may refuse maximization (e.g. a forced-floating test rule)
    // or minimization; exercise those restoration paths deterministically.
    if (QGuiApplication::platformName() != "offscreen") {
      window->hide();
      return;
    }
    window->showMaximized();
    QTRY_COMPARE(window->visibility(), QWindow::Maximized);
    QTest::qWait(50);
    clickMinimize();
    QTRY_VERIFY(!window->isVisible());
    QVERIFY(QMetaObject::invokeMethod(window, "restoreWindow"));
    QTRY_COMPARE(window->visibility(), QWindow::Maximized);
    QCOMPARE(store.dirtyCount(), dirty);
    window->setProperty("hideOnMinimize", false);
    QVERIFY(QMetaObject::invokeMethod(window, "minimizeWindow"));
    QTRY_COMPARE(window->visibility(), QWindow::Minimized);
    QVERIFY(QMetaObject::invokeMethod(window, "restoreWindow"));
    QTRY_VERIFY(window->isVisible());
    window->hide();
  }
  void desktopControls() {
    warnings.clear();
    const auto path = config + "/tidewm/config.wave";
    if (!qEnvironmentVariableIsSet("SETTINGS_NESTED_CONFIG"))
      write(path, "# My desktop\nengine = classic\ngaps = 8\n");
    write(config + "/abyssal/settings.json", R"({"reduceMotion":true})");
    ConfigStore store(SETTINGS_SOURCE_ROOT);
    if (!store.desktopEditable())
      QSKIP("wavefmt unavailable");
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("Store", &store);
    engine.rootContext()->setContextProperty("initialPage", "windows");
    engine.load(QUrl("qrc:/qml/Main.qml"));
    QVERIFY2(!engine.rootObjects().isEmpty(), qPrintable(warnings.join('\n')));
    auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    QVERIFY(window);
    QTest::qWait(300);
    auto card = findItem(window->contentItem(), "engine-scroll");
    QVERIFY(card);
    QTest::mouseClick(
        window, Qt::LeftButton, Qt::NoModifier,
        card->mapToScene(QPointF(card->width() / 2, card->height() / 2))
            .toPoint());
    QCOMPARE(store.desktopValue("engine").toString(), "scroll");
    auto column = findItem(window->contentItem(), "scroll.tile_proportion");
    QVERIFY(column);
    auto slider = findItem(column, "slider");
    QVERIFY(slider);
    slider->forceActiveFocus();
    QTest::keyClick(window, Qt::Key_End);
    QCOMPARE(store.desktopValue("scroll.tile_proportion").toDouble(), 1.0);
    auto gap = findItem(window->contentItem(), "gaps");
    QVERIFY(gap);
    auto gapSlider = findItem(gap, "slider");
    QVERIFY(gapSlider);
    gapSlider->forceActiveFocus();
    QTest::keyClick(window, Qt::Key_Right);
    QCOMPARE(store.desktopValue("gaps").toInt(), 9);
    auto border = findItem(window->contentItem(), "border.width");
    QVERIFY(border);
    auto borderSlider = findItem(border, "slider");
    QVERIFY(borderSlider);
    borderSlider->forceActiveFocus();
    QTest::keyClick(window, Qt::Key_Right);
    QCOMPARE(store.desktopValue("border.width").toInt(), 3);
    QFile before(path);
    QVERIFY(before.open(QIODevice::ReadOnly));
    QVERIFY(!before.readAll().contains("include"));
    before.close();
    auto save = findItem(window->contentItem(), "saveChanges");
    QVERIFY(save);
    QTest::mouseClick(
        window, Qt::LeftButton, Qt::NoModifier,
        save->mapToScene(QPointF(save->width() / 2, save->height() / 2))
            .toPoint());
    QCOMPARE(store.dirtyCount(), 0);
    QFile after(path);
    QVERIFY(after.open(QIODevice::ReadOnly));
    QVERIFY(after.readAll().contains("include \"abyssal-settings.wave\""));
    QTest::qWait(200);
    QVERIFY2(warnings.isEmpty(), qPrintable(warnings.join('\n')));
    window->hide();
  }
  void shortcutRecording() {
    warnings.clear();
    write(config + "/tidewm/config.wave", "bind Super+Q { close-window }\n");
    ConfigStore store(SETTINGS_SOURCE_ROOT);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("Store", &store);
    engine.rootContext()->setContextProperty("initialPage", "keybinds");
    engine.load(QUrl("qrc:/qml/Main.qml"));
    QVERIFY(!engine.rootObjects().isEmpty());
    auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    QVERIFY(window);
    QTest::qWait(100);
    auto recorder = findItem(window->contentItem(), "shortcutRecorder");
    QVERIFY(recorder);
    QTest::mouseClick(
        window, Qt::LeftButton, Qt::NoModifier,
        recorder
            ->mapToScene(QPointF(recorder->width() / 2, recorder->height() / 2))
            .toPoint());
    QVERIFY(recorder->property("recording").toBool());
    QTest::keyClick(window, Qt::Key_K, Qt::ControlModifier | Qt::ShiftModifier);
    QCOMPARE(recorder->property("chord").toString(), "Ctrl+Shift+K");
    QVERIFY(!recorder->property("recording").toBool());
    QCOMPARE(store.dirtyCount(), 0);
    auto submit = findItem(window->contentItem(), "shortcutSubmit");
    QVERIFY(submit);
    QTest::mouseClick(
        window, Qt::LeftButton, Qt::NoModifier,
        submit->mapToScene(QPointF(submit->width() / 2, submit->height() / 2))
            .toPoint());
    QVERIFY(store.bindings().size() == 2);
    QVERIFY(store.dirtyCount() > 0);
    QVERIFY2(warnings.isEmpty(), qPrintable(warnings.join('\n')));
    window->hide();
  }
  void panelControlsPreserveWidgetSettings() {
    warnings.clear();
    write(
        config + "/abyssal/layout.json",
        R"({"version":2,"future":42,"monitors":{"*":{"panels":[{"edge":"top","size":44,"extra":42,"items":[{"id":"clock","date":true}]}]},"Display.with.dots":{"panels":[],"future":7}}})");
    ConfigStore store(SETTINGS_SOURCE_ROOT);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("Store", &store);
    engine.rootContext()->setContextProperty("initialPage", "panels");
    engine.load(QUrl("qrc:/qml/Main.qml"));
    QVERIFY(!engine.rootObjects().isEmpty());
    auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    QVERIFY(window);
    QTest::qWait(100);
    auto add = findItem(window->contentItem(), "addPanel");
    QVERIFY(add);
    QTest::mouseClick(
        window, Qt::LeftButton, Qt::NoModifier,
        add->mapToScene(QPointF(add->width() / 2, add->height() / 2))
            .toPoint());
    QVERIFY2(warnings.isEmpty(), qPrintable(warnings.join('\n')));
    auto all = store.value("layout", "monitors").toMap();
    QVERIFY2(all["*"].toMap()["panels"].toList().size() == 2,
             qPrintable(store.text("layout") + store.message()));
    auto field = findItem(window->contentItem(), "panelThickness");
    QVERIFY(field);
    auto slider = findItem(field, "slider");
    QVERIFY(slider);
    slider->forceActiveFocus();
    QTest::keyClick(window, Qt::Key_Right);
    all = store.value("layout", "monitors").toMap();
    const auto panels = all["*"].toMap()["panels"].toList();
    QCOMPARE(panels[1].toMap()["size"].toInt(), 37);
    QCOMPARE(panels[0].toMap()["extra"].toInt(), 42);
    QCOMPARE(panels[0].toMap()["items"].toList()[0].toMap()["date"].toBool(),
             true);
    QCOMPARE(all["Display.with.dots"].toMap()["future"].toInt(), 7);
    QCOMPARE(store.value("layout", "future").toInt(), 42);
    QVERIFY2(warnings.isEmpty(), qPrintable(warnings.join('\n')));
    window->hide();
  }
  void appearanceControls() {
    warnings.clear();
    write(config + "/abyssal/appearance.json", R"({"theme":"abyssal-tide"})");
    write(config + "/abyssal/settings.json", R"({"reduceMotion":true})");
    ConfigStore store(SETTINGS_SOURCE_ROOT);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("Store", &store);
    engine.rootContext()->setContextProperty("initialPage", "appLook");
    engine.load(QUrl("qrc:/qml/Main.qml"));
    QVERIFY2(!engine.rootObjects().isEmpty(), qPrintable(warnings.join('\n')));
    auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    QVERIFY(window);
    QTest::qWait(100);
    auto snow = findItem(window->contentItem(), "snow");
    QVERIFY(snow);
    auto slider = findItem(snow, "slider");
    QVERIFY(slider);
    slider->forceActiveFocus();
    QTest::keyClick(window, Qt::Key_Home);
    QCOMPARE(store.value("settings", "snow").toInt(), 0);
    QTest::keyClick(window, Qt::Key_End);
    QCOMPARE(store.value("settings", "snow").toInt(), 100);
    auto drift = findItem(window->contentItem(), "drift");
    QVERIFY(drift);
    auto toggle = findItem(drift, "switch");
    QVERIFY(toggle);
    toggle->forceActiveFocus();
    QTest::keyClick(window, Qt::Key_Space);
    QCOMPARE(store.value("settings", "drift").toBool(), false);
    QQmlExpression base(qmlContext(window), window, "Theme.base");
    auto original = base.evaluate().value<QColor>();
    QVERIFY(original.isValid());
    store.setValue("appearance", "theme", "kelp-forest");
    QTest::qWait(100);
    QCOMPARE(base.evaluate().value<QColor>(), QColor("#0a1916"));
    QVERIFY(base.evaluate().value<QColor>() != original);
    store.reload();
    QTest::qWait(100);
    QCOMPARE(base.evaluate().value<QColor>(), original);
    QCOMPARE(store.value("settings", "snow", 80).toInt(), 80);
    QCOMPARE(store.dirtyCount(), 0);
    auto density = findItem(window->contentItem(), "density");
    QVERIFY(density);
    auto choice = findItem(density, "choice");
    QVERIFY(choice);
    choice->forceActiveFocus();
    QTest::keyClick(window, Qt::Key_Down);
    QCOMPARE(store.value("settings", "density").toString(), "roomy");
    window->setProperty("page", "notifications");
    QTest::qWait(100);
    auto maximum = findItem(window->contentItem(), "maxToasts");
    QVERIFY(maximum);
    auto stepper = findItem(maximum, "stepper");
    QVERIFY(stepper);
    stepper->forceActiveFocus();
    QTest::keyClick(window, Qt::Key_Up);
    QCOMPARE(store.value("notifications", "maxToasts").toInt(), 6);
    store.reload();
    QTest::qWait(100);
    QCOMPARE(store.dirtyCount(), 0);
    QVERIFY2(warnings.isEmpty(), qPrintable(warnings.join('\n')));
    window->hide();
  }
};
UiTest *UiTest::current = nullptr;
QTEST_MAIN(UiTest)
#include "ui_test.moc"
