#pragma once
#include <QMap>
#include <QString>

// A narrow, lossless view of plain Wave assignments. It never evaluates Lua or
// rewrites an existing user's file; includes are resolved by ConfigStore.
namespace WaveSettings {
struct Entry {
  QString key, value, include;
  int line = 0;
  int blockLine = -1;
};
struct Scan {
  QList<Entry> entries;
  QMap<QString, int> closingLines;
};
Scan scan(const QString &source);
QString set(const QString &source, const QString &key, const QString &value);
} // namespace WaveSettings
