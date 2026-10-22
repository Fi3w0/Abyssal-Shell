#include "ConfigStore.h"
#include <QColor>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QRegularExpression>
#include <QSaveFile>

namespace {
const QStringList roles{"crust", "base",    "surface0", "surface1", "overlay",
                        "text",  "subtext", "accent",   "cyan",     "rose",
                        "warn",  "danger",  "success"};
}

QString ConfigStore::activeThemeId() const {
  return value("appearance", "fromWallpaper", false).toBool() &&
                 m_docs.contains("theme:wallpaper")
             ? "wallpaper"
             : value("appearance", "theme", "abyssal-tide").toString();
}

QString ConfigStore::editableTheme() {
  auto id = activeThemeId();
  if (!m_docs.contains("theme:" + id))
    return {};
  if (id == "wallpaper" || m_docs["theme:" + id].readOnly)
    id = copyTheme(id);
  return id;
}

bool ConfigStore::setThemeColor(QString key, QString color) {
  if (!roles.contains(key) || !QColor(color).isValid() ||
      QColor(color).alpha() != 255) {
    report("Choose an opaque colour in #RRGGBB format.");
    return false;
  }
  if (key == "accent")
    return setAccent(color);
  const auto id = editableTheme();
  if (id.isEmpty())
    return false;
  setValue("theme:" + id, "colors." + key, QColor(color).name());
  return true;
}

bool ConfigStore::setThemeOption(QString key, QVariant value) {
  if (!QStringList{"shape", "glass", "glassStrong", "radius.popup",
                   "radius.control"}
           .contains(key))
    return false;
  const auto id = editableTheme();
  if (id.isEmpty())
    return false;
  setValue("theme:" + id, key, value);
  return true;
}

QString ConfigStore::createPreset(QString kind, QString name,
                                  QJsonObject data) {
  name = name.trimmed();
  if (name.isEmpty() || name.size() > 80 ||
      name.contains(QRegularExpression("[\\x00-\\x1f\\x7f]"))) {
    report("Give the preset a name between 1 and 80 characters.");
    return {};
  }
  QString stem =
      name.toLower().replace(QRegularExpression("[^a-z0-9]+"), "-").left(48);
  if (stem.isEmpty() || stem == "-")
    stem = "preset";
  if (stem == "wallpaper")
    stem = "saved-wallpaper";
  const QString prefix = kind == "theme" ? "theme:" : "panel-preset:";
  const QString directory = kind == "theme" ? "themes" : "panel-presets";
  QString id = stem;
  int suffix = 2;
  auto occupied = [&] {
    const QFileInfo file(m_home + "/abyssal/" + directory + "/" + id + ".json");
    return m_docs.contains(prefix + id) || file.exists() || file.isSymLink();
  };
  while (occupied())
    id = stem + "-" + QString::number(suffix++);
  data["name"] = name;
  load(prefix + id, name,
       m_home + "/abyssal/" + directory + "/" + id + ".json");
  setText(prefix + id, QString::fromUtf8(QJsonDocument(data).toJson()));
  if (kind == "theme") {
    setValue("appearance", "theme", id);
    setValue("appearance", "fromWallpaper", false);
  }
  report("Preset added to your draft. Save changes to keep it.");
  return id;
}

QString ConfigStore::saveTheme(QString name) {
  const auto id = activeThemeId();
  if (!m_docs.contains("theme:" + id))
    return {};
  const auto data = json(m_docs["theme:" + id]);
  QString error;
  if (!validTheme(data, error)) {
    report(error);
    return {};
  }
  return createPreset("theme", name, data);
}

QVariantList ConfigStore::panelPresets() const {
  QVariantList result;
  for (const auto &d : m_docs)
    if (d.id.startsWith("panel-preset:")) {
      const auto data = json(d);
      QString error;
      if (!validLayout(data["layout"].toObject(), error))
        continue;
      result << QVariantMap{{"id", d.id.mid(13)},
                            {"name", data["name"].toString(d.label)},
                            {"layout", data["layout"].toVariant()}};
    }
  return result;
}

QString ConfigStore::savePanelPreset(QString name) {
  const auto data = json(m_docs.value("layout"));
  QString error;
  if (!validLayout(data, error)) {
    report(error);
    return {};
  }
  return createPreset(
      "panels", name,
      {{"format", "abyssal-panels"}, {"version", 1}, {"layout", data}});
}

bool ConfigStore::loadPanelPreset(QString id) {
  if (!m_docs.contains("panel-preset:" + id))
    return false;
  const auto layout = json(m_docs["panel-preset:" + id])["layout"].toObject();
  QString error;
  if (!validLayout(layout, error)) {
    report(error);
    return false;
  }
  setText("layout", QString::fromUtf8(QJsonDocument(layout).toJson()));
  report("Panel preset loaded into your draft. Save changes to apply it.");
  return true;
}

bool ConfigStore::validTheme(const QJsonObject &data, QString &error) {
  if (data.contains("name") &&
      (!data["name"].isString() ||
       data["name"].toString().trimmed().isEmpty() ||
       data["name"].toString().size() > 80 ||
       data["name"].toString().contains(
           QRegularExpression("[\\x00-\\x1f\\x7f]")))) {
    error = "A theme name must be a single line of 1 to 80 characters.";
    return false;
  }
  const auto colors = data["colors"].toObject();
  if (colors.isEmpty()) {
    error = "A theme needs a colours object.";
    return false;
  }
  for (auto it = colors.begin(); it != colors.end(); ++it)
    if (!it->isString() || !QColor(it->toString()).isValid() ||
        (roles.contains(it.key()) && QColor(it->toString()).alpha() != 255)) {
      error = "Invalid theme colour: " + it.key();
      return false;
    }
  if (data.contains("shape") &&
      !QStringList{"pill", "square"}.contains(data["shape"].toString())) {
    error = "Choose a pill or square theme shape.";
    return false;
  }
  for (const auto &key : {"glass", "glassStrong"})
    if (data.contains(key) &&
        (!data[key].isDouble() || data[key].toDouble() < 0 ||
         data[key].toDouble() > 1)) {
      error = "Theme opacity must be between 0 and 1.";
      return false;
    }
  if (data.contains("radius") && !data["radius"].isObject()) {
    error = "Theme radii must be an object.";
    return false;
  }
  const auto radius = data["radius"].toObject();
  for (const auto &key : {"popup", "control"})
    if (radius.contains(key) &&
        (!radius[key].isDouble() || radius[key].toDouble() < 0 ||
         radius[key].toDouble() > 80)) {
      error = "Theme corner radii must be between 0 and 80.";
      return false;
    }
  if (data.contains("tidewm") && !data["tidewm"].isObject()) {
    error = "Theme window colours must be an object.";
    return false;
  }
  const auto desktop = data["tidewm"].toObject();
  for (const auto &key : {"border", "inactive", "urgent"}) {
    if (!desktop.contains(key))
      continue;
    const auto pair = desktop[key].toArray();
    if (!desktop[key].isArray() || pair.size() != 2 || !pair[0].isString() ||
        !pair[1].isString() || !QColor(pair[0].toString()).isValid() ||
        !QColor(pair[1].toString()).isValid()) {
      error = "Window border gradients need two valid colours.";
      return false;
    }
  }
  for (const auto &key : {"shadow", "shadowInactive", "shadowUrgent"})
    if (desktop.contains(key) && (!desktop[key].isString() ||
                                  !QColor(desktop[key].toString()).isValid())) {
      error = "Invalid window shadow colour.";
      return false;
    }
  if (data.contains("backdrop") &&
      (!data["backdrop"].isObject() ||
       (data["backdrop"].toObject().contains("top") &&
        !QColor(data["backdrop"].toObject()["top"].toString()).isValid()))) {
    error = "Invalid backdrop colour.";
    return false;
  }
  return true;
}

bool ConfigStore::validLayout(const QJsonObject &data, QString &error) {
  auto fail = [&] {
    error = "Choose a version 2 panel layout with valid displays, panels and "
            "widgets.";
    return false;
  };
  if (data["version"].toInt() != 2 || !data["monitors"].isObject())
    return fail();
  const auto monitors = data["monitors"].toObject();
  for (auto it = monitors.begin(); it != monitors.end(); ++it) {
    if (it.key().isEmpty() || !it->isObject() ||
        !it->toObject()["panels"].isArray())
      return fail();
    for (const auto &entry : it->toObject()["panels"].toArray()) {
      if (!entry.isObject())
        return fail();
      const auto p = entry.toObject();
      const QMap<QString, QStringList> options{
          {"edge", {"top", "bottom", "left", "right"}},
          {"width", {"fill", "fit", "islands", "custom"}},
          {"align", {"start", "center", "end"}},
          {"look", {"glass", "solid"}},
          {"visibility", {"always", "autohide", "below"}}};
      for (auto choice = options.begin(); choice != options.end(); ++choice)
        if (p.contains(choice.key()) &&
            !choice.value().contains(p[choice.key()].toString()))
          return fail();
      for (const auto &key : {"size", "length"})
        if (p.contains(key) &&
            (!p[key].isDouble() || p[key].toDouble() < 1 ||
             p[key].toDouble() > (QString(key) == "size" ? 256 : 100)))
          return fail();
      if ((p.contains("floating") && !p["floating"].isBool()) ||
          !p["items"].isArray())
        return fail();
      for (const auto &item : p["items"].toArray())
        if (!(item.isString() && !item.toString().isEmpty()) &&
            !(item.isObject() && !item.toObject()["id"].toString().isEmpty()))
          return fail();
    }
  }
  return true;
}

QString ConfigStore::importPreset(QString kind, QUrl url) {
  if ((kind != "theme" && kind != "panels") || !url.isLocalFile()) {
    report("Choose a local theme or panel preset file.");
    return {};
  }
  QFile file(url.toLocalFile());
  if (!file.open(QIODevice::ReadOnly) || file.size() > 1024 * 1024) {
    report("Could not read the preset (maximum size: 1 MiB).");
    return {};
  }
  QJsonParseError parse;
  const auto document = QJsonDocument::fromJson(file.readAll(), &parse);
  const auto data = document.object();
  QString error;
  bool valid = parse.error == QJsonParseError::NoError && document.isObject();
  if (valid)
    valid = kind == "theme" ? validTheme(data, error)
                            : data["format"] == "abyssal-panels" &&
                                  data["version"].toInt() == 1 &&
                                  validLayout(data["layout"].toObject(), error);
  if (!valid) {
    report(error.isEmpty() ? "This file is not a valid " + kind + " preset."
                           : error);
    return {};
  }
  return createPreset(
      kind, data["name"].toString(QFileInfo(file).completeBaseName()), data);
}

bool ConfigStore::exportPreset(QString kind, QString id, QUrl url) {
  if ((kind != "theme" && kind != "panels") || !url.isLocalFile())
    return false;
  QJsonObject data;
  if (kind == "theme") {
    if (id.isEmpty())
      id = activeThemeId();
    if (!m_docs.contains("theme:" + id))
      return false;
    data = json(m_docs["theme:" + id]);
  } else if (id.isEmpty()) {
    data = {{"format", "abyssal-panels"},
            {"version", 1},
            {"name", "My panels"},
            {"layout", json(m_docs.value("layout"))}};
  } else {
    if (!m_docs.contains("panel-preset:" + id))
      return false;
    data = json(m_docs["panel-preset:" + id]);
  }
  QString error;
  if (!(kind == "theme" ? validTheme(data, error)
                        : validLayout(data["layout"].toObject(), error))) {
    report(error);
    return false;
  }
  const QString path = url.toLocalFile();
  if (QFileInfo(path).isSymLink()) {
    report("Choose a regular file for the export.");
    return false;
  }
  QSaveFile file(path);
  const auto bytes = QJsonDocument(data).toJson();
  if (!file.open(QIODevice::WriteOnly) || file.write(bytes) != bytes.size() ||
      !file.commit()) {
    report("Could not export the preset: " + file.errorString());
    return false;
  }
  report("Exported preset to " + path);
  return true;
}
