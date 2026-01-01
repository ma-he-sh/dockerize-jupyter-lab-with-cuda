#!/bin/bash

if [ -n "$JUPYTER_PASSWORD" ]; then
  # Use password authentication
  HASHED_PASSWORD=$(python3 -c "from jupyter_server.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))")
  exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.password="$HASHED_PASSWORD" --NotebookApp.allow_origin='*' --NotebookApp.disable_check_xsrf=True
elif [ -n "$JUPYTER_TOKEN" ]; then
  # Use token authentication
  exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token="$JUPYTER_TOKEN" --NotebookApp.allow_origin='*' --NotebookApp.disable_check_xsrf=True
else
  # No authentication (not recommended for production)
  exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token='' --NotebookApp.allow_origin='*' --NotebookApp.disable_check_xsrf=True
fi

