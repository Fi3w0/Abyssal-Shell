Run `python3 tests/run-ui` with Qt Quick Test installed. If its runner is
not on PATH and qtpaths cannot locate it, set `QML_TEST_RUNNER` to the
qmltestrunner executable.

These tests load the actual UI components into an offscreen Qt window,
with fake services in a temporary directory. They do not connect to the
desktop, read the clipboard, or change saved settings. They cover clipboard
header dragging, screen boundaries, update counts that change digit length,
and Wi-Fi alignment with its label hidden.

Run `python3 -m unittest discover -s tests -p 'test_*.py'` for update-policy
and wallpaper-worker regressions. Package commands are mocked; settings use
temporary directories. Tests cover AUR helper selection, matching DNF check
and upgrade repositories, invalid configuration preservation, literal
wallpaper paths, video process cleanup, transition readiness and native
fallback when awww fails. They do not install or upgrade packages.
