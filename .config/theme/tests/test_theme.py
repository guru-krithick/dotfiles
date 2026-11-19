"""Run `theme` against a disposable home and a fake `noctalia` that keeps its state in a file."""
import json
import os
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[3]
SCRIPT = REPO / '.local/bin/theme'
NOCTALIA = REPO / '.config/noctalia'

# Answers like `noctalia msg`: replies on stdout, "error: ..." and exit 1 on failure,
# config-get values printed as TOML.
FAKE_NOCTALIA = r'''
import json, os, sys, tomllib
state_path = os.environ['FAKE_NOCTALIA_STATE']
with open(os.environ['FAKE_NOCTALIA_LOG'], 'a') as log:
    log.write(' '.join(sys.argv[1:]) + '\n')
state = json.load(open(state_path))
def reply(text='ok', code=0):
    print(text)
    if code == 0:
        json.dump(state, open(state_path, 'w'))
    sys.exit(code)
if not state['running']:
    reply('Error: noctalia is not running', 1)
command, args = sys.argv[2], sys.argv[3:]
if command == 'color-scheme-get':
    reply(f"{state['source']} {state['name']}")
if command == 'color-scheme-set':
    state['source'] = args[0]
    state['name'] = args[1]
    reply()
if command == 'config-get':
    values = {'wallpaper.directory': state['directory'],
              'theme.mode': state['mode']}
    reply(f"'{values[args[0]]}'") if args[0] in values else reply(f'error: path not found: {args[0]}', 1)
if command == 'config-set' and args[0] == 'wallpaper.directory':
    state[args[0].split('.')[1]] = tomllib.loads(f'v = {args[1]}')['v']
    reply()
if command == 'theme-mode-set':
    state['mode'] = args[0]
    reply()
if command == 'wallpaper-get':
    reply(state['wallpaper'])
if command == 'wallpaper-set':
    if not os.path.isfile(args[0]):
        reply('error: path does not exist or is not a regular file', 1)
    state['wallpaper'] = args[0]
    reply()
if command in ('wallpaper-next', 'wallpaper-previous', 'wallpaper-random'):
    reply()
if command == 'plugin':
    reply('ok: dispatched 1')
reply(f'error: unknown command {command}', 1)
'''

# Writes its last argument like ffmpeg writes an image; fails for "broken" pictures.
FAKE_FFMPEG = r'''
import sys
if any('broken' in arg for arg in sys.argv):
    print('Invalid data found when processing input', file=sys.stderr)
    sys.exit(1)
open(sys.argv[-1], 'w').write(' '.join(sys.argv[1:]))
'''


class ThemeCarouselTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('lua'), 'Lua is unavailable for the carousel lifecycle harness')
    def test_carousel_dwell_apply_queue_keys_and_closing(self):
        result = subprocess.run(['lua', str(Path(__file__).with_name('theme_carousel_test.lua')),
                                 str(NOCTALIA / 'plugins/themes')],
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


class ThemeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='theme-test-')
        root = Path(self.temp.name)
        self.home = root / 'home'
        palettes = self.home / '.config/noctalia/palettes'
        palettes.mkdir(parents=True)
        for tid in ('ultra-dark', 'tokyo-night', 'catppuccin-macchiato'):
            (palettes / f'{tid}.json').write_text('{"version": 2}')
        self.bars = palettes.parent / 'bars'
        self.bars.mkdir()
        for tid in ('default', 'ultra-dark', 'tokyo-night'):
            (self.bars / f'{tid}.toml').write_text(f'# {tid}\n')
        self.bar = palettes.parent / 'bar.toml'
        self.walls = self.home / 'Pictures/wallpapers'
        for tid, names in {'ultra-dark': ['b.png', 'a.jpg'], 'tokyo-night': ['x.jpg']}.items():
            (self.walls / tid).mkdir(parents=True)
            for name in names:
                (self.walls / tid / name).write_bytes(b'')
        (self.walls / 'ultra-dark/notes.txt').write_text('')  # not an image
        self.fallback = self.home / 'Pictures/wallpaper.jpg'
        self.fallback.write_bytes(b'')
        self.bin = root / 'bin'
        self.bin.mkdir()
        (self.bin / 'python3').symlink_to(sys.executable)
        (self.bin / 'fake_noctalia.py').write_text(FAKE_NOCTALIA)
        stub = self.bin / 'noctalia'
        stub.write_text(f'#!/bin/sh\nexec {sys.executable} {self.bin / "fake_noctalia.py"} "$@"\n')
        stub.chmod(0o755)
        self.log = root / 'calls.log'
        self.state_file = root / 'noctalia.json'
        self.set_state(running=True, source='builtin', name='Noctalia', mode='dark',
                       wallpaper=str(self.fallback), directory=str(self.home / 'Pictures'))
        self.env = {'HOME': str(self.home), 'PATH': str(self.bin), 'FAKE_NOCTALIA_LOG': str(self.log),
                    'FAKE_NOCTALIA_STATE': str(self.state_file)}

    def tearDown(self):
        self.temp.cleanup()

    def set_state(self, **changes):
        state = json.loads(self.state_file.read_text()) if self.state_file.exists() else {}
        self.state_file.write_text(json.dumps(dict(state, **changes)))

    def state(self):
        return json.loads(self.state_file.read_text())

    def theme(self, *args, ok=True):
        result = subprocess.run([sys.executable, str(SCRIPT), *args], env=self.env,
                                capture_output=True, text=True, timeout=60)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def calls(self, clear=False):
        lines = self.log.read_text().splitlines() if self.log.exists() else []
        if clear:
            self.log.write_text('')
        # Reads only inform the script; the order of the writes is what matters.
        return [line for line in lines if not line.startswith(('msg color-scheme-get', 'msg config-get'))]

    def memory(self):
        return json.loads((self.home / '.local/state/theme/wallpapers.json').read_text())

    def test_fixed_theme_sets_palette_then_wallpaper_and_points_the_picker_at_its_folder(self):
        self.theme('set', 'ultra-dark')
        self.assertEqual(self.calls(), [
            'msg color-scheme-set custom ultra-dark',
            f'msg wallpaper-set {self.walls}/ultra-dark/a.jpg',  # first image by name
            f'msg config-set wallpaper.directory "{self.walls}/ultra-dark"',
        ])
        self.assertEqual(self.theme('current').stdout.strip(), 'ultra-dark')
        current = json.loads(self.theme('current', '--json').stdout)
        self.assertEqual(current['folder'], f'{self.walls}/ultra-dark')
        listed = json.loads(self.theme('list', '--json').stdout)
        self.assertEqual([t['id'] for t in listed],
                         ['catppuccin-macchiato', 'tokyo-night', 'ultra-dark'])
        self.assertEqual([t['id'] for t in listed if t['current']], ['ultra-dark'])

    def test_visual_previews_match_the_wallpaper_that_will_be_applied_without_writes(self):
        palette = self.bars.parent / 'palettes/ultra-dark.json'
        palette.write_text(json.dumps({'version': 2, 'dark': {
            'primary': '#b8c7bc', 'surface': '#070908', 'terminal': {'background': '#000000'}}}))
        remembered = str(self.walls / 'ultra-dark/b.png')
        self.theme('remember', remembered)
        self.theme('set', 'ultra-dark')
        state_before, memory_before = self.state(), self.memory()
        self.calls(clear=True)
        entries = {e['id']: e for e in json.loads(self.theme('list', '--previews').stdout)}
        self.assertEqual(entries['ultra-dark']['wallpaper'], remembered)
        self.assertTrue(entries['ultra-dark']['current'])
        self.assertEqual(entries['ultra-dark']['colors'], {'primary': '#b8c7bc', 'surface': '#070908'})
        self.assertEqual(entries['catppuccin-macchiato']['wallpaper'], str(self.fallback))
        self.assertEqual(self.calls(), [])
        self.assertEqual(self.state(), state_before)
        self.assertEqual(self.memory(), memory_before)
        self.assertEqual(self.bar.resolve(), self.bars / 'ultra-dark.toml')

    def test_preview_failures_keep_themes_selectable_and_new_palettes_appear(self):
        (self.bars.parent / 'palettes/new-theme.json').write_text('{broken')
        entries = {e['id']: e for e in json.loads(self.theme('list', '--previews').stdout)}
        self.assertIn('preview_error', entries['new-theme'])
        self.assertEqual(entries['new-theme']['colors'], {})

    def test_chooser_only_toggles_the_carousel_and_reports_connection_failure(self):
        before = self.state()
        self.theme('choose')
        self.assertEqual(self.calls(clear=True), ['msg plugin guru/themes:switcher all toggle'])
        self.assertEqual(self.state(), before)
        self.assertFalse(self.bar.exists())
        self.set_state(running=False)
        self.assertEqual(self.theme('choose', ok=False).returncode, 1)

    def test_set_with_a_wallpaper_shows_that_picture_in_one_switch(self):
        self.theme('remember', str(self.walls / 'ultra-dark/b.png'))
        self.calls(clear=True)
        self.theme('set', 'ultra-dark', '--wallpaper', str(self.walls / 'ultra-dark/a.jpg'))
        self.assertEqual(self.calls(clear=True), [
            'msg color-scheme-set custom ultra-dark',
            f'msg wallpaper-set {self.walls}/ultra-dark/a.jpg',  # not the remembered b.png
            f'msg config-set wallpaper.directory "{self.walls}/ultra-dark"',
        ])
        # A missing or non-image file changes nothing, not even the palette.
        for bad in (self.walls / 'ultra-dark/gone.png', self.walls / 'ultra-dark/notes.txt'):
            result = self.theme('set', 'tokyo-night', '--wallpaper', str(bad), ok=False)
            self.assertEqual(result.returncode, 1)
        self.assertEqual(self.calls(), [])
        self.assertEqual(self.theme('current').stdout.strip(), 'ultra-dark')

    def install_ffmpeg(self):
        (self.bin / 'fake_ffmpeg.py').write_text(FAKE_FFMPEG)
        ffmpeg = self.bin / 'ffmpeg'
        ffmpeg.write_text(f'#!/bin/sh\nexec {sys.executable} {self.bin / "fake_ffmpeg.py"} "$@"\n')
        ffmpeg.chmod(0o755)

    def catalog(self):
        return json.loads(self.theme('catalog').stdout)

    def test_catalog_lists_every_wallpaper_by_theme_with_its_card_and_colours(self):
        palette = self.bars.parent / 'palettes/tokyo-night.json'
        palette.write_text(json.dumps({'version': 2, 'dark': {'primary': '#7aa2f7', 'surface': '#1a1b26',
                                                              'terminal': {'background': '#000000'}}}))
        (self.walls / 'ultra-dark/00-misty-pines.jpg').write_bytes(b'')
        self.theme('remember', str(self.walls / 'ultra-dark/b.png'))
        self.calls(clear=True)
        state_before = self.state()
        data = self.catalog()
        themes = {t['id']: t for t in data['themes']}
        self.assertEqual([t['id'] for t in data['themes']],
                         ['catppuccin-macchiato', 'tokyo-night', 'ultra-dark'])
        ultra = themes['ultra-dark']
        self.assertEqual([w['name'] for w in ultra['wallpapers']], ['misty pines', 'a', 'b'])
        self.assertEqual(ultra['remembered'], str(self.walls / 'ultra-dark/b.png'))
        self.assertEqual(themes['tokyo-night']['colors'], {'primary': '#7aa2f7', 'surface': '#1a1b26'})
        # A theme without a folder offers the fallback picture.
        self.assertEqual([w['path'] for w in themes['catppuccin-macchiato']['wallpapers']], [str(self.fallback)])
        cards = [w['card'] for t in data['themes'] for w in t['wallpapers']]
        self.assertEqual(len(set(cards)), len(cards))
        self.assertTrue(all(c.startswith(str(self.home / '.cache/theme/cards/')) for c in cards))
        self.assertFalse(any(w['ready'] for t in data['themes'] for w in t['wallpapers']))
        self.assertGreater(data['missing'], 0)
        self.assertEqual(data['card'], {'width': 560, 'height': 315, 'slant': 63, 'pad': 28})
        # Reading never changes the desktop, and works while Noctalia is down.
        self.assertEqual(self.calls(), [])
        self.assertEqual(self.state(), state_before)
        self.set_state(running=False)
        self.assertEqual(len(self.catalog()['themes']), 3)

    def test_cards_are_drawn_once_failures_are_marked_and_stale_cards_removed(self):
        self.assertEqual(self.theme('cards', ok=False).returncode, 1)  # no ffmpeg: an error, no crash
        self.install_ffmpeg()
        (self.walls / 'tokyo-night/broken.jpg').write_bytes(b'')
        printed = self.theme('cards').stdout.split()
        data = self.catalog()
        walls = {w['path']: w for t in data['themes'] for w in t['wallpapers']}
        broken = walls[str(self.walls / 'tokyo-night/broken.jpg')]
        self.assertFalse(broken['ready'])
        self.assertTrue(Path(broken['card']).with_suffix('.failed').is_file())
        others = [w for path, w in walls.items() if 'broken' not in path]
        self.assertTrue(all(w['ready'] and w['card'] in printed for w in others))
        self.assertTrue(all(t['placeholder'] for t in data['themes']))
        self.assertEqual(data['missing'], 0)
        # Nothing left to draw: a second run prints nothing and runs no ffmpeg.
        self.assertEqual(self.theme('cards').stdout, '')
        # A changed picture gets a new card; the old one is removed.
        old = walls[str(self.walls / 'ultra-dark/a.jpg')]['card']
        (self.walls / 'ultra-dark/a.jpg').write_bytes(b'new picture')
        self.theme('cards')
        new = next(w['card'] for t in self.catalog()['themes'] for w in t['wallpapers']
                   if w['path'] == str(self.walls / 'ultra-dark/a.jpg'))
        self.assertNotEqual(new, old)
        self.assertTrue(Path(new).is_file())
        self.assertFalse(Path(old).exists())

    def test_ultra_dark_overrides_saved_light_or_scheduled_mode(self):
        for mode in ('auto', 'light'):
            with self.subTest(saved_mode=mode):
                self.set_state(mode=mode)
                self.calls(clear=True)
                self.theme('set', 'ultra-dark')
                self.assertEqual(self.state()['mode'], 'dark')
                self.assertIn('msg theme-mode-set dark', self.calls())
                self.calls(clear=True)
                self.theme('set', 'ultra-dark')
                self.assertNotIn('msg theme-mode-set dark', self.calls())

    def test_each_theme_returns_to_its_remembered_wallpaper(self):
        self.theme('set', 'ultra-dark')
        self.theme('remember', str(self.walls / 'ultra-dark/b.png'))  # what the hook does
        self.theme('set', 'tokyo-night')
        self.theme('set', 'ultra-dark')
        self.assertEqual(self.state()['wallpaper'], str(self.walls / 'ultra-dark/b.png'))
        (self.walls / 'ultra-dark/b.png').unlink()  # a deleted favourite falls back to the folder
        self.theme('set', 'ultra-dark')
        self.assertEqual(self.state()['wallpaper'], str(self.walls / 'ultra-dark/a.jpg'))
        # Without a folder of its own a theme shows ~/Pictures/wallpaper.jpg and the
        # picker browses all wallpaper folders.
        self.theme('set', 'catppuccin-macchiato')
        self.assertEqual(self.state()['wallpaper'], str(self.fallback))
        self.assertEqual(self.state()['directory'], str(self.walls))

    def test_remember_files_a_wallpaper_under_its_folder_else_the_active_theme(self):
        self.theme('set', 'ultra-dark')
        self.theme('remember', str(self.walls / 'tokyo-night/x.jpg'))
        elsewhere = self.home / 'elsewhere.png'
        elsewhere.write_bytes(b'')
        self.theme('remember', str(elsewhere))
        self.assertEqual(self.memory(), {'tokyo-night': str(self.walls / 'tokyo-night/x.jpg'),
                                         'ultra-dark': str(elsewhere)})
        # The fallback, solid colours and missing files are not choices.
        for path in (str(self.fallback), 'color:#112233', str(self.home / 'gone.png')):
            self.theme('remember', path)
        self.assertEqual(self.memory()['ultra-dark'], str(elsewhere))

    def test_next_and_prev_cycle_in_list_order(self):
        self.theme('next')  # Noctalia shows a palette that is not a theme: start at the top
        self.assertEqual(self.theme('current').stdout.strip(), 'catppuccin-macchiato')
        self.theme('prev')
        self.assertEqual(self.theme('current').stdout.strip(), 'ultra-dark')
        self.theme('next')
        self.theme('next')
        self.assertEqual(self.theme('current').stdout.strip(), 'tokyo-night')

    def test_wallpaper_commands_use_noctalia_and_check_paths(self):
        for choice, command in (('next', 'wallpaper-next'), ('prev', 'wallpaper-previous'),
                                ('random', 'wallpaper-random')):
            self.theme('wallpaper', choice)
            self.assertEqual(self.calls(clear=True), [f'msg {command}'])
        self.theme('wallpaper', str(self.walls / 'tokyo-night/x.jpg'))
        self.assertEqual(self.state()['wallpaper'], str(self.walls / 'tokyo-night/x.jpg'))
        self.calls(clear=True)
        for path in (self.home / 'missing.jpg', self.walls / 'ultra-dark/notes.txt'):
            self.assertEqual(self.theme('wallpaper', str(path), ok=False).returncode, 1)
        self.assertEqual(self.calls(), [])

    def test_errors_exit_nonzero_and_change_nothing(self):
        result = self.theme('set', 'nope', ok=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("unknown theme 'nope'", result.stderr)
        self.assertEqual(self.calls(), [])
        self.set_state(running=False)
        result = self.theme('set', 'ultra-dark', ok=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn('noctalia is not running', result.stderr)
        self.assertEqual(self.state()['source'], 'builtin')
        self.assertIn('ultra-dark', self.theme('list').stdout)  # listing works offline

    def test_the_picker_folder_is_only_written_when_it_changes(self):
        self.theme('set', 'tokyo-night')
        self.calls(clear=True)
        self.theme('set', 'tokyo-night')
        self.assertFalse([c for c in self.calls() if c.startswith('msg config-set')])

    def test_concurrent_switches_are_serialised(self):
        self.theme('set', 'ultra-dark')
        with ThreadPoolExecutor(6) as pool:
            results = list(pool.map(lambda _: self.theme('next', ok=False), range(6)))
        self.assertEqual([r.returncode for r in results], [0] * 6, [r.stderr for r in results])
        # Three themes: six steps from ultra-dark return to it only if none was lost.
        self.assertEqual(self.theme('current').stdout.strip(), 'ultra-dark')

    def test_switches_select_the_bar_and_keep_it_between_invocations(self):
        for tid in ('ultra-dark', 'tokyo-night'):
            self.theme('set', tid)
            self.assertTrue(self.bar.is_symlink())
            self.assertEqual(self.bar.resolve(), self.bars / f'{tid}.toml')
            self.assertEqual(self.theme('current').stdout.strip(), tid)
            self.assertEqual(self.bar.read_text(), f'# {tid}\n')

    def test_a_new_theme_without_a_layout_uses_the_default_bar(self):
        (self.bars.parent / 'palettes/new-theme.json').write_text('{"version": 2}')
        self.theme('set', 'ultra-dark')
        self.theme('set', 'new-theme')
        self.assertEqual(self.bar.resolve(), self.bars / 'default.toml')
        self.assertEqual(self.theme('current').stdout.strip(), 'new-theme')

    def test_rejected_switches_preserve_the_active_bar(self):
        self.theme('set', 'ultra-dark')
        self.assertEqual(self.theme('set', 'missing', ok=False).returncode, 1)
        self.assertEqual(self.bar.resolve(), self.bars / 'ultra-dark.toml')
        self.set_state(running=False)
        self.assertEqual(self.theme('set', 'tokyo-night', ok=False).returncode, 1)
        self.assertEqual(self.bar.resolve(), self.bars / 'ultra-dark.toml')

    def test_a_user_owned_regular_bar_is_preserved(self):
        self.bar.write_text('# my own bar\n')
        self.theme('set', 'tokyo-night')
        self.assertFalse(self.bar.is_symlink())
        self.assertEqual(self.bar.read_text(), '# my own bar\n')

    def test_a_deleted_layout_is_replaced_by_the_fallback_on_next_switch(self):
        self.theme('set', 'ultra-dark')
        (self.bars / 'ultra-dark.toml').unlink()
        self.theme('set', 'ultra-dark')
        self.assertEqual(self.bar.resolve(), self.bars / 'default.toml')

    def test_startup_recreates_the_bar_without_reapplying_the_theme(self):
        self.set_state(source='custom', name='tokyo-night')
        self.theme('sync-bar')
        self.assertEqual(self.bar.resolve(), self.bars / 'tokyo-night.toml')
        self.assertEqual(self.calls(), [])  # no palette/wallpaper/template side effects
        self.bar.unlink()
        self.set_state(source='builtin', name='Noctalia')
        self.theme('sync-bar')
        self.assertEqual(self.bar.resolve(), self.bars / 'default.toml')
        self.assertEqual(self.calls(), [])


@unittest.skipUnless(shutil.which('jq'), 'needs jq')
class PomodoroWidgetTests(unittest.TestCase):
    """Exercise the adapter with timer output without touching the live timer."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='pomodoro-widget-test-')
        self.home = Path(self.temp.name)
        module = self.home / '.config/waybar/scripts/pomodoro.sh'
        module.parent.mkdir(parents=True)
        module.write_text('#!/bin/sh\nprintf "%s\\n" "$POMODORO_TEST_JSON"\n')
        module.chmod(0o755)

    def tearDown(self):
        self.temp.cleanup()

    def widget(self, state, text='', quiet=False):
        env = dict(os.environ, HOME=str(self.home),
                   POMODORO_TEST_JSON=json.dumps({'class': state, 'text': text}))
        result = subprocess.run([str(NOCTALIA / 'scripts/pomodoro-widget'),
                                 *(['quiet'] if quiet else [])], env=env,
                                capture_output=True, text=True, timeout=10, check=True)
        return json.loads(result.stdout)

    def test_timer_states_keep_the_countdown_and_use_theme_roles(self):
        for state, glyph, color in (('work', 'hourglass-high', 'primary'),
                                    ('break', 'coffee', 'secondary'),
                                    ('paused', 'player-pause', 'on_surface_variant')):
            with self.subTest(state=state):
                output = self.widget(state, '\U000f0001 12:34', quiet=True)
                self.assertEqual(output['text'], '12:34')
                self.assertEqual((output['glyph'], output['glyphColor']), (glyph, color))
                self.assertTrue(output['visible'])
                self.assertIn(['Left: start | Right: pause/resume', ''], output['tips'])

    def test_minimal_bars_hide_only_the_idle_timer(self):
        self.assertFalse(self.widget('standby', quiet=True)['visible'])
        self.assertTrue(self.widget('standby')['visible'])
        self.assertTrue(self.widget('paused', quiet=True)['visible'])

    def test_an_unknown_state_is_visible_as_an_error(self):
        output = self.widget('unexpected', quiet=True)
        self.assertTrue(output['visible'])
        self.assertEqual((output['glyph'], output['glyphColor']), ('alert-triangle', 'error'))


@unittest.skipUnless(shutil.which('mango') and shutil.which('kitty') and shutil.which('noctalia'),
                     'needs mango, kitty and noctalia')
class ConfigTests(unittest.TestCase):
    """The repo's configs parse with and without the colour files Noctalia generates."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='theme-config-test-')
        root = Path(self.temp.name)
        self.home = root / 'home'
        shutil.copytree(REPO / '.config/mango', self.home / '.config/mango',
                        ignore=shutil.ignore_patterns('noctalia.conf', '*.bak*'))
        shutil.copytree(REPO / '.config/kitty', self.home / '.config/kitty',
                        ignore=shutil.ignore_patterns('themes'))
        shutil.copytree(NOCTALIA, self.home / '.config/noctalia', symlinks=True)
        self.runtime = root / 'runtime'
        self.runtime.mkdir(mode=0o700)  # keeps mango's error log private
        self.env = dict(os.environ, HOME=str(self.home), XDG_RUNTIME_DIR=str(self.runtime),
                        XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_STATE_HOME=str(root / 'state'))

    def tearDown(self):
        self.temp.cleanup()

    def render(self, template, output):
        palette = NOCTALIA / 'palettes/catppuccin-macchiato.json'
        subprocess.run(['noctalia', 'theme', '--theme-json', str(palette), '-r', f'{template}:{output}'],
                       env=self.env, capture_output=True, check=True, timeout=30)

    def mango_errors(self):
        result = subprocess.run(['mango', '-c', str(self.home / '.config/mango/config.conf'), '-p'],
                                env=self.env, capture_output=True, text=True, timeout=30)
        return result.returncode, (result.stdout + result.stderr).strip()

    def kitty_colours(self):
        probe = ('import sys; from kitty.config import load_config; bad = []; '
                 'opts = load_config(sys.argv[-1], accumulate_bad_lines=bad); '
                 'print(len(bad), opts.background.as_sharp, opts.color1.as_sharp)')
        result = subprocess.run(['kitty', '+runpy', probe, str(self.home / '.config/kitty/kitty.conf')],
                                env=self.env, capture_output=True, text=True, timeout=30)
        return result.stdout.split()

    def test_noctalia_config_is_valid(self):
        config = self.home / '.config/noctalia'
        for layout in sorted((config / 'bars').glob('*.toml')):
            with self.subTest(layout=layout.stem):
                (config / 'bar.toml').unlink(missing_ok=True)
                (config / 'bar.toml').symlink_to(f'bars/{layout.name}')
                result = subprocess.run(['noctalia', 'config', 'validate', str(config)],
                                        env=self.env, capture_output=True, text=True, timeout=30)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertNotIn('WARN', result.stdout + result.stderr)

    def test_theme_switches_keep_popup_placement_and_clearance(self):
        config = self.home / '.config/noctalia'
        # Export the real merged config: syntax validation alone misses a
        # shared setting that silently overrides the active bar's settings.
        for theme in ('tokyo-night', 'ultra-dark', 'catppuccin-macchiato',
                      'default', 'tokyo-night'):
            with self.subTest(theme=theme):
                (config / 'bar.toml').unlink(missing_ok=True)
                (config / 'bar.toml').symlink_to(f'bars/{theme}.toml')
                result = subprocess.run(['noctalia', 'config', 'export', 'full'],
                                        env=self.env, capture_output=True, text=True,
                                        check=True, timeout=30)
                effective = tomllib.loads(result.stdout)
                bottom = theme == 'tokyo-night'
                self.assertEqual(effective['osd']['position'],
                                 'bottom_center' if bottom else 'top_center')
                self.assertEqual(effective['osd']['offset_y'], 56 if bottom else 8)
                self.assertEqual(effective['notification']['position'],
                                 'bottom_right' if bottom else 'top_right')

    def test_mango_config_parses_without_and_with_the_generated_colours(self):
        self.assertEqual(self.mango_errors(), (0, ''))
        self.render(NOCTALIA / 'templates/mango.conf', self.home / '.config/mango/noctalia.conf')
        self.assertEqual(self.mango_errors(), (0, ''))  # any unknown key would raise Mango's error bar

    def test_kitty_config_parses_without_and_with_the_generated_colours(self):
        self.assertEqual(self.kitty_colours(), ['0', '#000000', '#f07178'])  # the fallback palette
        self.render('/usr/share/noctalia/assets/templates/kitty/kitty.conf',
                    self.home / '.config/kitty/themes/noctalia.conf')
        self.assertEqual(self.kitty_colours(), ['0', '#24273a', '#ed8796'])


if __name__ == '__main__':
    unittest.main()
