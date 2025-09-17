ARG IMAGE=scratch
FROM ${IMAGE} AS frr-base
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN find / -name '*.a' -exec rm -f {} \;
RUN find / -name '*.la' -exec rm -f {} \;
RUN find / -name '*.h' -exec rm -f {} \;
RUN mkdir -p /run/frr/hh /var/run/frr/hh
RUN chown -R frr:frr /run/frr
RUN chown -R frr:frr /var/run/frr
# hack to deal with /usr/bin/python3 path in frr
RUN ln -s / /usr
FROM scratch AS frr-release
COPY --from=frr-base / /
CMD ["/libexec/frr/docker-start"]
FROM scratch AS frr-debug
COPY --from=frr-base / /
CMD ["/libexec/frr/docker-start"]
FROM ${IMAGE} AS doc-env
FROM ${IMAGE} AS libc-env
FROM ${IMAGE} AS debug-env
FROM ${IMAGE} AS mstflint-release
FROM ${IMAGE} AS mstflint-debug
FROM ${IMAGE} AS compile-env
# This sets up sudo to work in the compile env container
RUN echo "ALL ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dangerous \
    && chmod 0444 /etc/sudoers.d/dangerous \
    && chmod 4755 /sbin/sudo \
    && mkdir -p /etc/pam.d \
    && chmod 555 /etc/pam.d \
    && echo auth requisite pam_permit.so > /etc/pam.d/sudo \
    && echo account requisite pam_permit.so >> /etc/pam.d/sudo \
    && echo session requisite pam_permit.so >> /etc/pam.d/sudo \
    && chmod 444 /etc/pam.d/*

# Link the fuzz sysroot (same as the release sysroot)
RUN cd /sysroot/x86_64-unknown-linux-gnu \
    && ln -s ./release fuzz
