# Builds the mdbook-alerts package for use in the mdbook preprocessor
# I like this more than mdbook-admonish in that it uses the same syntax as
# github (which makes our docs more portable)
{
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  owner = "lambdalisue";
  pname = "rs-mdbook-alerts";
  version = "0.6.10";

  src = fetchFromGitHub {
    inherit owner;
    repo = pname;
    rev = "v${version}";
    hash = "sha256-xyjLrqNb/YC2FWQXsCFJgiIDZz4xWACnrUiBuXS2Nio";
  };

  cargoHash = "sha256-kzp1bpP4yHfu0BakN/O5OxdO/tLs/kWNmnaUopIlBVM";

  meta = {
    description = "mdBook preprocessor to add GitHub Flavored Markdown's Alerts to your book";
    mainProgram = "mdbook-alerts";
    homepage = "https://github.com/${owner}/${pname}";
  };
}
