__bold=1
__prompt_env_color=99
__prompt_dir_color=116
__prompt_cmd_color=154
__prompt_root_cmd_color=160
_bold="\\033[${__bold}m"
_prompt_env_color="\\033[38;5;${__prompt_env_color}m"
_prompt_dir_color="\\033[38;5;${__prompt_dir_color}m"
_prompt_cmd_color="\\033[38;5;${__prompt_cmd_color}m"
_prompt_root_cmd_color="\\033[38;5;${__prompt_root_cmd_color}m"
_end_color="\\033[0m"
_red_if_root="\$(if [ \$(whoami) = root ]; then echo '${_prompt_root_cmd_color}'; else echo '${_prompt_cmd_color}'; fi)"
_sigil="\$(if [ \$(whoami) = root ]; then echo -e ＃; else echo ＄; fi)"
_env_propt="${_bold}${_prompt_env_color}⟪dataplane:dev-env:\$(whoami)⟫${_end_color}"
_pwd_prompt="${_bold}${_prompt_dir_color}⟪\$(pwd)⟫${_end_color}"
_cmd_prompt="${_bold}${_red_if_root}⟪$_sigil⟫${_end_color} "
export PS1="\n${_env_propt}\n${_pwd_prompt}\n${_cmd_prompt}"
