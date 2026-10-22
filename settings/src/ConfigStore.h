#pragma once
#include <QFileSystemWatcher>
#include <QJsonObject>
#include <QMap>
#include <QObject>
#include <QTimer>
#include <QVariant>
#include <QUrl>

class ConfigStore : public QObject {
  Q_OBJECT
  Q_PROPERTY(QVariantList documents READ documents NOTIFY changed)
  Q_PROPERTY(QVariantList themes READ themes NOTIFY changed)
  Q_PROPERTY(QVariantList panelPresets READ panelPresets NOTIFY changed)
  Q_PROPERTY(QVariantList bindings READ bindings NOTIFY changed)
  Q_PROPERTY(int dirtyCount READ dirtyCount NOTIFY changed)
  Q_PROPERTY(QString message READ message NOTIFY messageChanged)
  Q_PROPERTY(QString shellRoot READ shellRoot CONSTANT)
  Q_PROPERTY(QVariantList desktopPages READ desktopPages CONSTANT)
  Q_PROPERTY(bool desktopEditable READ desktopEditable CONSTANT)
  Q_PROPERTY(bool externalChange READ externalChange NOTIFY changed)
public:
  explicit ConfigStore(QString root, QObject *parent = nullptr);
  QVariantList documents() const;
  QVariantList themes() const;
  QVariantList bindings() const;
  int dirtyCount() const;
  QString message() const { return m_message; }
  QString shellRoot() const { return m_root; }
  bool externalChange() const { return m_externalChange; }
  Q_INVOKABLE QVariant value(QString id, QString key,
                             QVariant fallback = {}) const;
  Q_INVOKABLE void setValue(QString id, QString key, QVariant value);
  Q_INVOKABLE QString text(QString id) const;
  Q_INVOKABLE void setText(QString id, QString text);
  Q_INVOKABLE bool setBinding(QString id, int line, QString chord,
                              QString action);
  Q_INVOKABLE void setAutostart(QVariantList apps);
  Q_INVOKABLE QVariantMap account() const;
  Q_INVOKABLE QString copyTheme(QString id);
  QVariantList panelPresets() const;
  Q_INVOKABLE QString saveTheme(QString name);
  Q_INVOKABLE bool setThemeColor(QString key, QString color);
  Q_INVOKABLE bool setThemeOption(QString key, QVariant value);
  Q_INVOKABLE QString savePanelPreset(QString name);
  Q_INVOKABLE bool loadPanelPreset(QString id);
  Q_INVOKABLE QString importPreset(QString kind, QUrl file);
  Q_INVOKABLE bool exportPreset(QString kind, QString id, QUrl file);
  Q_INVOKABLE void resetAppLook();
  QVariantList desktopPages() const;
  bool desktopEditable() const;
  Q_INVOKABLE QVariant desktopValue(QString key, QVariant fallback = {}) const;
  Q_INVOKABLE bool setDesktopValue(QString key, QVariant value);
  Q_INVOKABLE QVariantList keyboardLayouts() const;
  Q_INVOKABLE bool setAccent(QString color);
  Q_INVOKABLE QVariantList applications() const;
  Q_INVOKABLE QString shortcutName(int key, int modifiers) const;
  Q_INVOKABLE bool addShortcut(QString chord, QString action);
  Q_INVOKABLE bool apply();
  Q_INVOKABLE void reload();
  Q_INVOKABLE void launch(QString action);
  Q_INVOKABLE QStringList outputs() const;
  Q_INVOKABLE QVariantMap capabilities() const;
  Q_INVOKABLE QVariantMap transitions() const;

private:
  struct Document {
    QString id, label, path, target, original, draft;
    bool existed = false, readOnly = false;
  };
  QString m_root, m_home, m_state, m_message;
  QMap<QString, Document> m_docs;
  mutable bool m_waveCacheValid = false;
  mutable QMap<QString, QString> m_waveValues;
  QFileSystemWatcher m_watcher;
  QTimer m_externalTimer;
  bool m_externalChange = false;
  void load(QString id, QString label, QString path, bool readonly = false);
  void loadWave(QString path, int depth = 0);
  void report(QString message);
  bool validate(const Document &doc, QString &error) const;
  bool unchanged(const Document &doc) const;
  static QString read(QString path);
  static QJsonObject json(const Document &doc);
  static QString waveValidator();
  static QVariant fromUi(QVariant value);
  QString activeThemeId() const;
  QString editableTheme();
  QString createPreset(QString kind, QString name, QJsonObject data);
  static bool validTheme(const QJsonObject &data, QString &error);
  static bool validLayout(const QJsonObject &data, QString &error);
signals:
  void changed();
  void messageChanged();
};
