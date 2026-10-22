#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-2.1-or-later

"""Check the public wrapper arguments without requiring a Docker engine."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class DevelopmentWrapperTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        (ROOT / "build").mkdir(exist_ok=True)
        cls.scratch = tempfile.TemporaryDirectory(prefix="dev-wrappers.", dir=ROOT / "build")
        cls.addClassCleanup(cls.scratch.cleanup)
        cls.work = Path(cls.scratch.name).resolve()
        cls.repository = cls.work / "repository with spaces"
        scripts = cls.repository / "docker/dev"
        scripts.mkdir(parents=True)
        for name in ("build", "run", "Dockerfile"):
            shutil.copy2(ROOT / "docker/dev" / name, scripts / name)
        cls.commands = cls.work / "commands"
        cls.commands.mkdir()
        docker = cls.commands / "docker"
        docker.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
Path(os.environ["ARCA_TEST_DOCKER_LOG"]).write_text(json.dumps(sys.argv[1:]))
''')
        identity = cls.commands / "id"
        identity.write_text('''#!/usr/bin/env python3
import os, sys
print(os.environ[{"-u": "ARCA_TEST_UID", "-g": "ARCA_TEST_GID"}[sys.argv[1]]])
''')
        docker.chmod(0o755)
        identity.chmod(0o755)

    def invoke(self, script, *arguments, uid="501"):
        self.log = self.work / "docker.json"
        self.log.unlink(missing_ok=True)
        environment = dict(os.environ, PATH=str(self.commands) + os.pathsep + os.environ["PATH"],
                           ARCA_TEST_DOCKER_LOG=str(self.log), ARCA_TEST_UID=uid,
                           ARCA_TEST_GID="20")
        return subprocess.run([str(self.repository / "docker/dev" / script), *arguments],
                              cwd=self.work, env=environment, input="",
                              capture_output=True, text=True, timeout=10)

    def docker_arguments(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.log.exists(), "Wrapper did not invoke the selected docker")
        return json.loads(self.log.read_text())

    def test_build_defaults_and_foreign_working_directory(self):
        arguments = self.docker_arguments(self.invoke("build"))
        self.assertEqual(arguments, ["build", "--platform", "linux/amd64",
                                     "--tag", "arca-dev:trixie", "--file",
                                     str(self.repository / "docker/dev/Dockerfile"),
                                     str(self.repository)])

    def test_build_explicit_platform_and_tag(self):
        for options in (("--platform", "linux/arm64", "--tag", "arca-test:arm64"),
                        ("--platform=linux/arm64", "--tag=arca-test:arm64")):
            with self.subTest(options=options):
                arguments = self.docker_arguments(self.invoke("build", *options))
                self.assertEqual(arguments[:5], ["build", "--platform", "linux/arm64",
                                                 "--tag", "arca-test:arm64"])

    def test_run_defaults_and_argument_boundaries(self):
        command = ("printf", "%s\\n", "one argument with spaces", "$HOME", "--help")
        arguments = self.docker_arguments(self.invoke("run", "arca-dev:trixie", *command))
        self.assertEqual(arguments[:7], ["run", "--platform", "linux/amd64", "--rm",
                                         "--user", "501:20", "--env"])
        self.assertIn("HOME=/tmp", arguments)
        self.assertIn(f"type=bind,source={self.repository},target=/work", arguments)
        self.assertEqual(arguments[-len(command) - 1:], ["arca-dev:trixie", *command])
        self.assertNotIn("--interactive", arguments)
        self.assertNotIn("--tty", arguments)

    def test_run_arm64_and_default_shell(self):
        for options in (("--platform", "linux/arm64"), ("--platform=linux/arm64",)):
            with self.subTest(options=options):
                arguments = self.docker_arguments(self.invoke("run", *options, "arca-test:arm64"))
                self.assertEqual(arguments[:3], ["run", "--platform", "linux/arm64"])
                self.assertIn("--interactive", arguments)
                self.assertNotIn("--tty", arguments)
                self.assertEqual(arguments[-2:], ["arca-test:arm64", "bash"])

    def test_root_requires_an_explicit_exception(self):
        result = self.invoke("run", "arca-dev:trixie", "true", uid="0")
        self.assertEqual(result.returncode, 1)
        self.assertIn("regular user", result.stderr)
        self.assertFalse(self.log.exists())
        arguments = self.docker_arguments(self.invoke("run", "--root", "arca-dev:trixie",
                                                       "true", uid="0"))
        self.assertIn("0:0", arguments)
        self.assertIn("HOME=/root", arguments)

    def test_help_and_invalid_options_do_not_invoke_docker(self):
        for script in ("build", "run"):
            with self.subTest(script=script):
                result = self.invoke(script, "--help", uid="0")
                self.assertEqual(result.returncode, 0)
                self.assertIn("Usage:", result.stdout)
                self.assertFalse(self.log.exists())
        cases = [("build", "--platform"), ("build", "--tag"),
                 ("build", "--tag="), ("build", "--platform=linux/s390x"),
                 ("build", "--platform", "--tag"), ("build", "--unknown"),
                 ("run",), ("run", "--platform"), ("run", "--platform="),
                 ("run", "--platform=linux/s390x", "arca-dev:trixie"),
                 ("run", "--unknown"), ("run", "")]
        for script, *options in cases:
            with self.subTest(script=script, options=options):
                result = self.invoke(script, *options)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn("Usage:", result.stderr)
                self.assertFalse(self.log.exists())


if __name__ == "__main__":
    unittest.main()
