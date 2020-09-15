import setuptools

with open("README.md", encoding="utf8") as f:
    readme = f.read()


setuptools.setup(
    name="jupyter_pluto_proxy",
    version="0.1",
    url="https://github.com/hdrake/ClimateWidgets",
    author="Fons van der Plas",
    license="BSD",
    description="Pluto extension for Jupyter",
    long_description=readme,
    long_description_content_type="text/markdown",
    packages=setuptools.find_packages(),
    keywords=["Jupyter", "Pluto", "editor"],
    classifiers=["Framework :: Jupyter"],
    install_requires=[
        'jupyter-server-proxy'
    ],
    entry_points={
        "jupyter_serverproxy_servers": ["pluto = jupyter_pluto_proxy:setup_pluto",]
    },
    package_data={"jupyter_pluto_proxy": ["icons/*"]},
    project_urls={
        "Source": "https://github.com/hdrake/ClimateWidgets/",
        "Tracker": "https://github.com/hdrake/ClimateWidgets/issues",
    },
)
