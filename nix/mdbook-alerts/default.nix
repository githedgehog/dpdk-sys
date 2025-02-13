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
  version = "0.7.0";

  src = fetchFromGitHub {
    inherit owner;
    repo = pname;
    rev = "v${version}";
    hash = "sha256-MZS9TESITj3tzdaXYu5S2QUCW7cZuTpH1skFKeVi/sQ";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-ZL8M9Ces8qs8ClayjJTt5FvlG+WcRpJLuZBNATEbLtQ=";

  meta = {
    description = "mdBook preprocessor to add GitHub Flavored Markdown's Alerts to your book";
    mainProgram = "mdbook-alerts";
    homepage = "https://github.com/${owner}/${pname}";
  };
}
