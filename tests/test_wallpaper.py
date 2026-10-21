import importlib.machinery
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch, Mock

loader = importlib.machinery.SourceFileLoader('wallpaper_backend', str(Path(__file__).resolve().parents[1] / 'scripts/wallpaper-player'))
spec = importlib.util.spec_from_loader(loader.name, loader)
wall = importlib.util.module_from_spec(spec)
loader.exec_module(wall)


class WallpaperTests(unittest.TestCase):
    def test_paths_and_outputs_are_literal_arguments(self):
        config = {'source': '/pictures/a $(touch nope); wallpaper.png', 'output': 'DP-3', 'fit': 'fit', 'transition': 'wave', 'duration': 0.8}
        command = wall.image_command(config)
        self.assertEqual(command[-1], config['source'])
        self.assertEqual(command[command.index('--outputs') + 1], 'DP-3')
        self.assertEqual(command[command.index('--namespace') + 1], 'abyssal')
        self.assertEqual(command[command.index('--transition-type') + 1], 'wave')
        self.assertEqual(command[command.index('--resize') + 1], 'fit')

    def test_effect_changes_do_not_restart_a_video(self):
        config = {'source': '/a.mp4', 'output': 'DP-1', 'kind': 'video', 'fit': 'crop', 'hwdec': 'auto'}
        self.assertEqual(wall.render_key(config), wall.render_key(dict(config, duration=2, transition='wave', imageBackend='awww')))
        self.assertNotEqual(wall.render_key(config), wall.render_key(dict(config, fit='fit')))

    def test_bad_transition_and_duration_are_bounded(self):
        args = wall.image_command({'source': '/a.png', 'output': 'DP-1', 'transition': 'invalid', 'duration': 100})
        self.assertEqual(args[args.index('--transition-type') + 1], 'fade')
        self.assertEqual(args[args.index('--transition-duration') + 1], '3')

    def test_video_is_reaped_before_replacement(self):
        player = wall.Player.__new__(wall.Player)
        player.video = Mock()
        video = player.video
        with tempfile.TemporaryDirectory() as temp:
            player.socket = Path(temp) / 'player.sock'
            player.socket.touch()
            player.stop_video()
            video.terminate.assert_called_once()
            video.wait.assert_called_once_with(timeout=2)
            self.assertFalse(player.socket.exists())
            self.assertIsNone(player.video)

    def test_stalled_player_is_killed_and_reaped(self):
        player = wall.Player.__new__(wall.Player)
        player.video = Mock()
        video = player.video
        video.wait.side_effect = [subprocess.TimeoutExpired('mpvpaper', 2), 0]
        with tempfile.TemporaryDirectory() as temp:
            player.socket = Path(temp) / 'player.sock'
            player.stop_video()
        video.kill.assert_called_once()
        self.assertEqual(video.wait.call_count, 2)

    def test_video_layer_stays_above_the_image_daemon(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / 'video.mp4'
            source.touch()
            player = wall.Player.__new__(wall.Player)
            player.current = None
            player.sequence = 0
            player.socket = Path(temp) / 'player.sock'
            player.stop_video = Mock()
            with patch.object(wall, 'emit'), patch.object(wall, 'ipc', return_value={'w': 640}), \
                    patch.object(wall.subprocess, 'Popen') as start:
                start.return_value.poll.return_value = None
                player.apply({'source': str(source), 'output': 'DP-1', 'kind': 'video', 'imageBackend': 'awww'})
            self.assertEqual(start.call_args.args[0][:3], ['mpvpaper', '-l', 'bottom'])
            self.assertEqual(player.current['source'], str(source))

    def test_incoming_video_is_not_covered_before_its_first_frame(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / 'video.mp4'
            source.touch()
            player = wall.Player.__new__(wall.Player)
            player.current = {'source': '/old.png', 'kind': 'image', 'imageBackend': 'native'}
            player.sequence = 0
            player.socket = Path(temp) / 'player.sock'
            player.stop_video = Mock()
            player.snapshot = Mock(return_value='/old.png')
            with patch.object(wall, 'emit') as emit, patch.object(wall, 'ipc', return_value={'w': 640}), \
                    patch.object(wall.subprocess, 'Popen') as start:
                start.return_value.poll.return_value = None
                player.apply({'source': str(source), 'output': 'DP-1', 'kind': 'video', 'duration': 0.9, 'preset': 'undertow'})
            player.snapshot.assert_not_called()
            self.assertFalse(any('prepare' in call.kwargs for call in emit.call_args_list))

    def test_partial_ipc_reply_followed_by_eof_does_not_spin(self):
        with patch.object(wall.socket, 'socket') as connect:
            client = connect.return_value.__enter__.return_value
            client.recv.side_effect = [b'{"request_id":', b'']
            with self.assertRaisesRegex(OSError, 'closed'):
                wall.ipc('/test.sock', ['get_property', 'pause'])

    def test_native_ack_precedes_removing_transition(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / 'blue.png'
            source.touch()
            player = wall.Player.__new__(wall.Player)
            player.current = {'source': '/old.png', 'kind': 'image', 'imageBackend': 'native', 'fit': 'crop'}
            player.sequence = 0
            player.snapshot = Mock(return_value='/old.png')
            player.wait = Mock(return_value=True)
            player.stop_video = Mock()
            with patch.object(wall, 'emit') as emit:
                player.apply({'source': str(source), 'kind': 'image', 'imageBackend': 'native', 'duration': 0.6})
            self.assertEqual([call.args[0] for call in player.wait.call_args_list], ['overlayReady', 'nativeReady'])
            self.assertEqual(emit.call_args_list[-1].kwargs['fade'], True)
            self.assertEqual(player.current['source'], str(source))

    def test_awww_failure_uses_native_renderer(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / 'blue.png'
            source.touch()
            player = wall.Player.__new__(wall.Player)
            player.current = None
            player.sequence = 0
            player.wait = Mock(return_value=True)
            player.stop_video = Mock()
            with patch.object(wall, 'emit') as emit, patch.object(wall, 'command', return_value=subprocess.CompletedProcess([], 1)):
                player.apply({'source': str(source), 'output': 'DP-1', 'kind': 'image', 'imageBackend': 'awww'})
            self.assertTrue(any(c.kwargs.get('native') == str(source) for c in emit.call_args_list))
            player.wait.assert_called_once_with('nativeReady', 1)


if __name__ == '__main__':
    unittest.main()
