ARG IMAGE=scratch
FROM ${IMAGE} AS frr
FROM ${IMAGE} AS doc-env
FROM ${IMAGE} AS libc-env
FROM ${IMAGE} AS mstflint
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
