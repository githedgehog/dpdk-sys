# Build Plan

## Build matrix

\`\`\`yml
$(yq --yaml-output '.matrix' builds.yml)
\`\`\`

## Raw build flags file

\`\`\`yml
$(< ./nix/flags.nix)
\`\`\`

## Build versions

### env

\`\`\`yml
$(yq --yaml-output '.env' builds.yml)
\`\`\`

<details>
<summary>

## Raw \`builds.yml\` file

</summary>

\`\`\`yml
$(< builds.yml)
\`\`\`

</details>

<details>
<summary>

## Raw \`versions.nix\` file

</summary>

\`\`\`nix
$(< nix/versions.nix)
\`\`\`

</details>

EOF
