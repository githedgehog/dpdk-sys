ARG IMAGE=scratch
FROM ${IMAGE} AS doc-env
FROM ${IMAGE} AS compile-env

# I can't properly set permissions in nix because of the way it works.
# So I have to do this hacky thing to get sudo to work.
RUN chmod 777 /tmp \
 && chmod 4755 /sbin/sudo \
 && chmod 555 /etc/pam.d \
 && chmod -R 444 /etc/pam.d/* \
 && chmod 444 /etc/group \
 && chmod 444 /etc/passwd \
 && mkdir -p /home/runner \
 && chown -R runner:runner /home/runner

USER runner
CMD ["/bin/bash", "--login"]
