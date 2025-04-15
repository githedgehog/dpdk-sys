ARG IMAGE=scratch
FROM ${IMAGE} AS frr
FROM ${IMAGE} AS doc-env
FROM ${IMAGE} AS compile-env
CMD ["/bin/bash", "--login"]
