#!/usr/bin/env bash

if [ -d "/content" ]; then
  echo "This appears to be a Google Colab environment."

  echo "Installing dependencies"
  pip install -r "https://raw.githubusercontent.com/norandom/log2ml/main/dependencies/requirements.gpu.txt"

  # https://docs.rapids.ai/deployment/stable/platforms/colab/
  git clone https://github.com/rapidsai/rapidsai-csp-utils.git
  python rapidsai-csp-utils/colab/pip-install.py

else
  echo "This does not appear to be a Google Colab environment."
fi
