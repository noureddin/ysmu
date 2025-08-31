#!/bin/bash

__moving_commits() {  # grep all the commits that affect the given two files simultaneously
  git log --oneline -- "$1" | grep -Fx "$(git log --oneline -- "$2")" | sed 's/ .*/ /' | tr -d $"\n"  # has a trailing space
}

get_git_latest_moving_commit() {  # of a term; returns nothing if never moved
  local term="$1"
  local wanttime="$2"  # any thing makes it print the unix timestamp instead of the commit itself
  #
  local c=""  # output is joined directly b/c it has a trailing space
  c="$c$(__moving_commits "w/$term" "c/$term")"
  c="$c$(__moving_commits "w/$term" "x/$term")"
  c="$c$(__moving_commits "w/$term" "u/$term")"
  c="$c$(__moving_commits "c/$term" "x/$term")"
  c="$c$(__moving_commits "c/$term" "u/$term")"
  c="$c$(__moving_commits "x/$term" "u/$term")"
  #
  if [ -n "$c" ]; then  # a perfectly empty string when no commits match at all
    if [ -n "$wanttime" ]; then
      git log --pretty=%ct -1 $c
    else
      git log --oneline -1 $c
    fi
  fi
}


get_git_latest_moving_commit "$1" time
