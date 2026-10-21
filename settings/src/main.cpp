#include "ConfigStore.h"
#include <QCommandLineParser>
#include <QDir>
#include <QGuiApplication>
#include <QLocalServer>
#include <QLocalSocket>
#include <QLockFile>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QTimer>
int main(int argc, char **argv) {
  QGuiApplication app(argc, argv);
  app.setApplicationName("abyssal-settings");
  app.setOrganizationName("Abyssal");
  app.setDesktopFileName("org.abyssal.Settings");
  QQuickStyle::setStyle("Basic");
  QCommandLineParser parser;
  parser.addHelpOption();
  parser.addOption({"shell-root", "Abyssal Shell directory", "path",
                    QDir::homePath() + "/.config/quickshell/abyssal"});
  parser.addOption({"page", "Initial settings section", "name", "appearance"});
  parser.addOption({"capture", "Save a UI capture for testing", "path"});
  parser.addOption(
      {"quit-after", "Quit after N milliseconds (testing)", "milliseconds"});
  parser.addOption({"new-instance", "Separate instance for isolated UI tests"});
  parser.process(app);
  const QString endpoint =
      QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation) +
      "/abyssal-settings";
  QLockFile lock(endpoint + ".lock");
  QLocalServer server;
  if (!parser.isSet("new-instance")) {
    if (!lock.tryLock(0)) {
      QLocalSocket socket;
      socket.connectToServer(endpoint);
      if (socket.waitForConnected(1500)) {
        socket.write("activate");
        socket.waitForBytesWritten(1000);
        return 0;
      }
      qWarning("Settings is already starting or its lock is held.");
      return 1;
    }
    QLocalServer::removeServer(endpoint);
    if (!server.listen(endpoint)) {
      qWarning("Could not create the settings activation socket.");
      return 1;
    }
  }
  ConfigStore store(parser.value("shell-root"));
  QQmlApplicationEngine engine;
  engine.rootContext()->setContextProperty("Store", &store);
  engine.rootContext()->setContextProperty("initialPage", parser.value("page"));
  engine.load(QUrl("qrc:/qml/Main.qml"));
  if (engine.rootObjects().isEmpty())
    return 1;
  QObject::connect(&server, &QLocalServer::newConnection, &app, [&] {
    while (auto socket = server.nextPendingConnection()) {
      auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
      window->show();
      window->raise();
      window->requestActivate();
      socket->deleteLater();
    }
  });
  if (parser.isSet("capture"))
    QTimer::singleShot(900, &app, [&] {
      auto w = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
      if (w)
        w->grabWindow().save(parser.value("capture"));
    });
  if (parser.isSet("quit-after"))
    QTimer::singleShot(parser.value("quit-after").toInt(), &app,
                       &QCoreApplication::quit);
  return app.exec();
}
