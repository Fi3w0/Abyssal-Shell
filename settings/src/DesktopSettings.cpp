#include "ConfigStore.h"
#include "WaveSettings.h"
#include <QColor>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QKeySequence>
#include <QRegularExpression>
#include <QSet>
#include <QSettings>
#include <QStandardPaths>
#include <QXmlStreamReader>
#include <algorithm>
#include <cmath>
#include <functional>

QVariantList ConfigStore::desktopPages() const {
  static const auto pages = [] {
    QFile file(":/registry/desktop.json");
    if (!file.open(QIODevice::ReadOnly))
      return QVariantList{};
    return QJsonDocument::fromJson(file.readAll()).array().toVariantList();
  }();
  return pages;
}
static QVariantMap definition(const QVariantList &pages, const QString &key) {
  for (const auto &p : pages)
    for (const auto &g : p.toMap()["groups"].toList())
      for (const auto &r : g.toMap()["rows"].toList())
        if (r.toMap()["key"] == key)
          return r.toMap();
  return {};
}
bool ConfigStore::desktopEditable() const { return !waveValidator().isEmpty(); }
QString ConfigStore::waveValidator() {
  auto found = QStandardPaths::findExecutable("wavefmt");
  if (!found.isEmpty())
    return found;
  const auto local = QDir::homePath() + "/.local/bin/wavefmt";
  return QFileInfo(local).isExecutable() ? local : QString();
}
static QString resolveInclude(const QString &from, QString path) {
  if (path.startsWith("~/"))
    path = QDir::homePath() + path.mid(1);
  return QDir::cleanPath(
      QDir::isRelativePath(path) ? QFileInfo(from).dir().filePath(path) : path);
}
QVariant ConfigStore::desktopValue(QString key, QVariant fallback) const {
  fallback = fromUi(fallback);
  if (!m_waveCacheValid) {
    m_waveValues.clear();
    QStringList visiting;
    std::function<void(QString, int)> visit = [&](QString path, int depth) {
      if (depth > 12 || visiting.contains(path))
        return;
      const auto id = "wave:" + path;
      QString resolvedId = id;
      if (!m_docs.contains(resolvedId)) {
        const auto canonical = QFileInfo(path).canonicalFilePath();
        for (const auto &doc : m_docs)
          if (!canonical.isEmpty() && doc.target == canonical) {
            resolvedId = doc.id;
            break;
          }
      }
      if (!m_docs.contains(resolvedId))
        return;
      visiting << path;
      const auto entries = WaveSettings::scan(m_docs[resolvedId].draft).entries;
      // TideWM resolves all includes first; this file's own entries win,
      // regardless of where its include statements appear.
      for (const auto &entry : entries)
        if (!entry.include.isEmpty())
          visit(resolveInclude(path, entry.include), depth + 1);
      QSet<int> animationBlocks;
      for (const auto &entry : entries) {
        if (entry.key.startsWith("animations.") &&
            !animationBlocks.contains(entry.blockLine)) {
          animationBlocks.insert(entry.blockLine);
          for (const auto &preset : entries) {
            if (preset.key != "animations.preset" ||
                preset.blockLine != entry.blockLine)
              continue;
            auto name = preset.value;
            name.remove('"');
            name.remove('\'');
            const auto values =
                definition(desktopPages(), "animations.preset")["presetValues"]
                    .toMap()
                    .value(name)
                    .toMap();
            if (values.isEmpty())
              continue;
            for (auto it = m_waveValues.begin(); it != m_waveValues.end();) {
              if (it.key().startsWith("animations."))
                it = m_waveValues.erase(it);
              else
                ++it;
            }
            for (auto it = values.cbegin(); it != values.cend(); ++it)
              m_waveValues["animations." + it.key()] = it.value().toString();
          }
        }
        if (entry.include.isEmpty())
          m_waveValues[entry.key] = entry.value;
      }
      visiting.removeLast();
    };
    visit(m_home + "/tidewm/config.wave", 0);
    m_waveCacheValid = true;
  }
  if (!m_waveValues.contains(key))
    return fallback;
  auto value = m_waveValues[key].trimmed();
  const auto spec = definition(desktopPages(), key);
  const auto kind = spec["kind"].toString();
  if (key == "scroll.center_focused") {
    if (value == "true")
      return "always";
    if (value == "false")
      return "never";
  }
  if (kind == "bool") {
    if (value == "true")
      return true;
    if (value == "false")
      return false;
    return fallback;
  }
  if (kind == "number" || kind == "slider") {
    const bool seconds = value.endsWith('s') && !value.endsWith("ms");
    if (spec["suffix"] == "ms")
      value.remove(QRegularExpression("(?:ms|s)$"));
    bool ok;
    const auto number = value.toDouble(&ok);
    return ok ? QVariant(number * (seconds ? 1000 : 1)) : fallback;
  }
  if (kind == "presets") {
    const auto parsed = QJsonDocument::fromJson(value.toUtf8());
    return parsed.isArray() ? parsed.array().toVariantList() : fallback;
  }
  if (value.startsWith('"') || value.startsWith('\''))
    return value.mid(1, value.size() - 2);
  return value.contains('{') || value.contains('(') ? fallback
                                                    : QVariant(value);
}
bool ConfigStore::setDesktopValue(QString key, QVariant value) {
  value = fromUi(value);
  const auto spec = definition(desktopPages(), key);
  if (spec.isEmpty() || !desktopEditable()) {
    report("Desktop settings need TideWM's configuration validator (wavefmt).");
    return false;
  }
  const auto mainPath = m_home + "/tidewm/config.wave";
  const auto managedPath = m_home + "/tidewm/abyssal-settings.wave";
  const auto main = "wave:" + mainPath, managed = "wave:" + managedPath;
  if (spec["deviceDefault"].toBool() && value.toString() == "device-default") {
    auto originals =
        this->value("settings", "desktopOriginal", QVariantMap{}).toMap();
    if (originals.contains(key) && m_docs.contains(main)) {
      const auto saved = originals[key].toMap();
      if (saved["existed"].toBool())
        setText(main, WaveSettings::set(m_docs[main].draft, key,
                                        saved["value"].toString()));
      else {
        auto lines = m_docs[main].draft.split('\n');
        const auto entries = WaveSettings::scan(m_docs[main].draft).entries;
        for (auto it = entries.crbegin(); it != entries.crend(); ++it)
          if (it->key == key)
            lines.removeAt(it->line);
        setText(main, lines.join('\n'));
      }
      originals.remove(key);
      setValue("settings", "desktopOriginal", originals);
    }
    if (m_docs.contains(managed)) {
      auto lines = m_docs[managed].draft.split('\n');
      const auto entries = WaveSettings::scan(m_docs[managed].draft).entries;
      for (auto it = entries.crbegin(); it != entries.crend(); ++it)
        if (it->key == key)
          lines.removeAt(it->line);
      setText(managed, lines.join('\n'));
    }
    return true;
  }
  QString encoded;
  const auto kind = spec["kind"].toString();
  if (kind == "bool") {
    if (value.metaType().id() != QMetaType::Bool)
      return false;
    encoded = value.toBool() ? "true" : "false";
  } else if (kind == "number" || kind == "slider") {
    bool ok;
    auto n = value.toDouble(&ok);
    const auto scale = spec.value("scale", 1).toDouble();
    if (!ok || !std::isfinite(n) || n * scale < spec["min"].toDouble() - 1e-6 ||
        n * scale > spec["max"].toDouble() + 1e-6 ||
        (kind == "number" && std::floor(n) != n))
      return false;
    encoded = QString::number(n, 'g', 12) + spec["suffix"].toString();
  } else if (kind == "presets") {
    const auto list = value.toList();
    if (list.isEmpty() || list.size() > 16)
      return false;
    double previous = 0;
    for (const auto &entry : list) {
      bool ok;
      const auto n = entry.toDouble(&ok);
      if (!ok || !std::isfinite(n) || n < .1 || n > 1 || n <= previous)
        return false;
      previous = n;
    }
    encoded = QString::fromUtf8(QJsonDocument(QJsonArray::fromVariantList(list))
                                    .toJson(QJsonDocument::Compact));
  } else if (kind == "layouts") {
    if (!QRegularExpression("^[a-zA-Z0-9_-]+(?:,[a-zA-Z0-9_-]+)*$")
             .match(value.toString())
             .hasMatch())
      return false;
    encoded = '"' + value.toString() + '"';
  } else {
    bool found = false;
    for (const auto &c : spec["choices"].toList())
      if (c.toMap()["value"] == value)
        found = true;
    if (!found)
      return false;
    encoded = value.toString();
  }
  if (!m_docs.contains(main)) {
    load(main, "config.wave", mainPath);
    if (!m_docs[main].existed)
      m_docs[main].draft.clear();
  }
  const auto scan = WaveSettings::scan(m_docs[main].draft);
  const auto top = key.section('.', 0, 0);
  bool inParent = scan.closingLines.contains(top);
  for (const auto &entry : scan.entries)
    if (entry.key == key)
      inParent = true;
  const auto target = inParent ? main : managed;
  if (!m_docs.contains(target)) {
    load(target, "abyssal-settings.wave", managedPath);
    if (!m_docs[target].existed)
      m_docs[target].draft =
          "# Desktop preferences managed by Abyssal Settings.\n";
  }
  if (m_docs[main].readOnly || m_docs[target].readOnly) {
    report(
        "The desktop preferences are not readable or writable by this user.");
    return false;
  }
  // Keep a reversible baseline when an existing parent device block has to be
  // edited. Restore removes only our override and retains all unrelated text.
  if (inParent && spec["deviceDefault"].toBool()) {
    auto originals =
        this->value("settings", "desktopOriginal", QVariantMap{}).toMap();
    if (!originals.contains(key)) {
      QVariantMap saved{{"existed", false}};
      for (const auto &entry : scan.entries)
        if (entry.key == key)
          saved = {{"existed", true}, {"value", entry.value}};
      originals[key] = saved;
      setValue("settings", "desktopOriginal", originals);
      if (this->value("settings", "desktopOriginal").toMap() != originals)
        return false;
    }
  }
  if (!inParent) {
    auto lines = m_docs[main].draft.split('\n');
    for (auto it = scan.entries.crbegin(); it != scan.entries.crend(); ++it)
      if (!it->include.isEmpty() &&
          resolveInclude(mainPath, it->include) == managedPath)
        lines.removeAt(it->line);
    auto text = lines.join('\n');
    if (!text.endsWith('\n') && !text.isEmpty())
      text += '\n';
    m_docs[main].draft = text + "include \"abyssal-settings.wave\"\n";
  }
  auto source = m_docs[target].draft;
  if (key == "animations.preset") {
    auto lines = source.split('\n');
    const auto entries = WaveSettings::scan(source).entries;
    for (auto it = entries.crbegin(); it != entries.crend(); ++it)
      if (it->key.startsWith("animations.") && it->key != key &&
          !definition(desktopPages(), it->key).isEmpty())
        lines.removeAt(it->line);
    source = lines.join('\n');
  }
  m_docs[target].draft = WaveSettings::set(source, key, encoded);
  m_waveCacheValid = false;
  // A later preset block can reset a value in an earlier block. Append a
  // final narrow override only when replacing the existing line would lose.
  const auto actual = desktopValue(key);
  const bool matches =
      (kind == "slider" || kind == "number")
          ? std::abs(actual.toDouble() - value.toDouble()) < 1e-6
          : actual == value;
  if (!matches) {
    auto &draft = m_docs[target].draft;
    if (!draft.endsWith('\n'))
      draft += '\n';
    draft += WaveSettings::set({}, key, encoded);
    m_waveCacheValid = false;
  }
  emit changed();
  report("Desktop preference ready. Save changes to apply it.");
  return true;
}
QVariantList ConfigStore::keyboardLayouts() const {
  QVariantList result;
  QStringList roots{qEnvironmentVariable("XKB_CONFIG_ROOT"),
                    "/usr/share/X11/xkb", "/usr/local/share/X11/xkb"};
  for (const auto &root : roots) {
    if (root.isEmpty())
      continue;
    QFile file(root + "/rules/evdev.xml");
    if (!file.open(QIODevice::ReadOnly))
      continue;
    QXmlStreamReader xml(&file);
    while (!xml.atEnd()) {
      xml.readNext();
      if (!xml.isStartElement() || xml.name() != QLatin1String("layout"))
        continue;
      QString name, label;
      while (xml.readNextStartElement()) {
        if (xml.name() != QLatin1String("configItem")) {
          xml.skipCurrentElement();
          continue;
        }
        while (xml.readNextStartElement()) {
          if (xml.name() == QLatin1String("name"))
            name = xml.readElementText();
          else if (xml.name() == QLatin1String("description"))
            label = xml.readElementText();
          else
            xml.skipCurrentElement();
        }
      }
      if (!name.isEmpty())
        result << QVariantMap{{"value", name}, {"label", label}};
    }
    if (!result.isEmpty())
      break;
  }
  if (result.isEmpty())
    result << QVariantMap{{"value", "us"}, {"label", "English (US)"}};
  return result;
}
bool ConfigStore::setAccent(QString color) {
  if (!QColor(color).isValid())
    return false;
  auto id = value("appearance", "fromWallpaper", false).toBool()
                ? "wallpaper"
                : value("appearance", "theme", "abyssal-tide").toString();
  if (!m_docs.contains("theme:" + id))
    return false;
  if (id == "wallpaper" || m_docs["theme:" + id].readOnly)
    id = copyTheme(id);
  if (id.isEmpty())
    return false;
  setValue("appearance", "theme", id);
  setValue("appearance", "fromWallpaper", false);
  setValue("theme:" + id, "colors.accent", QColor(color).name());
  // Derived accent surfaces must follow the new accent rather than keep an
  // old hand-picked colour from the source palette.
  auto theme = json(m_docs["theme:" + id]);
  auto colors = theme["colors"].toObject();
  colors.remove("accentSoft");
  colors.remove("controlEdge");
  theme["colors"] = colors;
  auto desktop = theme["tidewm"].toObject();
  desktop["border"] = QJsonArray{QColor(color).name(), QColor(color).name()};
  const QColor accent(color), crust(colors["crust"].toString());
  const auto shadow =
      crust.isValid()
          ? QColor::fromRgbF(accent.redF() * .3 + crust.redF() * .7,
                             accent.greenF() * .3 + crust.greenF() * .7,
                             accent.blueF() * .3 + crust.blueF() * .7)
          : accent;
  desktop["shadow"] = shadow.name() + "b0";
  theme["tidewm"] = desktop;
  setText("theme:" + id, QString::fromUtf8(QJsonDocument(theme).toJson()));
  return true;
}

QVariantList ConfigStore::applications() const {
  QVariantList result;
  if (QStandardPaths::findExecutable("gio").isEmpty())
    return result;
  QSet<QString> seen;
  for (const auto &directory : QStandardPaths::standardLocations(
           QStandardPaths::ApplicationsLocation)) {
    QDirIterator files(directory, {"*.desktop"}, QDir::Files,
                       QDirIterator::Subdirectories);
    while (files.hasNext()) {
      const auto path = files.next();
      const auto id = QDir(directory).relativeFilePath(path).replace('/', '-');
      if (seen.contains(id))
        continue;
      seen.insert(id);
      QSettings entry(path, QSettings::IniFormat);
      entry.beginGroup("Desktop Entry");
      if (entry.value("Hidden").toBool() || entry.value("NoDisplay").toBool() ||
          entry.value("Type").toString() != "Application")
        continue;
      auto escaped = path;
      escaped.replace('\\', "\\\\").replace('"', "\\\"");
      result << QVariantMap{{"command", entry.value("Exec").toString()},
                            {"value", "spawn:gio launch \"" + escaped + "\""},
                            {"label", entry.value("Name", id).toString()}};
    }
  }
  std::sort(result.begin(), result.end(),
            [](const QVariant &a, const QVariant &b) {
              return a.toMap()["label"].toString().localeAwareCompare(
                         b.toMap()["label"].toString()) < 0;
            });
  return result;
}
QString ConfigStore::shortcutName(int key, int modifiers) const {
  if (key == Qt::Key_Shift || key == Qt::Key_Control || key == Qt::Key_Meta ||
      key == Qt::Key_Alt || key == Qt::Key_AltGr || key == Qt::Key_unknown)
    return {};
  return QKeySequence(
             QKeyCombination(Qt::KeyboardModifiers(modifiers), Qt::Key(key)))
      .toString(QKeySequence::PortableText)
      .replace("Meta+", "Super+");
}
