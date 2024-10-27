ARG TAG="latest"
FROM ghcr.io/githedgehog/dpdk-sys/compile-env:${TAG} AS compile-env
FROM ghcr.io/githedgehog/dpdk-sys/dev-env:${TAG} AS dev-env
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

# I can't properly set permissions in nix because of the way it works.
# So I have to do this hacky thing to get sudo to work.
# Also, ldconfig breaks in nix settings.
# Normally that doesn't matter but it is called by vscode in the dev container
# so we need to remove it to make that work.
RUN chmod 777 /tmp \
 && chmod 4755 /sbin/sudo \
 && chmod 555 /etc/pam.d \
 && chmod -R 444 /etc/pam.d/* \
 && chmod 444 /etc/group \
 && chmod 444 /etc/passwd \
 && rm /bin/ldconfig \
 && mkdir -p /home/runner \
 && chown -R runner:runner /home/runner

USER runner
CMD ["/bin/bash", "--login"]
