#!/usr/bin/env bash
# Open yazi in a new terminal starting in ~. On quit (Ctrl+O / q) the
# yazi() wrapper in ~/.zshrc cds, and the shell stays open in that folder.
# (Lives in a script because sway splits bindings on ';'.)
exec ghostty --working-directory=home -e zsh -ic 'yazi; exec zsh'
