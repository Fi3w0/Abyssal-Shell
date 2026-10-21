#pragma once
#include <QJsonObject>
#include <QMap>
#include <QObject>
#include <QVariant>

class ConfigStore : public QObject {
  Q_OBJECT
  Q_PROPERTY(QVariantList documents READ documents NOTIFY changed)
  Q_PROPERTY(QVariantList themes READ themes NOTIFY changed)
  Q_PROPERTY(QVariantList bindings READ bindings NOTIFY changed)
  Q_PROPERTY(int dirtyCount READ dirtyCount NOTIFY changed)
  Q_PROPERTY(QString message READ message NOTIFY messageChanged)
  Q_PROPERTY(QString shellRoot READ shellRoot CONSTANT)
public:
  explicit ConfigStore(QString root, QObject *parent = nullptr);
  QVariantList documents() const;
  QVariantList themes() const;
  QVariantList bindings() const;
  int dirtyCount() const;
  QString message() const { return m_message; }
  QString shellRoot() const { return m_root; }
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
  void load(QString id, QString label, QString path, bool readonly = false);
  void loadWave(QString path, int depth = 0);
  void report(QString message);
  bool validate(const Document &doc, QString &error) const;
  bool unchanged(const Document &doc) const;
  static QString read(QString path);
  static QJsonObject json(const Document &doc);
signals:
  void changed();
  void messageChanged();
};
