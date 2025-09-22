import os
import time


def write_plane_obj(path: str, size: float = 50.0):
    half = size / 2.0
    with open(path, "w") as f:
        f.write("o plane\n")
        f.write(f"v {-half} 0 {-half}\n")
        f.write(f"v {half} 0 {-half}\n")
        f.write(f"v {half} 0 {half}\n")
        f.write(f"v {-half} 0 {half}\n")
        # Two triangles (1-indexed in OBJ)
        f.write("f 1 2 3\n")
        f.write("f 1 3 4\n")


def main():
    import PyRecastDetour as navmod

    # Use the same input geometry as the C++ demo ships with
    candidates = [
        "/app/Meshes/nav_test.obj",
        "/app/Meshes/undulating.obj",
        "/app/Meshes/dungeon.obj",
    ]
    nm = navmod.Navmesh()
    for p in candidates:
        try:
            nm.init_by_obj(p)
            obj_path = p
            break
        except Exception:
            continue

    # Use SoloMesh defaults close to RecastDemo defaults
    settings = nm.get_settings()
    # These mirror Sample::resetCommonSettings defaults
    settings["cellSize"] = 0.3
    settings["cellHeight"] = 0.2
    settings["agentHeight"] = 2.0
    settings["agentRadius"] = 0.6
    settings["agentMaxClimb"] = 0.9
    settings["agentMaxSlope"] = 45.0
    settings["regionMinSize"] = 8
    settings["regionMergeSize"] = 20
    settings["edgeMaxLen"] = 12.0
    settings["edgeMaxError"] = 1.3
    settings["vertsPerPoly"] = 6.0
    settings["detailSampleDist"] = 6.0
    settings["detailSampleMaxError"] = 1.0
    nm.set_settings(settings)
    # Try watershed (0) like default demo; if it fails, switch to monotone (1)
    nm.set_partition_type(0)

    t0 = time.perf_counter()
    nm.build_navmesh()
    build_ms = (time.perf_counter() - t0) * 1000.0

    log = nm.get_log()
    print("Build took (ms):", round(build_ms, 2))
    print(log)

    if "Could not build Detour navmesh" in log or "Fail to build navmesh" in log:
        # Relax settings and retry: monotone partitioning and smaller regions
        settings = nm.get_settings()
        settings["regionMinSize"] = 0
        settings["regionMergeSize"] = 0
        settings["detailSampleDist"] = 0.0
        settings["detailSampleMaxError"] = 0.0
        nm.set_settings(settings)
        nm.set_partition_type(1)
        t0 = time.perf_counter()
        nm.build_navmesh()
        build_ms = (time.perf_counter() - t0) * 1000.0
        print("Retry (monotone) build took (ms):", round(build_ms, 2))
        print(nm.get_log())

    # Query a path diagonally across the plane
    start = [-20.0, 0.0, -20.0]
    end = [20.0, 0.0, 20.0]
    t1 = time.perf_counter()
    path = nm.pathfind_straight(start, end)
    query_ms = (time.perf_counter() - t1) * 1000.0
    print("Path points:", len(path) // 3)
    print("Path took (ms):", round(query_ms, 2))
    # Show first/last points for sanity
    if path:
        print("First:", path[:3], "Last:", path[-3:])


if __name__ == "__main__":
    main()


