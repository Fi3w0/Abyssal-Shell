#include "ConfigStore.h"
#include <QColor>
#include <QCoreApplication>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJSValue>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QProcess>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSet>
#include <QStandardPaths>
#include <QSysInfo>
#include <QTemporaryDir>
#include <QTemporaryFile>
#include <QUrl>
#include <algorithm>
#include <cmath>
#include <fcntl.h>
#include <pwd.h>
#include <sys/stat.h>
#include <unistd.h>

QString ConfigStore::read(QString path) {
  QFile f(path);
  return f.open(QIODevice::ReadOnly) ? QString::fromUtf8(f.readAll())
                                     : QString();
}
QVariant ConfigStore::fromUi(QVariant value) {
  if (value.metaType().id() == qMetaTypeId<QJSValue>())
    value = value.value<QJSValue>().toVariant();
  if (value.metaType().id() == QMetaType::QVariantList) {
    auto list = value.toList();
    for (auto &entry : list)
      entry = fromUi(entry);
    return list;
  }
  if (value.metaType().id() == QMetaType::QVariantMap) {
    auto map = value.toMap();
    for (auto it = map.begin(); it != map.end(); ++it)
      it.value() = fromUi(it.value());
    return map;
  }
  return value;
}
ConfigStore::ConfigStore(QString root, QObject *parent)
    : QObject(parent), m_root(root) {
  m_home =
      QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
  m_state = qEnvironmentVariable("XDG_STATE_HOME",
                                 QDir::homePath() + "/.local/state") +
            "/abyssal/settings-backups";
  m_externalTimer.setSingleShot(true);
  m_externalTimer.setInterval(120);
  connect(&m_watcher, &QFileSystemWatcher::fileChanged, this,
          [this] { m_externalTimer.start(); });
  connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this,
          [this] { m_externalTimer.start(); });
  connect(&m_externalTimer, &QTimer::timeout, this, [this] {
    if (!dirtyCount())
      reload();
    else {
      m_externalChange = true;
      emit changed();
    }
  });
  reload();
}
void ConfigStore::report(QString s) {
  m_message = s;
  emit messageChanged();
}
void ConfigStore::load(QString id, QString label, QString path, bool readonly) {
  QFileInfo info(path);
  Document d;
  d.id = id;
  d.label = label;
  d.path = path;
  d.existed = info.exists();
  d.target = d.existed ? info.canonicalFilePath() : info.absoluteFilePath();
  d.original = d.existed ? read(path) : QString();
  d.draft = d.existed ? d.original : QStringLiteral("{}\n");
  d.readOnly =
      readonly || (d.existed && (!info.isReadable() || d.target.isEmpty()));
  m_docs[id] = d;
}
void ConfigStore::loadWave(QString path, int depth) {
  if (depth > 12 || m_docs.size() > 100 || !QFileInfo::exists(path))
    return;
  QString target = QFileInfo(path).canonicalFilePath();
  for (const auto &d : m_docs)
    if (d.target == target)
      return;
  QString id = "wave:" + QFileInfo(path).absoluteFilePath();
  load(id, QFileInfo(path).fileName(), path,
       QFileInfo(path).fileName() == "theme.wave");
  const QRegularExpression pattern(R"re(^\s*include\s+["']([^"']+)["'])re",
                                   QRegularExpression::MultilineOption);
  auto matches = pattern.globalMatch(read(path));
  while (matches.hasNext()) {
    QString p = matches.next().captured(1);
    if (p.startsWith("~/"))
      p = QDir::homePath() + p.mid(1);
    if (QDir::isRelativePath(p))
      p = QFileInfo(path).dir().filePath(p);
    if (p.endsWith(".wave"))
      loadWave(QDir::cleanPath(p), depth + 1);
  }
}
void ConfigStore::reload() {
  m_waveCacheValid = false;
  m_externalChange = false;
  m_docs.clear();
  for (QString id : {"appearance", "wallpaper", "layout", "updates", "idle",
                     "notifications", "profile", "autostart", "settings"})
    load(id, id.left(1).toUpper() + id.mid(1),
         m_home + "/abyssal/" + id + ".json");
  QDir shipped(m_root + "/themes"), user(m_home + "/abyssal/themes");
  for (QString name : shipped.entryList({"*.json"}, QDir::Files))
    load("theme:" + QFileInfo(name).completeBaseName(),
         QFileInfo(name).completeBaseName(), shipped.filePath(name), true);
  for (QString name : user.entryList({"*.json"}, QDir::Files))
    load("theme:" + QFileInfo(name).completeBaseName(),
         QFileInfo(name).completeBaseName(), user.filePath(name));
  loadWave(m_home + "/tidewm/config.wave");
  QDir panels(m_home + "/abyssal/panel-presets");
  for (const auto &name : panels.entryList({"*.json"}, QDir::Files))
    load("panel-preset:" + QFileInfo(name).completeBaseName(),
         QFileInfo(name).completeBaseName(), panels.filePath(name));
  if (!m_watcher.files().isEmpty())
    m_watcher.removePaths(m_watcher.files());
  if (!m_watcher.directories().isEmpty())
    m_watcher.removePaths(m_watcher.directories());
  QStringList watched;
  for (const auto &d : m_docs)
    if (QFileInfo::exists(d.path))
      watched << d.path;
  for (const auto &path :
       {m_home + "/abyssal", m_home + "/abyssal/themes",
        m_home + "/abyssal/panel-presets", m_home + "/tidewm"})
    if (QFileInfo::exists(path))
      watched << path;
  if (!watched.isEmpty())
    m_watcher.addPaths(watched);
  emit changed();
  report("Configuration loaded. Changes stay in a draft until you apply them.");
}
QJsonObject ConfigStore::json(const Document &d) {
  return QJsonDocument::fromJson(d.draft.toUtf8()).object();
}
QVariantList ConfigStore::documents() const {
  QVariantList list;
  for (const auto &d : m_docs)
    list.append(
        QVariantMap{{"id", d.id},
                    {"label", d.label},
                    {"path", d.path},
                    {"readOnly", d.readOnly},
                    {"dirty", d.draft != (d.existed ? d.original : "{}\n")}});
  return list;
}
int ConfigStore::dirtyCount() const {
  int n = 0;
  for (const auto &d : m_docs)
    if (d.draft != (d.existed ? d.original : "{}\n"))
      ++n;
  return n;
}
QVariant ConfigStore::value(QString id, QString key, QVariant fallback) const {
  fallback = fromUi(fallback);
  if (!m_docs.contains(id))
    return fallback;
  QJsonValue v = json(m_docs[id]);
  for (const auto &part : key.split('.', Qt::SkipEmptyParts)) {
    if (v.isArray()) {
      bool ok;
      int i = part.toInt(&ok);
      v = ok ? v.toArray().at(i) : QJsonValue();
    } else
      v = v.toObject().value(part);
  }
  return v.isUndefined() || v.isNull() ? fallback : v.toVariant();
}
static QJsonValue put(QJsonValue current, const QStringList &parts, int at,
                      QJsonValue value) {
  if (at == parts.size())
    return value;
  bool index = false;
  int n = parts[at].toInt(&index);
  if (current.isArray() && index) {
    QJsonArray a = current.toArray();
    if (n >= 0 && n < a.size())
      a[n] = put(a[n], parts, at + 1, value);
    return a;
  }
  QJsonObject obj = current.toObject();
  obj[parts[at]] = put(obj[parts[at]], parts, at + 1, value);
  return obj;
}
void ConfigStore::setValue(QString id, QString key, QVariant value) {
  value = fromUi(value);
  if (!m_docs.contains(id) || m_docs[id].readOnly)
    return;
  QJsonParseError error;
  auto parsed = QJsonDocument::fromJson(m_docs[id].draft.toUtf8(), &error);
  if (error.error != QJsonParseError::NoError || !parsed.isObject()) {
    report("Fix the JSON syntax in " + m_docs[id].label +
           " before editing its controls.");
    return;
  }
  auto obj =
      put(parsed.object(), key.split('.'), 0, QJsonValue::fromVariant(value))
          .toObject();
  m_docs[id].draft = QString::fromUtf8(QJsonDocument(obj).toJson());
  emit changed();
}
QString ConfigStore::text(QString id) const { return m_docs.value(id).draft; }
void ConfigStore::setText(QString id, QString t) {
  if (m_docs.contains(id) && !m_docs[id].readOnly && m_docs[id].draft != t) {
    m_docs[id].draft = t;
    m_waveCacheValid = false;
    emit changed();
  }
}
void ConfigStore::resetAppLook() {
  QJsonParseError error;
  const auto parsed =
      QJsonDocument::fromJson(m_docs["settings"].draft.toUtf8(), &error);
  if (error.error != QJsonParseError::NoError || !parsed.isObject()) {
    report("Fix the settings JSON syntax before resetting the app's look.");
    return;
  }
  auto object = parsed.object();
  for (const auto &key :
       {"backgroundStyle", "backgroundTop", "backgroundBottom", "windowOpacity",
        "shafts", "snow", "drift", "glass", "glowStrength", "glowSource",
        "selectionStyle", "density", "font", "corners", "reduceMotion"})
    object.remove(key);
  setText("settings", QString::fromUtf8(QJsonDocument(object).toJson()));
}
QVariantList ConfigStore::themes() const {
  QVariantList list;
  for (const auto &d : m_docs)
    if (d.id.startsWith("theme:")) {
      auto o = json(d);
      list.append(QVariantMap{{"id", d.id.mid(6)},
                              {"name", o.value("name").toString(d.label)},
                              {"colors", o.value("colors").toVariant()},
                              {"readOnly", d.readOnly}});
    }
  return list;
}
QVariantList ConfigStore::bindings() const {
  QVariantList list;
  const QRegularExpression rx(
      R"re(^\s*bind\s+([^\s{]+)\s*\{\s*(.*?)\s*\}\s*(?:#.*)?$)re");
  for (const auto &d : m_docs)
    if (d.id.startsWith("wave:")) {
      int line = 0;
      for (const auto &s : d.draft.split('\n')) {
        auto m = rx.match(s);
        if (m.hasMatch()) {
          QString action = m.captured(2);
          if (action.startsWith('"') && action.endsWith('"')) {
            auto parsed =
                QJsonDocument::fromJson(("[" + action + "]").toUtf8()).array();
            action = parsed.isEmpty() ? action.mid(1, action.size() - 2)
                                      : parsed.first().toString();
          }
          list.append(QVariantMap{{"id", d.id},
                                  {"file", d.label},
                                  {"line", line},
                                  {"chord", m.captured(1)},
                                  {"action", action},
                                  {"readOnly", d.readOnly}});
        }
        ++line;
      }
    }
  return list;
}
bool ConfigStore::setBinding(QString id, int line, QString chord,
                             QString action) {
  if (!m_docs.contains(id) || m_docs[id].readOnly)
    return false;
  if (!QRegularExpression(R"re(^[^\s{}"#]+$)re").match(chord).hasMatch() ||
      action.trimmed().isEmpty() || action.contains('\n') ||
      action.contains('\r')) {
    report("Enter one shortcut and a single-line TideWM action.");
    return false;
  }
  for (const auto &v : bindings()) {
    auto b = v.toMap();
    if (b["chord"].toString().compare(chord, Qt::CaseInsensitive) == 0 &&
        !(b["id"] == id && b["line"] == line)) {
      report("That shortcut is already assigned in " + b["file"].toString());
      return false;
    }
  }
  auto lines = m_docs[id].draft.split('\n');
  if (line < -1 || line >= lines.size())
    return false;
  if (line == -1) {
    line = lines.size();
    lines.append("");
  }
  auto old = lines[line];
  int hash = old.indexOf("} #");
  QString comment = hash >= 0 ? old.mid(hash + 1) : QString();
  action.replace('\\', "\\\\");
  action.replace('"', "\\\"");
  lines[line] = "bind " + chord + " { \"" + action + "\" }" + comment;
  setText(id, lines.join('\n'));
  return true;
}
bool ConfigStore::addShortcut(QString chord, QString action) {
  const auto path = m_home + "/tidewm/config.wave", id = "wave:" + path;
  if (!m_docs.contains(id)) {
    load(id, "config.wave", path);
    if (!m_docs[id].existed)
      m_docs[id].draft.clear();
  }
  return setBinding(id, -1, chord, action);
}
void ConfigStore::setAutostart(QVariantList apps) {
  apps = fromUi(apps).toList();
  QString main = "wave:" + m_home + "/tidewm/config.wave";
  if (!m_docs.contains(main)) {
    load(main, "config.wave", m_home + "/tidewm/config.wave");
    if (!m_docs[main].existed)
      m_docs[main].draft.clear();
  }
  QJsonArray commands;
  QSet<QString> seen;
  for (const auto &app : apps) {
    auto a = app.toMap();
    QString c = a.value("command").toString().trimmed();
    if (c.isEmpty() || c.contains('\n') || c.contains('\r')) {
      report("Each startup entry needs a single-line command.");
      return;
    }
    if (a.value("enabled", true).toBool()) {
      if (seen.contains(c)) {
        report("That startup command is already in the list.");
        return;
      }
      seen.insert(c);
      commands.append(c);
    }
  }
  QString path = m_home + "/tidewm/abyssal-autostart.wave", id = "wave:" + path;
  if (!m_docs.contains(id))
    load(id, "abyssal-autostart.wave", path);
  setValue("autostart", "apps", apps);
  setText(id, "# Managed by Abyssal Settings. Existing config.wave startup "
              "entries stay intact.\nspawn = " +
                  QString::fromUtf8(
                      QJsonDocument(commands).toJson(QJsonDocument::Compact)) +
                  "\n");
  if (!m_docs[main].draft.contains(QRegularExpression(
          R"re(^\s*include\s+["'](?:.*/)?abyssal-autostart\.wave["'])re",
          QRegularExpression::MultilineOption)))
    setText(main, m_docs[main].draft +
                      "\n# Additional startup apps, managed by Abyssal "
                      "Settings.\ninclude \"abyssal-autostart.wave\"\n");
}
QVariantMap ConfigStore::account() const {
  const passwd *pw = getpwuid(getuid());
  QString login =
      pw ? QString::fromLocal8Bit(pw->pw_name) : qEnvironmentVariable("USER");
  return {{"login", login},
          {"name", pw ? QString::fromLocal8Bit(pw->pw_gecos).section(',', 0, 0)
                      : login},
          {"home", QDir::homePath()},
          {"avatar", QFileInfo::exists(QDir::homePath() + "/.face.icon")
                         ? QDir::homePath() + "/.face.icon"
                     : QFileInfo::exists(QDir::homePath() + "/.face")
                         ? QDir::homePath() + "/.face"
                         : ""},
          {"host", QSysInfo::machineHostName()}};
}
QString ConfigStore::copyTheme(QString id) {
  if (!m_docs.contains("theme:" + id))
    return {};
  QString next = "custom-" + id;
  int n = 2;
  while (m_docs.contains("theme:" + next))
    next = "custom-" + id + "-" + QString::number(n++);
  load("theme:" + next, "Custom theme",
       m_home + "/abyssal/themes/" + next + ".json");
  auto o = json(m_docs["theme:" + id]);
  o["name"] = o.value("name").toString() + " · Custom";
  m_docs["theme:" + next].draft = QString::fromUtf8(QJsonDocument(o).toJson());
  setValue("appearance", "theme", next);
  setValue("appearance", "fromWallpaper", false);
  emit changed();
  return next;
}
bool ConfigStore::unchanged(const Document &d) const {
  QFileInfo info(d.path);
  return info.exists() == d.existed &&
         (!d.existed ||
          (info.canonicalFilePath() == d.target && read(d.path) == d.original));
}
bool ConfigStore::validate(const Document &d, QString &error) const {
  if (d.id.startsWith("wave:")) {
    QString fmt = waveValidator();
    if (fmt.isEmpty()) {
      error = "Install TideWM's wavefmt to validate compositor files before "
              "applying.";
      return false;
    }
    QTemporaryFile temp;
    if (!temp.open() ||
        temp.write(d.draft.toUtf8()) != d.draft.toUtf8().size() ||
        !temp.flush()) {
      error = "Could not prepare the Wave syntax check.";
      return false;
    }
    QProcess p;
    p.start(fmt, {temp.fileName()});
    if (!p.waitForFinished(5000) || p.exitStatus() != QProcess::NormalExit ||
        p.exitCode() != 0) {
      error =
          "Wave syntax error in " + d.label + ": " + p.readAllStandardError();
      return false;
    }
  } else {
    QJsonParseError e;
    auto doc = QJsonDocument::fromJson(d.draft.toUtf8(), &e);
    if (e.error != QJsonParseError::NoError || !doc.isObject()) {
      error = "Invalid JSON object in " + d.label + ": " + e.errorString();
      return false;
    }
    const auto o = doc.object();
    if (d.id.startsWith("theme:") && !validTheme(o, error))
      return false;
    if (d.id == "layout" && !o.isEmpty() && !validLayout(o, error))
      return false;
    if (d.id.startsWith("panel-preset:") &&
        !validLayout(o["layout"].toObject(), error))
      return false;
    auto number = [&](QString key, double minimum, double maximum,
                      bool integer = true) {
      if (!o.contains(key))
        return true;
      auto v = o[key];
      double n = v.toDouble(-1e300);
      if (!v.isDouble() || !std::isfinite(n) || n < minimum || n > maximum ||
          (integer && std::floor(n) != n)) {
        error = "Invalid " + key + " in " + d.label;
        return false;
      }
      return true;
    };
    QStringList booleans, strings;
    if (d.id == "updates") {
      if (!number("intervalMinutes", 0, 10080))
        return false;
      booleans = {"flatpak", "onStartup", "afterTransactions", "includeAur"};
      strings = {"manager", "aurHelper", "dnfRepoMode"};
    } else if (d.id == "appearance") {
      booleans = {"mono", "fromWallpaper"};
      strings = {"theme", "preset"};
    } else if (d.id == "settings") {
      if (!number("windowOpacity", 40, 100, false) ||
          !number("shafts", 0, 100, false) || !number("snow", 0, 100, false) ||
          !number("glass", 0, 15, false) ||
          !number("glowStrength", 0, 40, false))
        return false;
      const QMap<QString, QStringList> options{
          {"backgroundStyle", {"theme", "solid", "custom", "wallpaper"}},
          {"glowSource", {"cyan", "accent", "rose"}},
          {"selectionStyle", {"edge", "filled", "underline"}},
          {"density", {"compact", "normal", "roomy"}}};
      for (auto it = options.cbegin(); it != options.cend(); ++it)
        if (o.contains(it.key()) &&
            !it.value().contains(o[it.key()].toString())) {
          error = "Invalid " + it.key() + " in " + d.label;
          return false;
        }
      for (const auto &key : {"backgroundTop", "backgroundBottom"})
        if (o.contains(key) &&
            (!o[key].isString() || !QColor(o[key].toString()).isValid())) {
          error = "Invalid background colour in " + d.label;
          return false;
        }
      booleans = {"drift", "corners", "reduceMotion"};
      strings = {"font"};
    } else if (d.id == "profile")
      strings = {"displayName", "avatar"};
    else if (d.id == "wallpaper") {
      if (!number("transitionDuration", 0, 3, false))
        return false;
      strings = {"transition", "transitionPreset", "imageBackend"};
      if (o.contains("screens") && !o["screens"].isObject()) {
        error = "Wallpaper screens must be an object.";
        return false;
      }
    } else if (d.id == "idle") {
      if (!number("blank", 0, 10080) || !number("lock", 0, 10080))
        return false;
    } else if (d.id == "notifications") {
      if (!number("toastDuration", 1000, 30000) || !number("maxToasts", 1, 10))
        return false;
      booleans = {"dnd"};
    } else if (d.id == "autostart") {
      if (o.contains("apps") && !o["apps"].isArray()) {
        error = "Startup apps must be a list.";
        return false;
      }
      QSet<QString> commands;
      for (const auto &entry : o["apps"].toArray()) {
        auto app = entry.toObject();
        QString cmd = app["command"].toString().trimmed();
        if (!entry.isObject() || cmd.isEmpty() || cmd.contains('\n') ||
            cmd.contains('\r') ||
            (app.contains("enabled") && !app["enabled"].isBool()) ||
            commands.contains(cmd)) {
          error = "Invalid or duplicated startup command.";
          return false;
        }
        commands.insert(cmd);
      }
    }
    for (const auto &key : booleans)
      if (o.contains(key) && !o[key].isBool()) {
        error = key + " must be true or false.";
        return false;
      }
    for (const auto &key : strings)
      if (o.contains(key) && !o[key].isString()) {
        error = key + " must be text.";
        return false;
      }
  }
  return true;
}
bool ConfigStore::apply() {
  QString error;
  if (m_docs.contains("autostart")) {
    const auto d = m_docs["autostart"];
    if (d.draft != (d.existed ? d.original : "{}\n")) {
      if (!validate(d, error)) {
        report(error);
        return false;
      }
      if (!m_docs.contains("wave:" + m_home + "/tidewm/config.wave")) {
        report("TideWM configuration is required for startup apps.");
        return false;
      }
      setAutostart(json(d)["apps"].toArray().toVariantList());
    }
  }
  QStringList dirty;
  for (const auto &d : m_docs)
    if (d.draft != (d.existed ? d.original : "{}\n")) {
      if (d.readOnly) {
        report("Read-only file: " + d.label);
        return false;
      }
      if (!unchanged(d)) {
        report(d.label + " changed outside this app. Reload before applying; "
                         "your draft has been kept.");
        return false;
      }
      if (!validate(d, error)) {
        report(error);
        return false;
      }
      dirty << d.id;
    }
  if (dirty.isEmpty()) {
    report("No changes to apply.");
    return true;
  }
  if (std::any_of(dirty.cbegin(), dirty.cend(),
                  [](const QString &id) { return id.startsWith("wave:"); })) {
    for (const auto &dependency : m_docs)
      if (dependency.id.startsWith("wave:") && !unchanged(dependency)) {
        report("The desktop configuration changed outside this app. Reload "
               "before saving; your draft has been kept.");
        return false;
      }
  }
  QDir().mkpath(m_state);
  QTemporaryDir backupDirectory(
      m_state + "/" +
      QDateTime::currentDateTimeUtc().toString("yyyyMMdd-HHmmss-zzz") +
      "-XXXXXX");
  if (!backupDirectory.isValid()) {
    report("Could not create the configuration backup directory.");
    return false;
  }
  backupDirectory.setAutoRemove(false);
  const QString backup = backupDirectory.path();
  QFile::setPermissions(backup,
                        QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner);
  QJsonArray manifest;
  for (const auto &id : dirty) {
    const auto &d = m_docs[id];
    manifest.append(QJsonObject{
        {"path", d.path}, {"target", d.target}, {"existed", d.existed}});
  }
  QSaveFile manifestFile(backup + "/manifest.json");
  if (!manifestFile.open(QIODevice::WriteOnly) ||
      manifestFile.write(QJsonDocument(manifest).toJson()) < 0 ||
      !manifestFile.commit()) {
    report("Could not write the backup manifest.");
    return false;
  }
  QStringList written;
  for (const auto &id : dirty) {
    auto &d = m_docs[id];
    QString saved = backup + "/" + QString::number(written.size()) + "-" +
                    QFileInfo(d.path).fileName();
    if (!unchanged(d) || (d.existed && !QFile::copy(d.target, saved))) {
      error = "Could not back up " + d.label + " or it changed during apply.";
      break;
    }
    QDir().mkpath(QFileInfo(d.target).absolutePath());
    QSaveFile file(d.target);
    if (!file.open(QIODevice::WriteOnly) ||
        file.write(d.draft.toUtf8()) != d.draft.toUtf8().size() ||
        !file.commit()) {
      error = "Could not write " + d.label;
      break;
    }
    if (QFileInfo(d.path).isSymLink())
      utimensat(AT_FDCWD, d.path.toLocal8Bit().constData(), nullptr,
                AT_SYMLINK_NOFOLLOW);
    written << id;
  }
  if (!error.isEmpty()) {
    bool restored = true;
    for (const auto &id : written) {
      auto &d = m_docs[id];
      if (read(d.path) != d.draft) {
        restored = false;
        continue;
      }
      if (!d.existed)
        restored = QFile::remove(d.target) && restored;
      else {
        QSaveFile f(d.target);
        if (f.open(QIODevice::WriteOnly)) {
          bool complete =
              f.write(d.original.toUtf8()) == d.original.toUtf8().size();
          restored = complete && f.commit() && restored;
        } else
          restored = false;
      }
    }
    report(error +
           (restored ? " Earlier writes were rolled back; backups: "
                     : " Some files could not be restored; use backups: ") +
           backup);
    return false;
  }
  for (const auto &id : dirty) {
    auto &d = m_docs[id];
    d.original = d.draft;
    d.existed = true;
    d.target = QFileInfo(d.path).canonicalFilePath();
  }
  if (std::any_of(dirty.begin(), dirty.end(),
                  [](const QString &id) { return id.startsWith("theme:"); }))
    QProcess::startDetached(
        "qs", {"-c", "abyssal", "ipc", "call", "theme", "reload"});
  emit changed();
  report("Applied " + QString::number(dirty.size()) +
         " file(s). Backup: " + backup);
  return true;
}
void ConfigStore::launch(QString action) {
  if (action == "panels")
    QProcess::startDetached("qs",
                            {"-c", "abyssal", "ipc", "call", "shell", "edit"});
  else if (action == "wallpapers")
    QProcess::startDetached(
        "qs", {"-c", "abyssal", "ipc", "call", "shell", "wallpapers"});
  else if (action == "config")
    QDesktopServices::openUrl(QUrl::fromLocalFile(m_home + "/tidewm"));
  else if (action == "password")
    QProcess::startDetached(m_root + "/scripts/terminal", {"passwd"});
}
QStringList ConfigStore::outputs() const {
  QStringList names;
  QProcess p;
  p.start("tidectl", {"--json", "outputs"});
  if (p.waitForFinished(1500)) {
    auto data = QJsonDocument::fromJson(p.readAllStandardOutput())
                    .object()
                    .value("data")
                    .toArray();
    for (const auto &v : data) {
      auto n = v.toObject().value("name").toString();
      if (!n.isEmpty())
        names << n;
    }
  }
  if (names.isEmpty()) {
    auto screens = value("wallpaper", "screens").toMap();
    names = screens.keys();
    names.removeAll("*");
  }
  return names;
}
QVariantMap ConfigStore::capabilities() const {
  QProcess p;
  p.start(m_root + "/scripts/updates", {"capabilities"});
  if (p.waitForFinished(5000))
    return QJsonDocument::fromJson(p.readAllStandardOutput())
        .object()
        .toVariantMap();
  return {};
}
QVariantMap ConfigStore::transitions() const {
  return QJsonDocument::fromJson(
             read(m_root + "/wallpaper/transitions.json").toUtf8())
      .object()
      .toVariantMap();
}
