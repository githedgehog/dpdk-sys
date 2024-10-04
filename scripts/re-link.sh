relink_file() {
  new_target="$(realpath -s --relative-to="$1" "$(readlink "$1")")"
  rm "$1"
  ln -sr "$new_target" "$1"
  rm "$1.bak"
}

relink_files() {
  find . -type l -lname '/nix/*' -exec relink_file {} \;
}
