import math
import time


def generate_grid(nx=50, ny=50, size=50.0):
    # nx, ny = quads along X and Y
    verts = []
    faces = []
    dx = size / nx
    dy = size / ny
    # origin at (-size/2, 0, -size/2)
    x0 = -size / 2.0
    y0 = -size / 2.0
    # generate vertices row-major
    for j in range(ny + 1):
        for i in range(nx + 1):
            x = x0 + i * dx
            z = y0 + j * dy
            verts.extend([x, 0.0, z])
    def vid(i, j):
        return j * (nx + 1) + i
    for j in range(ny):
        for i in range(nx):
            v0 = vid(i, j)
            v1 = vid(i + 1, j)
            v2 = vid(i + 1, j + 1)
            v3 = vid(i, j + 1)
            # two triangles per quad, as triangles
            faces.extend([3, v0, v1, v2])
            faces.extend([3, v0, v2, v3])
    return verts, faces


def main():
    import Py310RecastDetour as navmod

    verts, faces = generate_grid(nx=64, ny=64, size=64.0)
    nm = navmod.Navmesh()
    nm.init_by_raw(verts, faces)

    # Use defaults akin to Sample::resetCommonSettings
    settings = nm.get_settings()
    nm.set_settings(settings)
    nm.set_partition_type(0)

    t0 = time.perf_counter()
    nm.build_navmesh()
    build_ms = (time.perf_counter() - t0) * 1000.0
    print("Build took (ms):", round(build_ms, 2))
    print(nm.get_log())

    # Try a path across the grid
    start = [-20.0, 0.0, -20.0]
    end = [20.0, 0.0, 20.0]
    t1 = time.perf_counter()
    path = nm.pathfind_straight(start, end)
    query_ms = (time.perf_counter() - t1) * 1000.0
    print("Path points:", len(path) // 3)
    print("Path took (ms):", round(query_ms, 2))
    if path:
        print("First:", path[:3], "Last:", path[-3:])


if __name__ == "__main__":
    main()


