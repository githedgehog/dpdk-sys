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
   <a href="https://www.gnu.org/software/bash/">
   <code>
   
   bash [^yes-bash]

   </code>
   </a>
   </summary>
   
   You very likely already have `bash`.
   If not, install it via a package manager.
   </details>


<!-- Footnotes -->
[^yes-bash]: It really needs to be `bash` and not just some [POSIX] `sh`. 
             The problem is that the `justfile` needs to set the shell explicitly to bash to get reasonable error handling.

<!-- Links -->
[`just`]: https://github.com/casey/just
[`nix`]: https://nixos.org/nix/
[`docker`]: https://www.docker.com/
[`bash`]: https://www.gnu.org/software/bash/
[POSIX]: https://en.wikipedia.org/wiki/POSIX
[`cargo`]: https://doc.rust-lang.org/cargo/getting-started/installation.html
