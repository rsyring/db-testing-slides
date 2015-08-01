#!/bin/bash
PYTHONWARNINGS=ignore::UserWarning watchmedo shell-command \
    --recursive \
    --command='make -e slides' \
    conf.py index.rst _static _templates
