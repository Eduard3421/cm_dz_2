#!/bin/bash

VISUALIZER_PATH=$1
REPO_PATH=$2
FILE_PATH=$3

cd $REPO_PATH

commits=$(git log --all --format=%H -- $FILE_PATH)

echo "@startuml" > dependencies.puml
echo "title Dependencies Graph" >> dependencies.puml

declare -A processed_authors
declare -A processed_commits

for commit in $commits; do
  author=$(git log -1 --format=%an $commit)
  date=$(git log -1 --format=%ad $commit)
  if [ -z "${processed_authors[$author]}" ]; then
    processed_authors[$author]="$author\n$date"
    echo "participant \"${processed_authors[$author]}\" as $commit" >> dependencies.puml
  fi
done

for commit in $commits; do
  if [ "${processed_commits[$commit]}" == "1" ]; then
    continue
  fi

  processed_commits[$commit]=1

  prev_commits=$(git log --format=%H --skip 1 --until=$commit --max-count=10)
  for prev_commit in $prev_commits; do
    if [ "${processed_commits[$prev_commit]}" != "1" ]; then
      processed_commits[$prev_commit]=1

      if ! grep -q "$prev_commit -> $commit" dependencies.puml; then
        echo "$prev_commit -> $commit" >> dependencies.puml
      fi
    fi
  done
done

echo "@enduml" >> dependencies.puml

if ! $VISUALIZER_PATH -checkonly dependencies.puml; then
  echo "Syntax error in dependencies.puml. Please check the file manually."
  exit 1
fi

# Визуализация графа
$VISUALIZER_PATH dependencies.puml -o dependencies.png

$VISUALIZER_PATH dependencies.puml -o dependencies.png

echo "Graph generated as dependencies.png"
