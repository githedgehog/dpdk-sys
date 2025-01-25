ARG IMAGE=scratch
FROM ${IMAGE} AS frr
# size reduction hack
RUN for frr in /nix/store/*-frr-*; do \
  ln -s "${frr}" "$(sed 's|/nix/store/.*-\(.*-frr-.*\)|/nix/store/\1|' <<<"${frr}")"; \
done
FROM ${IMAGE} AS doc-env
FROM ${IMAGE} AS compile-env
CMD ["/bin/bash", "--login"]
