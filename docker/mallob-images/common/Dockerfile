################### Build Mallob
FROM satcomp-infrastructure:common
USER root
#  Install required softwares
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt install -y cmake build-essential zlib1g-dev libopenmpi-dev wget unzip build-essential zlib1g-dev cmake python3 build-essential gfortran wget curl libjemalloc-dev libjemalloc2 gdb psmisc

# Fetch Mallob
RUN git clone https://github.com/domschrei/mallob && cd mallob && git checkout concurrency && git checkout 6b2a8c5597a2481b3baa00af9c652eb020cefaae
# Download CaDiCaL from git directly
RUN cd mallob/lib && git clone https://github.com/domschrei/cadical && cd cadical && git checkout 20a9484
# Fetch remaining solvers, build all of them
RUN cd mallob/lib && bash fetch_and_build_sat_solvers.sh klcy
RUN cd mallob && sed -i 's/^new_test.*$//g' CMakeLists.txt
# Build Mallob
RUN cd mallob && mkdir -p build && cd build \
  && cmake -DCMAKE_BUILD_TYPE=RELEASE \
    -DMALLOB_SUBPROC_DISPATCH_PATH='"./"' -DMALLOB_ASSERT=1 -DMALLOB_USE_GLUCOSE=0 \
    -DMALLOB_USE_ASAN=0 -DMALLOB_USE_JEMALLOC=1 -DMALLOB_JEMALLOC_DIR=/usr/lib/x86_64-linux-gnu \
    -DMALLOB_LOG_VERBOSITY=3 -DMALLOB_CERTIFIED_UNSAT=0 -DMALLOB_APP_SAT=1 -DMALLOB_APP_KMEANS=0 \
    -DMALLOB_MAX_N_APPTHREADS_PER_PROCESS=32 .. \
  && VERBOSE=1 make -j \
  && cd ..
