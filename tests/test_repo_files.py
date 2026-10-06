"""Files Godot generates that the repository must carry. Every script and shader has a
committed `.uid`: without one, the first import on the owner's Mac writes it as an
untracked file, and the play-folder sync (tools/mac/ngu-sync.sh) then reads the
folder as changed, keeps it on a backup branch and reports an update that wasn't."""
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class RepoFilesTests(unittest.TestCase):
    def test_every_script_has_its_uid_committed(self):
        tracked = set(subprocess.run(['git', 'ls-files'], cwd=ROOT, capture_output=True, text=True, check=True).stdout.split('\n'))
        missing = sorted(path for path in tracked if path.endswith(('.gd', '.gdshader')) and path + '.uid' not in tracked)
        self.assertEqual(missing, [], 'commit the .uid Godot writes beside each new script (open the project or run '
                                      '`bash run_godot.sh --headless --path . --import`, then `git add` it)')


if __name__ == '__main__':
    unittest.main()
