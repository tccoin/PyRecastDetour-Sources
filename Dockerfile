# syntax=docker/dockerfile:1.6

ARG PY_VER=3.10
ARG TARGETPLATFORM=linux/amd64

FROM python:${PY_VER}-slim-bullseye AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG PY_VER
ARG TARGETPLATFORM

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential cmake git pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# Copy source
COPY . /work

# Install Python deps for building the extension
RUN python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir pybind11

# Build recastnavigation static libraries (clear any host cache dir first)
RUN rm -rf third_party/recastnavigation/build \
    && cmake -S third_party/recastnavigation -B third_party/recastnavigation/build -DCMAKE_BUILD_TYPE=Release \
    -DRECASTNAVIGATION_DEMO=OFF -DRECASTNAVIGATION_TESTS=OFF -DRECASTNAVIGATION_EXAMPLES=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC" \
    -DRECASTNAVIGATION_ENABLE_ASSERTS=ON \
    && cmake --build third_party/recastnavigation/build --config Release -j

# Build PyBind11 extension
RUN set -eux; \
    EXT_SUFFIX=$(python -c 'import sysconfig;print(sysconfig.get_config_var("EXT_SUFFIX"))'); \
    MAJOR=$(python -c 'import sys;print(sys.version_info.major)'); \
    MINOR=$(python -c 'import sys;print(sys.version_info.minor)'); \
    MODNAME=PyRecastDetour; \
    CPP_DEFS=""; \
    if [ "$MAJOR" = "3" ] && [ "$MINOR" = "6" ]; then CPP_DEFS="-D_Python36"; fi; \
    if [ "$MAJOR" = "3" ] && [ "$MINOR" = "7" ]; then CPP_DEFS="-D_Python37"; fi; \
    if [ "$MAJOR" = "3" ] && [ "$MINOR" = "8" ]; then CPP_DEFS="-D_Python38"; fi; \
    if [ "$MAJOR" = "3" ] && [ "$MINOR" = "9" ]; then CPP_DEFS="-D_Python39"; fi; \
    PYBIND_INCLUDES=$(python -m pybind11 --includes); \
    mkdir -p /work/build /work/dist; \
    cc -O3 -fPIC -c /work/src/Contrib/fastlz/fastlz.c -o /work/build/fastlz.o; \
    g++ -O3 -std=c++14 -fPIC -shared -Wl,--no-as-needed \
    -static-libstdc++ -static-libgcc \
    $CPP_DEFS \
    $PYBIND_INCLUDES \
    -I/work/src \
    -I/work/third_party/recastnavigation/Recast/Include \
    -I/work/third_party/recastnavigation/Detour/Include \
    -I/work/third_party/recastnavigation/DetourCrowd/Include \
    -I/work/third_party/recastnavigation/DetourTileCache/Include \
    -I/work/third_party/recastnavigation/DebugUtils/Include \
    /work/src/PyRecastDetour.cpp \
    /work/src/Navmesh.cpp \
    /work/src/InputGeom.cpp \
    /work/src/MeshLoaderObj.cpp \
    /work/src/SampleInterfaces.cpp \
    /work/src/Sample_SoloMesh.cpp \
    /work/src/Sample_TileMesh.cpp \
    /work/src/Sample_TempObstacles.cpp \
    /work/src/Sample.cpp \
    /work/src/Sample_Debug.cpp \
    /work/src/NavMeshTesterTool.cpp \
    /work/src/NavMeshPruneTool.cpp \
    /work/src/ConvexVolumeTool.cpp \
    /work/src/CrowdTool.cpp \
    /work/src/ChunkyTriMesh.cpp \
    /work/src/PerfTimer.cpp \
    /work/src/ValueHistory.cpp \
    /work/build/fastlz.o \
    /work/third_party/recastnavigation/build/Recast/libRecast.a \
    /work/third_party/recastnavigation/build/DetourTileCache/libDetourTileCache.a \
    /work/third_party/recastnavigation/build/DetourCrowd/libDetourCrowd.a \
    /work/third_party/recastnavigation/build/DebugUtils/libDebugUtils.a \
    /work/third_party/recastnavigation/build/Detour/libDetour.a \
    -lm \
    -o /work/dist/${MODNAME}${EXT_SUFFIX}

# Runtime image: include Python to run tests/examples; copy built artifact only
FROM python:${PY_VER}-slim-bullseye AS runtime
ARG PY_VER
WORKDIR /app
COPY --from=builder /work/dist /app/dist
COPY tests /app/tests
COPY --from=builder /work/third_party/recastnavigation/RecastDemo/Bin/Meshes /app/Meshes
ENV PYTHONPATH=/app/dist
CMD ["python", "-c", "import sys,glob;print('Artifacts:',glob.glob('/app/dist/*')); import PyRecastDetour as m; print('Loaded:',m)"]


