#pragma once
#include <QObject>
#include <QTemporaryDir>
class ConfigTest : public QObject {
  Q_OBJECT
  QTemporaryDir temp;
  QString root, config;
  void write(QString path, QByteArray data);
  QByteArray read(QString path);
private slots:
  void initTestCase();
  void init();
  void draftsDoNotWrite();
  void applyPreservesUnknownAndBacksUp();
  void malformedDraftIsBlocked();
  void externalChangesAreKept();
  void symlinksArePreserved();
  void changedSymlinkIsBlocked();
  void laterWriteFailureRollsBack();
  void shippedThemesCannotBeEdited();
  void keybindDuplicateIsBlocked();
  void autostartPreservesExistingStartup();
};
