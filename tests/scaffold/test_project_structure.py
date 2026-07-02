from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


class ProjectStructureTest(unittest.TestCase):
    def read(self, relative_path: str) -> str:
        return (ROOT / relative_path).read_text(encoding="utf-8")

    def test_project_has_main_scene_autoloads_and_input_actions(self):
        project = self.read("project.godot")

        self.assertIn('run/main_scene="res://scenes/main/Main.tscn"', project)
        self.assertIn('GameState="*res://scripts/autoload/GameState.gd"', project)
        self.assertIn('EventBus="*res://scripts/autoload/EventBus.gd"', project)
        self.assertIn('SceneLoader="*res://scripts/autoload/SceneLoader.gd"', project)

        for action in [
            "move_left",
            "move_right",
            "move_up",
            "move_down",
            "pause",
            "confirm",
            "cancel",
        ]:
            self.assertIn(f'{action}={{', project)

    def test_required_directories_exist(self):
        for relative_path in [
            "assets/art",
            "assets/audio",
            "assets/fonts",
            "assets/materials",
            "debug",
            "scenes/main",
            "scenes/game",
            "scenes/player",
            "scenes/ui",
            "scripts/autoload",
            "scripts/components",
            "scripts/resources",
            "scripts/main",
            "scripts/game",
            "scripts/player",
            "scripts/ui",
        ]:
            self.assertTrue((ROOT / relative_path).is_dir(), relative_path)

    def test_required_scenes_and_scripts_exist(self):
        for relative_path in [
            "scenes/main/Main.tscn",
            "scenes/game/Game.tscn",
            "scenes/player/Player.tscn",
            "scenes/ui/HUD.tscn",
            "scenes/ui/PauseMenu.tscn",
            "scripts/main/main.gd",
            "scripts/game/game.gd",
            "scripts/player/player.gd",
            "scripts/ui/hud.gd",
            "scripts/ui/pause_menu.gd",
            "scripts/autoload/GameState.gd",
            "scripts/autoload/EventBus.gd",
            "scripts/autoload/SceneLoader.gd",
        ]:
            self.assertTrue((ROOT / relative_path).is_file(), relative_path)

    def test_scene_script_references_are_present(self):
        expected_references = {
            "scenes/main/Main.tscn": "res://scripts/main/main.gd",
            "scenes/game/Game.tscn": "res://scripts/game/game.gd",
            "scenes/player/Player.tscn": "res://scripts/player/player.gd",
            "scenes/ui/HUD.tscn": "res://scripts/ui/hud.gd",
            "scenes/ui/PauseMenu.tscn": "res://scripts/ui/pause_menu.gd",
        }

        for scene_path, script_path in expected_references.items():
            self.assertIn(script_path, self.read(scene_path))

    def test_game_scene_contains_player_hud_and_pause_menu(self):
        scene = self.read("scenes/game/Game.tscn")

        self.assertIn("res://scenes/player/Player.tscn", scene)
        self.assertIn("res://scenes/ui/HUD.tscn", scene)
        self.assertIn("res://scenes/ui/PauseMenu.tscn", scene)


if __name__ == "__main__":
    unittest.main()
