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
    config = temp.path() + "/config";
    qputenv("XDG_CONFIG_HOME", config.toUtf8());
    qputenv("XDG_STATE_HOME", (temp.path() + "/state").toUtf8());
    QQuickStyle::setStyle("Basic");
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
    for (const auto &page : {"appearance", "appLook", "wallpaper", "panels",
                             "keybinds", "tidewm", "autostart", "updates",
                             "notifications", "idle", "account", "files"}) {
      window->setProperty("page", page);
      QTest::qWait(20);
      QVERIFY2(warnings.isEmpty(),
               qPrintable(QString(page) + ": " + warnings.join('\n')));
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
