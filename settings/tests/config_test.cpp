#include "config_test.h"
#include "../src/ConfigStore.h"
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QtTest>
void ConfigTest::write(QString path, QByteArray data) {
  QDir().mkpath(QFileInfo(path).absolutePath());
  QFile f(path);
  QVERIFY(f.open(QIODevice::WriteOnly));
  f.write(data);
}

QByteArray ConfigTest::read(QString path) {
  QFile f(path);
  if (!f.open(QIODevice::ReadOnly))
    return {};
  return f.readAll();
}

void ConfigTest::initTestCase() {
  root = temp.path() + "/shell";
  config = temp.path() + "/config";
  qputenv("XDG_CONFIG_HOME", config.toUtf8());
  qputenv("XDG_STATE_HOME", (temp.path() + "/state").toUtf8());
  qputenv("PATH",
          (QDir::homePath() + "/.local/bin:" + qEnvironmentVariable("PATH"))
              .toUtf8());
}

void ConfigTest::init() {
  QDir(config).removeRecursively();
  QDir(root).removeRecursively();
  write(config + "/abyssal/appearance.json",
        R"({"theme":"sample","custom":42})");
  write(root + "/themes/sample.json",
        R"({"name":"Sample","colors":{"base":"#100d18","accent":"#b8a0df"}})");
}

void ConfigTest::draftsDoNotWrite() {
  ConfigStore s(root);
  s.setValue("appearance", "mono", true);
  QCOMPARE(s.dirtyCount(), 1);
  QVERIFY(!read(config + "/abyssal/appearance.json").contains("mono"));
}

void ConfigTest::applyPreservesUnknownAndBacksUp() {
  ConfigStore s(root);
  s.setValue("appearance", "mono", true);
  QVERIFY(s.apply());
  QCOMPARE(s.value("appearance", "custom").toInt(), 42);
  QCOMPARE(s.dirtyCount(), 0);
  QVERIFY(s.message().contains("Backup:"));
}

void ConfigTest::malformedDraftIsBlocked() {
  ConfigStore s(root);
  s.setText("appearance", "{");
  QVERIFY(!s.apply());
  QVERIFY(read(config + "/abyssal/appearance.json").contains("custom"));
}

void ConfigTest::externalChangesAreKept() {
  ConfigStore s(root);
  s.setValue("appearance", "mono", true);
  write(config + "/abyssal/appearance.json", R"({"external":true})");
  QVERIFY(!s.apply());
  QVERIFY(read(config + "/abyssal/appearance.json").contains("external"));
  QCOMPARE(s.dirtyCount(), 1);
}

void ConfigTest::symlinksArePreserved() {
  QString target = temp.path() + "/real.json";
  write(target, R"({"custom":42})");
  QFile::remove(config + "/abyssal/appearance.json");
  QVERIFY(QFile::link(target, config + "/abyssal/appearance.json"));
  ConfigStore s(root);
  s.setValue("appearance", "mono", true);
  QVERIFY(s.apply());
  QVERIFY(QFileInfo(config + "/abyssal/appearance.json").isSymLink());
  QVERIFY(read(target).contains("mono"));
}

void ConfigTest::changedSymlinkIsBlocked() {
  QString a = temp.path() + "/a.json", b = temp.path() + "/b.json",
          p = config + "/abyssal/appearance.json";
  write(a, "{}");
  write(b, "{}");
  QFile::remove(p);
  QFile::link(a, p);
  ConfigStore s(root);
  s.setValue("appearance", "mono", true);
  QFile::remove(p);
  QFile::link(b, p);
  QVERIFY(!s.apply());
  QCOMPARE(read(b), QByteArray("{}"));
}

void ConfigTest::laterWriteFailureRollsBack() {
  QByteArray original = read(config + "/abyssal/appearance.json");
  write(config + "/abyssal/themes", "blocked");
  ConfigStore s(root);
  s.copyTheme("sample");
  QVERIFY(!s.apply());
  QCOMPARE(read(config + "/abyssal/appearance.json"), original);
}

void ConfigTest::shippedThemesCannotBeEdited() {
  ConfigStore s(root);
  s.setText("theme:sample", "{}");
  QCOMPARE(s.dirtyCount(), 0);
}

void ConfigTest::keybindDuplicateIsBlocked() {
  write(config + "/tidewm/config.wave",
        "bind Super+A { close-window }\nbind Super+B { toggle-floating }\n");
  ConfigStore s(root);
  auto rows = s.bindings();
  QCOMPARE(rows.size(), 2);
  auto b = rows[1].toMap();
  QVERIFY(!s.setBinding(b["id"].toString(), b["line"].toInt(), "Super+A",
                        "toggle-floating"));
  QCOMPARE(s.dirtyCount(), 0);
}

void ConfigTest::autostartPreservesExistingStartup() {
  if (QStandardPaths::findExecutable("wavefmt").isEmpty())
    QSKIP("wavefmt unavailable");
  write(config + "/tidewm/config.wave", "spawn = [\"shell-start\"]\n");
  ConfigStore s(root);
  s.setAutostart({QVariantMap{{"name", "Music"},
                              {"command", "music app"},
                              {"enabled", true}},
                  QVariantMap{{"name", "Disabled"},
                              {"command", "do-not-run"},
                              {"enabled", false}}});
  QVERIFY(s.apply());
  QVERIFY(read(config + "/tidewm/config.wave").contains("shell-start"));
  QVERIFY(
      read(config + "/tidewm/config.wave").contains("abyssal-autostart.wave"));
  auto managed = read(config + "/tidewm/abyssal-autostart.wave");
  QVERIFY(managed.contains("music app"));
  QVERIFY(!managed.contains("do-not-run"));
}
void ConfigTest::appLookUsesProtectedDrafts() {
  ConfigStore s(root);
  s.setValue("settings", "backgroundStyle", "custom");
  s.setValue("settings", "backgroundTop", "#16305a");
  s.setValue("settings", "snow", 0);
  QVERIFY(!QFileInfo::exists(config + "/abyssal/settings.json"));
  QVERIFY(s.apply());
  s.reload();
  QCOMPARE(s.value("settings", "snow").toInt(), 0);
  QCOMPARE(s.value("settings", "backgroundTop").toString(), "#16305a");
  s.setValue("settings", "snow", 80);
  write(config + "/abyssal/settings.json", R"({"external":true})");
  QVERIFY(!s.apply());
  QVERIFY(read(config + "/abyssal/settings.json").contains("external"));
}

void ConfigTest::invalidAppLookIsBlocked() {
  for (const auto &draft : {R"({"glass":16})", R"({"snow":-1})",
                           R"({"windowOpacity":39})", R"({"glowStrength":41})",
                           R"({"backgroundTop":"broken"})",
                           R"({"backgroundStyle":"broken"})",
                           R"({"density":"broken"})", R"({"drift":1})"}) {
    ConfigStore s(root);
    s.setText("settings", draft);
    QVERIFY(!s.apply());
    QVERIFY(!QFileInfo::exists(config + "/abyssal/settings.json"));
  }
}

void ConfigTest::resetAppLookPreservesUnknownKeys() {
  write(config + "/abyssal/settings.json", R"({"glass":10,"future":42})");
  ConfigStore s(root);
  s.resetAppLook();
  QCOMPARE(s.value("settings", "glass", 3).toInt(), 3);
  QCOMPARE(s.value("settings", "future").toInt(), 42);
  QVERIFY(read(config + "/abyssal/settings.json").contains("glass"));
  QVERIFY(s.apply());
  QVERIFY(!read(config + "/abyssal/settings.json").contains("glass"));
  s.setText("settings", "{broken");
  s.resetAppLook();
  QCOMPARE(s.text("settings"), "{broken");
}
QTEST_GUILESS_MAIN(ConfigTest)
