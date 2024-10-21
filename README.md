# dpdk-sys

[Nix][`nix`] build suite for a rust + dpdk toolchain.

## Building the toolchains

### Requirements:

1. <details>
   <summary>
   <a href="https://github.com/casey/just">
   <code>just</code>
   </a>
   </summary>
   
   1. If you have [`cargo`]:
      ```bash
      cargo install just
      ```
   2. use your package manager (but ensure a recent version of `just`)
   </details>

2. <details>
   <summary>
   <a href="https://nixos.org/nix/">
   <code>nix</code>
   </a>
   </summary>

   Single user `nix` (which I recommend) can be installed with:
   ```bash
   sudo mkdir -m 0755 -p /nix
   sudo chown "$(id -u):$(id -g)" /nix
   sh <(curl -L https://nixos.org/nix/install) --no-daemon
   ```
   </details>

3. <details>
   <summary>
   <a href="https://www.docker.com/">
   <code>docker</code>
   </a>
   </summary>

   1. Install `docker` via a package manager.
   2. The user you are running the build as needs to be in the `docker` group (or be root).
   </details>
   
4. <details>
   <summary>
   <a href="https://www.gnu.org/software/bash/"></a><code>bash</code></a> or some other POSIX shell (with `set -euo pipefail`)
   </summary>
   
   Whatever implementation of `sh` you have is fine so long as it supports

   1. `set -e` (exit on error)
   2. `set -u` (exit on undefined variable)
   3. `set -o pipefail` (exit on error in a pipeline)

   You very likely already have [`bash`] or [`busybox`] which supports these flags.

   Unfortunately, `sh` as it exists in CI does not support these flags, so we need to specify `bash` in the `justfile` ¯\_(ツ)_/¯
   </details>


<!-- Links -->
[POSIX]: https://en.wikipedia.org/wiki/POSIX
[`bash`]: https://www.gnu.org/software/bash/
[`busybox`]: https://www.busybox.net/
[`cargo`]: https://doc.rust-lang.org/cargo/getting-started/installation.html
[`docker`]: https://www.docker.com/
[`just`]: https://github.com/casey/just
[`nix`]: https://nixos.org/nix/
