#include "config_test.h"
#include "../src/ConfigStore.h"
#include <QDir>
#include <QFile>
#include <QJSEngine>
#include <QJsonDocument>
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
  for (const auto &draft :
       {R"({"glass":16})", R"({"snow":-1})", R"({"windowOpacity":39})",
        R"({"glowStrength":41})", R"({"backgroundTop":"broken"})",
        R"({"backgroundStyle":"broken"})", R"({"density":"broken"})",
        R"({"drift":1})"}) {
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

void ConfigTest::desktopReadsIncludesInOrder() {
  write(config + "/tidewm/config.wave",
        "gaps = 4\ninclude \"look.wave\"\ngaps = 9\n");
  write(config + "/tidewm/look.wave",
        "gaps = 6\nscroll {\n tile_proportion = 0.94\n center_focused = "
        "true\n}\nrule {\n gaps = 55\n}\nbind Super+Q { close-window }\n");
  ConfigStore s(root);
  QCOMPARE(s.desktopValue("gaps").toInt(), 9);
  QCOMPARE(s.desktopValue("scroll.tile_proportion").toDouble(), .94);
  QCOMPARE(s.desktopValue("scroll.center_focused").toString(), "always");
  write(config + "/tidewm/config.wave", "gaps = 4\ninclude \"look.wave\"\n");
  s.reload();
  QCOMPARE(s.desktopValue("gaps").toInt(), 4);
  QCOMPARE(s.dirtyCount(), 0);
}
void ConfigTest::desktopDraftsPreserveAndApply() {
  if (!ConfigStore(root).desktopEditable())
    QSKIP("wavefmt unavailable");
  const QByteArray original = "# My configuration\ngaps = 9\ninclude "
                              "\"look.wave\"\nbind Super+Q { close-window }\n";
  write(config + "/tidewm/config.wave", original);
  write(config + "/tidewm/look.wave", "rounding {\n radius = 12\n}\n");
  ConfigStore s(root);
  QVERIFY(s.setDesktopValue("engine", "scroll"));
  QVERIFY(s.setDesktopValue("gaps", 18));
  QVERIFY(s.setDesktopValue("scroll.tile_proportion", .67));
  QVERIFY(
      s.setDesktopValue("scroll.preset_widths", QVariantList{.333, .5, .8}));
  QVERIFY(s.setDesktopValue("input.touchpad.natural_scroll", true));
  QCOMPARE(read(config + "/tidewm/config.wave"), original);
  QVERIFY(!QFileInfo::exists(config + "/tidewm/abyssal-settings.wave"));
  QCOMPARE(s.desktopValue("gaps").toInt(), 18);
  QVERIFY(s.apply());
  QVERIFY(read(config + "/tidewm/config.wave").contains("# My configuration"));
  QVERIFY(read(config + "/tidewm/config.wave").contains("gaps = 18"));
  QVERIFY(read(config + "/tidewm/config.wave")
              .contains("bind Super+Q { close-window }"));
  QCOMPARE(read(config + "/tidewm/look.wave"),
           QByteArray("rounding {\n radius = 12\n}\n"));
  s.reload();
  QCOMPARE(s.desktopValue("engine").toString(), "scroll");
  QCOMPARE(s.desktopValue("scroll.tile_proportion").toDouble(), .67);
  QCOMPARE(s.desktopValue("input.touchpad.natural_scroll").toBool(), true);
  const auto managed = read(config + "/tidewm/abyssal-settings.wave");
  QVERIFY(s.setDesktopValue("gaps", 22));
  QVERIFY(s.setDesktopValue("gaps", 18));
  QCOMPARE(s.text("wave:" + config + "/tidewm/abyssal-settings.wave").toUtf8(),
           managed);
  QCOMPARE(s.dirtyCount(), 0);
}
void ConfigTest::desktopInvalidAndExternalChanges() {
  if (!ConfigStore(root).desktopEditable())
    QSKIP("wavefmt unavailable");
  write(config + "/tidewm/config.wave", "gaps = 8\n");
  ConfigStore s(root);
  QVERIFY(!s.setDesktopValue("gaps", -1));
  QVERIFY(!s.setDesktopValue("engine", "scroll\nspawn = malicious"));
  QVERIFY(!s.setDesktopValue("input.xkb_layout", "us\"\nspawn = malicious"));
  QVERIFY(!s.setDesktopValue("scroll.preset_widths", QVariantList{.5, .333}));
  QCOMPARE(s.dirtyCount(), 0);
  QVERIFY(s.setDesktopValue("gaps", 10));
  write(config + "/tidewm/config.wave", "# changed elsewhere\ngaps = 30\n");
  QVERIFY(!s.apply());
  QVERIFY(read(config + "/tidewm/config.wave").contains("gaps = 30"));
  QVERIFY(!QFileInfo::exists(config + "/tidewm/abyssal-settings.wave"));
  write(config + "/tidewm/config.wave", "include \"abyssal-settings.wave\"\n");
  write(config + "/tidewm/abyssal-settings.wave", "border {\n width = 2\n}\n");
  s.reload();
  QVERIFY(s.setDesktopValue("border.width", 3));
  write(config + "/tidewm/config.wave",
        "include \"abyssal-settings.wave\"\nborder {\n width = 8\n}\n");
  QVERIFY(!s.apply());
  QVERIFY(read(config + "/tidewm/abyssal-settings.wave").contains("width = 2"));
}
void ConfigTest::animationPresetsAndOverrides() {
  if (!ConfigStore(root).desktopEditable())
    QSKIP("wavefmt unavailable");
  write(config + "/tidewm/config.wave",
        "animations {\n open {\n  duration = 2s\n }\n preset = snappy\n}\n");
  ConfigStore s(root);
  QCOMPARE(s.desktopValue("animations.open.duration").toInt(), 2000);
  QCOMPARE(s.desktopValue("animations.close.duration").toInt(), 100);
  QVERIFY(s.setDesktopValue("animations.preset", "silk"));
  QCOMPARE(s.desktopValue("animations.open.duration").toInt(), 170);
  QVERIFY(s.setDesktopValue("animations.open.duration", 250));
  QCOMPARE(s.desktopValue("animations.open.duration").toInt(), 250);
  QVERIFY(s.setDesktopValue("animations.preset", "minimal"));
  QCOMPARE(s.desktopValue("animations.open.duration").toInt(), 100);
  QVERIFY(s.apply());
  write(config + "/tidewm/config.wave",
        "animations {\n open {\n duration = 500ms\n }\n}\nanimations {\n "
        "preset = snappy\n}\n");
  s.reload();
  QCOMPARE(s.desktopValue("animations.open.duration").toInt(), 120);
  QVERIFY(s.setDesktopValue("animations.open.duration", 280));
  QCOMPARE(s.desktopValue("animations.open.duration").toInt(), 280);
  QVERIFY(s.apply());
}
void ConfigTest::accentIsSharedAndShippedThemeIsKept() {
  ConfigStore s(root);
  const auto original = read(root + "/themes/sample.json");
  QVERIFY(s.setAccent("#123abc"));
  const auto id = s.value("appearance", "theme").toString();
  QVERIFY(id.startsWith("custom-"));
  QCOMPARE(s.value("theme:" + id, "colors.accent").toString(), "#123abc");
  QCOMPARE(s.value("theme:" + id, "tidewm.border").toList(),
           QVariantList({"#123abc", "#123abc"}));
  QCOMPARE(read(root + "/themes/sample.json"), original);
  QVERIFY(!s.setAccent("not a colour"));
}
void ConfigTest::externalChangesReloadWithoutLosingDrafts() {
  ConfigStore s(root);
  write(config + "/abyssal/appearance.json",
        R"({"theme":"external","custom":42})");
  QTRY_COMPARE(s.value("appearance", "theme").toString(), "external");
  QCOMPARE(s.dirtyCount(), 0);
  s.setValue("appearance", "theme", "my-draft");
  write(config + "/abyssal/appearance.json", R"({"theme":"other-app"})");
  QTRY_VERIFY(s.externalChange());
  QCOMPARE(s.value("appearance", "theme").toString(), "my-draft");
  QVERIFY(!s.apply());
  QVERIFY(read(config + "/abyssal/appearance.json").contains("other-app"));
}

void ConfigTest::deviceSettingsCanBeRestored() {
  if (!ConfigStore(root).desktopEditable())
    QSKIP("wavefmt unavailable");
  write(config + "/tidewm/config.wave",
        "input {\n xkb_layout = us\n touchpad {\n  tap_to_click = false # "
        "device preference\n }\n}\n");
  ConfigStore s(root);
  QVERIFY(s.setDesktopValue("input.touchpad.tap_to_click", true));
  QVERIFY(s.setDesktopValue("input.touchpad.natural_scroll", true));
  QCOMPARE(s.desktopValue("input.touchpad.tap_to_click").toBool(), true);
  QVERIFY(s.apply());
  s.reload();
  QVERIFY(s.setDesktopValue("input.touchpad.tap_to_click", "device-default"));
  QVERIFY(s.setDesktopValue("input.touchpad.natural_scroll", "device-default"));
  QCOMPARE(s.desktopValue("input.touchpad.tap_to_click").toBool(), false);
  QVERIFY(!s.desktopValue("input.touchpad.natural_scroll").isValid());
  QVERIFY(s.apply());
  QVERIFY(read(config + "/tidewm/config.wave")
              .contains("tap_to_click = false # device preference"));
  QVERIFY(!read(config + "/tidewm/config.wave").contains("natural_scroll"));
}
void ConfigTest::qmlObjectsAndArraysRemainStructured() {
  ConfigStore s(root);
  QJSEngine js;
  s.setValue(
      "layout", "monitors",
      QVariant::fromValue(js.evaluate("({'Display.with.dots':{panels:[{items:[{"
                                      "id:'clock',date:true}]}]}})")));
  auto monitors = s.value("layout", "monitors").toMap();
  const auto items = monitors["Display.with.dots"]
                         .toMap()["panels"]
                         .toList()[0]
                         .toMap()["items"]
                         .toList();
  QCOMPARE(items[0].toMap()["date"].toBool(), true);
  QVERIFY(!s.text("layout").contains("null"));
  if (s.desktopEditable()) {
    QVERIFY(
        s.setDesktopValue("scroll.preset_widths",
                          QVariant::fromValue(js.evaluate("[0.25,0.5,0.75]"))));
    QCOMPARE(s.desktopValue("scroll.preset_widths").toList().size(), 3);
  }
  s.setAutostart({QVariant::fromValue(
      js.evaluate("({name:'Music',command:'music-app',enabled:true})"))});
  QCOMPARE(s.value("autostart", "apps").toList()[0].toMap()["name"].toString(),
           "Music");
}
QTEST_GUILESS_MAIN(ConfigTest)

void ConfigTest::themePresetsRoundTrip() {
  ConfigStore s(root);
  const auto shipped = read(root + "/themes/sample.json");
  QVERIFY(s.setThemeColor("base", "#123456"));
  const auto editable = s.value("appearance", "theme").toString();
  QVERIFY(editable != "sample");
  QCOMPARE(s.value("theme:" + editable, "colors.base").toString(), "#123456");
  QVERIFY(s.setThemeColor("accent", "#abc123"));
  QVERIFY(s.setThemeOption("glass", .5));
  const auto saved = s.saveTheme("My ocean / test");
  QVERIFY(!saved.isEmpty());
  QVERIFY(!saved.contains('/'));
  QCOMPARE(s.value("theme:" + saved, "glass").toDouble(), .5);
  QVERIFY(!QFileInfo::exists(config + "/abyssal/themes/" + saved + ".json"));
  const auto output = QUrl::fromLocalFile(temp.path() + "/theme-export.json");
  QVERIFY(s.exportPreset("theme", "", output));
  QCOMPARE(read(root + "/themes/sample.json"), shipped);
  const auto imported = s.importPreset("theme", output);
  QVERIFY(!imported.isEmpty());
  QVERIFY(imported != saved);
  QCOMPARE(s.value("appearance", "theme").toString(), imported);
  QCOMPARE(s.value("theme:" + imported, "colors.base").toString(), "#123456");
  QCOMPARE(s.value("theme:" + imported, "tidewm.border").toList(),
           QVariantList({"#abc123", "#abc123"}));
  QVERIFY(s.apply());
  ConfigStore reopened(root);
  QCOMPARE(reopened.value("appearance", "theme").toString(), imported);
  QCOMPARE(reopened.value("theme:" + imported, "name").toString(), "My ocean / test");
  QCOMPARE(reopened.value("theme:" + imported, "glass").toDouble(), .5);
  QCOMPARE(read(root + "/themes/sample.json"), shipped);
}

void ConfigTest::panelPresetsRoundTrip() {
  const QByteArray layout = R"({"version":2,"future":{"keep":true},"monitors":{"DP-1.2":{"panels":[{"edge":"bottom","size":44,"items":[{"id":"clock","date":true},"tray"],"future":42}]},"*":{"panels":[]}}})";
  write(config + "/abyssal/layout.json", layout);
  ConfigStore s(root);
  const auto saved = s.savePanelPreset("Work / wide");
  QVERIFY(!saved.isEmpty());
  QCOMPARE(s.panelPresets().size(), 1);
  QVERIFY(!QFileInfo::exists(config + "/abyssal/panel-presets/" + saved + ".json"));
  s.setValue("layout", "monitors", QVariantMap{});
  QVERIFY(s.loadPanelPreset(saved));
  QCOMPARE(QJsonDocument::fromJson(s.text("layout").toUtf8()), QJsonDocument::fromJson(layout));
  const auto output = QUrl::fromLocalFile(temp.path() + "/panels-export.json");
  QVERIFY(s.exportPreset("panels", "", output));
  const auto imported = s.importPreset("panels", output);
  QVERIFY(!imported.isEmpty());
  QCOMPARE(s.panelPresets().size(), 2);
  s.setValue("layout", "monitors", QVariantMap{});
  QVERIFY(s.loadPanelPreset(imported));
  QCOMPARE(QJsonDocument::fromJson(s.text("layout").toUtf8()), QJsonDocument::fromJson(layout));
  QVERIFY(s.apply());
  ConfigStore reopened(root);
  QCOMPARE(reopened.panelPresets().size(), 2);
  QVERIFY(reopened.loadPanelPreset(saved));
  QCOMPARE(QJsonDocument::fromJson(reopened.text("layout").toUtf8()), QJsonDocument::fromJson(layout));
}

void ConfigTest::invalidPresetsDoNotChangeDrafts() {
  ConfigStore s(root);
  const auto before = s.dirtyCount();
  const auto selected = s.value("appearance", "theme");
  const auto file = temp.path() + "/invalid-preset.json";
  for (const auto &content : {QByteArray("{bad"), QByteArray("[]"), QByteArray(R"({"colors":{"base":"oops"}})"),
      QByteArray(R"({"colors":{"base":"#123456"},"glass":4})"),
      QByteArray(R"({"name":"bad\nname","colors":{"base":"#123456"}})"),
      QByteArray(R"({"colors":{"base":"#123456"},"tidewm":{"border":["#123456","bad"]}})"),
      QByteArray(R"({"format":"abyssal-panels","version":1,"layout":{"version":2,"monitors":{"*":{"panels":[{"items":[4]}]}}}})")}) {
    write(file, content);
    QVERIFY(s.importPreset("theme", QUrl::fromLocalFile(file)).isEmpty());
    QVERIFY(s.importPreset("panels", QUrl::fromLocalFile(file)).isEmpty());
    QCOMPARE(s.dirtyCount(), before);
    QCOMPARE(s.value("appearance", "theme"), selected);
  }
  QVERIFY(!s.setThemeColor("accent", "#80123456"));
  QVERIFY(!s.setThemeColor("not-a-role", "#123456"));
  QVERIFY(s.saveTheme("  ").isEmpty());
  QVERIFY(!s.loadPanelPreset("../../other"));
  QCOMPARE(s.dirtyCount(), before);
  const auto target = temp.path() + "/kept-export.json";
  const auto link = temp.path() + "/export-link.json";
  write(target, "keep me");
  QVERIFY(QFile::link(target, link));
  QVERIFY(!s.exportPreset("theme", "", QUrl::fromLocalFile(link)));
  QCOMPARE(read(target), QByteArray("keep me"));
  const auto editable = s.copyTheme("sample");
  s.setText("theme:" + editable, R"({"colors":{"base":"invalid"}})");
  QVERIFY(!s.exportPreset("theme", editable, QUrl::fromLocalFile(target)));
  QCOMPARE(read(target), QByteArray("keep me"));
}
