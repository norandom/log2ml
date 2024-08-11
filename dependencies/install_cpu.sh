#!/usr/bin/env bash

if [[ "$(uname)" == "Darwin" ]] || [[ "$(uname)" == "Linux" ]]; then
  echo "The CPU installation is starting (macOS, Linux)."

  echo "Installing dependencies"
  pip install -r "https://raw.githubusercontent.com/norandom/log2ml/main/dependencies/requirements.cgpu.txt"

  echo "cuML will not be installed."

else
  echo "This does not appear to be a CPU environment."
fi
