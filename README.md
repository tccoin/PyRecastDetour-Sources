Source files of the [PyRecastDetour](https://github.com/Tugcga/PyRecastDetour) module for Python. It use [PyBind11](https://github.com/pybind/pybind11) for bindings and based on default example application from original [Recast Navigation](https://github.com/recastnavigation/recastnavigation) repository. Release page contains [archive](https://github.com/Tugcga/PyRecastDetour-Sources/releases/download/v.1.0/include_libs.zip) with required libraries and include files.

## Docker build (parametrized)

This repository includes a Dockerfile to build the extension for a specific Python version and platform.

- Build args:
  - `PY_VER` (default `3.10`)
  - `TARGETPLATFORM` (default `linux/amd64`)

### Build

```bash
docker build \
  --build-arg PY_VER=3.10 \
  --platform=linux/amd64 \
  -t pyrecastdetour:py310-amd64 .
```

### Run and test

```bash
docker run --rm -it pyrecastdetour:py310-amd64
# or run the test script
docker run --rm -it pyrecastdetour:py310-amd64 python /app/tests/solo_demo.py
```

Artifacts will be placed in `/app/dist` inside the container runtime (built in `/work/dist` during the build stage).

### Extract and install the built library

Copy the built `.so` out of the container and install it locally (adjust container tag if you changed args):

```bash
# Copy artifact to host
cid=$(docker create pyrecastdetour:py310-amd64)
docker cp "$cid:/app/dist/." ./dist
docker rm "$cid"

# Install system-wide (or place on your PYTHONPATH)
sudo mkdir -p /usr/local/lib/python3.10/site-packages
sudo cp dist/Py310RecastDetour*.so /usr/local/lib/python3.10/site-packages/

# Test import on host
python3.10 -c "import Py310RecastDetour as m; print(m, 'OK')"
```

## Example usage (Python 3.10)

```python
import Py310RecastDetour as navmod

nm = navmod.Navmesh()
vertices = [
    0.0, 0.0, 0.0,
    1.0, 0.0, 0.0,
    1.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
]
faces = [0, 1, 2, 0, 2, 3]

nm.init_by_raw(vertices, faces)
nm.build_navmesh()
print(nm.get_bounding_box())
print(nm.pathfind_straight([0.1,0.0,0.1],[0.9,0.0,0.9]))
```

If you need a different Python minor version (e.g., 3.8), adjust `PY_VER` during `docker build`. The module name is selected at compile time to match the Python version (`Py36RecastDetour`, `Py37RecastDetour`, `Py38RecastDetour`, `Py39RecastDetour`, `Py310RecastDetour`).
