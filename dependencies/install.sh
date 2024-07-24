#!/usr/bin/env bash

if [ -d "/content" ]; then
  echo "This appears to be a Google Colab environment."

  echo "Installing dependencies"
  pip install -r "https://raw.githubusercontent.com/norandom/log2ml/main/dependencies/requirements.gpu.txt"

else
  echo "This does not appear to be a Google Colab environment."
fi
