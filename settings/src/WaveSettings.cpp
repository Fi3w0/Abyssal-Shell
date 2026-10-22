#include "WaveSettings.h"
#include <QRegularExpression>

namespace WaveSettings {
static QString code(QString line) {
  QChar quote;
  bool escaped = false;
  for (int i = 0; i < line.size(); ++i) {
    auto c = line[i];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (c == '\\' && !quote.isNull()) {
      escaped = true;
      continue;
    }
    if (!quote.isNull()) {
      if (c == quote)
        quote = QChar();
    } else if (c == '\'' || c == '"')
      quote = c;
    else if (c == '#' && (i == 0 || line[i - 1].isSpace()))
      return line.left(i).trimmed();
  }
  return line.trimmed();
}
Scan scan(const QString &source) {
  Scan result;
  QStringList scope;
  QList<int> starts;
  const auto lines = source.split('\n');
  const QRegularExpression block(R"(^([\w-]+)(?:\s+[^{}]+)?\s*\{$)");
  const QRegularExpression assign(R"(^([\w-]+)\s*=\s*(.+)$)");
  const QRegularExpression include(R"re(^include\s+["']([^"']+)["']$)re");
  int opaqueDepth = 0;
  for (int i = 0; i < lines.size(); ++i) {
    const auto text = code(lines[i]);
    // Lua/custom multiline expressions stay opaque: braces inside cannot make
    // subsequent values appear to be top-level assignments.
    if (opaqueDepth) {
      opaqueDepth += text.count('{') - text.count('}');
      continue;
    }
    if (text.contains("{{")) {
      opaqueDepth = text.count('{') - text.count('}');
      continue;
    }
    if (text == "}") {
      if (!scope.isEmpty()) {
        result.closingLines[scope.join('.')] = i;
        scope.removeLast();
        starts.removeLast();
      }
      continue;
    }
    auto b = block.match(text);
    if (b.hasMatch()) {
      scope << b.captured(1);
      starts << i;
      continue;
    }
    auto inc = include.match(text);
    if (scope.isEmpty() && inc.hasMatch()) {
      result.entries << Entry{{}, {}, inc.captured(1), i};
      continue;
    }
    auto a = assign.match(text);
    if (a.hasMatch())
      result.entries << Entry{(scope + QStringList{a.captured(1)}).join('.'),
                              a.captured(2),
                              {},
                              i,
                              starts.isEmpty() ? -1 : starts.first()};
  }
  return result;
}
QString set(const QString &source, const QString &key, const QString &value) {
  auto result = scan(source);
  auto lines = source.split('\n');
  for (auto it = result.entries.crbegin(); it != result.entries.crend(); ++it) {
    if (it->key != key || !it->include.isEmpty())
      continue;
    const auto original = lines[it->line];
    const int start = original.indexOf('=') + 1;
    const auto raw = code(original);
    const auto tail = original.mid(original.indexOf(raw) + raw.size());
    lines[it->line] = original.left(start) + " " + value + tail;
    return lines.join('\n');
  }
  auto parts = key.split('.');
  const auto name = parts.takeLast();
  int depth = parts.size(), line = -1;
  while (depth > 0) {
    const auto path = parts.mid(0, depth).join('.');
    if (result.closingLines.contains(path)) {
      line = result.closingLines[path];
      break;
    }
    --depth;
  }
  QStringList insertion;
  for (int i = depth; i < parts.size(); ++i)
    insertion << QString(i * 4, ' ') + parts[i] + " {";
  insertion << QString(parts.size() * 4, ' ') + name + " = " + value;
  for (int i = parts.size() - 1; i >= depth; --i)
    insertion << QString(i * 4, ' ') + "}";
  if (line < 0)
    return source + (source.endsWith('\n') || source.isEmpty() ? "" : "\n") +
           insertion.join('\n') + "\n";
  for (int i = 0; i < insertion.size(); ++i)
    lines.insert(line + i, insertion[i]);
  return lines.join('\n');
}
} // namespace WaveSettings
