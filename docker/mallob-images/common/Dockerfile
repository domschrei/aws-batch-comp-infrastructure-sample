################### Build Mallob
FROM satcomp-infrastructure:common
USER root
#  Install required softwares
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt install -y cmake build-essential zlib1g-dev libopenmpi-dev wget unzip build-essential zlib1g-dev cmake python3 build-essential gfortran wget curl libjemalloc-dev libjemalloc2 gdb psmisc

# Fetch Mallob
RUN wget -nc https://github.com/domschrei/mallob/archive/d126df06ed018ba8cfe23234ca9fdd9132aedf15.zip -O mallob.zip
RUN unzip mallob.zip
RUN mv mallob-*/ mallob
# Fetch and build solver backends
RUN cd mallob/lib && bash fetch_and_build_solvers.sh klcy
# disable building test classes to save time & energy
RUN cd mallob && sed -i 's/^new_test.*$//g' CMakeLists.txt src/app/sat/setup.cmake
# Build Mallob
RUN cd mallob && mkdir -p build && cd build \
  && cmake -DCMAKE_BUILD_TYPE=RELEASE \
    -DMALLOB_SUBPROC_DISPATCH_PATH='"./"' -DMALLOB_ASSERT=1 -DMALLOB_USE_GLUCOSE=0 \
    -DMALLOB_USE_ASAN=0 -DMALLOB_USE_JEMALLOC=1 -DMALLOB_JEMALLOC_DIR=/usr/lib/x86_64-linux-gnu \
    -DMALLOB_LOG_VERBOSITY=3 -DMALLOB_CERTIFIED_UNSAT=0 -DMALLOB_APP_SAT=1 -DMALLOB_APP_KMEANS=0 \
    -DMALLOB_MAX_N_APPTHREADS_PER_PROCESS=64 .. \
  && VERBOSE=1 make -j \
  && cd ..
