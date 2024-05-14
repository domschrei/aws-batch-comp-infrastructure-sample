################### Use Mallob
FROM satcomp-mallob:common AS builder
USER root

################### Extract Mallob in run stage
FROM satcomp-infrastructure:leader AS mallob_liaison

#  Install required softwares
USER root
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt install -y libjemalloc-dev libjemalloc2 gdb bc

WORKDIR /

# Copy mallob and related executables
COPY --from=builder /mallob/build/mallob mallob
COPY --from=builder /mallob/build/mallob_sat_process mallob_sat_process
COPY --from=builder /mallob/build/mallob_process_dispatcher mallob_process_dispatcher
COPY --from=builder /mallob/impcheck/build/impcheck_parse impcheck_parse
COPY --from=builder /mallob/impcheck/build/impcheck_check impcheck_check
COPY --from=builder /mallob/impcheck/build/impcheck_confirm impcheck_confirm

COPY --chown=ecs-user /init_solver.sh /competition
COPY --chown=ecs-user /run_solver.sh /competition
COPY --chown=ecs-user /solver /competition

USER ecs-user
RUN chmod +x /competition/init_solver.sh
RUN chmod +x /competition/run_solver.sh
RUN chmod +x /competition/solver
