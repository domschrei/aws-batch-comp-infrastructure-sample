################### Use Mallob
FROM satcomp-mallob:common AS builder
USER root

################### Extract Mallob in run stage
FROM satcomp-infrastructure:worker AS mallob_liaison
WORKDIR /

USER root
RUN DEBIAN_FRONTEND=noninteractive apt install -y libjemalloc-dev libjemalloc2 gdb psmisc

# Copy mallob
COPY --from=builder /mallob/build/mallob mallob
COPY --from=builder /mallob/build/mallob_sat_process mallob_sat_process
COPY --from=builder /mallob/build/mallob_process_dispatcher mallob_process_dispatcher

COPY --chown=ecs-user /init_mallob.sh /competition
COPY --chown=ecs-user /worker /competition
USER ecs-user
RUN chmod +x /competition/init_mallob.sh
RUN chmod +x /competition/worker
