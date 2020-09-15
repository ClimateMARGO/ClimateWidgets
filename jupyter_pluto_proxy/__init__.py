import os


def setup_pluto():
    def _get_pluto_cmd(port):
        return ["julia", "-e", "import Pkg; Pkg.add(Pkg.PackageSpec(;name=\"Pluto\", rev=\"ced3faf\")); import Pluto; Pluto.run(\"0.0.0.0\", " + str(port) + ")"]

    return {
        "command": _get_pluto_cmd,
        "timeout": 300,
        "new_browser_tab": True,
        "launcher_entry": {
            "title": "Pluto.jl",
            "icon_path": os.path.join(
                os.path.dirname(os.path.abspath(__file__)), "icons", "pluto.svg"
            ),
        },
    }
