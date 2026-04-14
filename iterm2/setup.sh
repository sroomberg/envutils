#!/bin/bash

cp ./sr.zsh-theme ~/.oh-my-zsh/themes/

sed -i 's/ZSH_THEME=.*/ZSH_THEME="sr"' ~/.zshrc