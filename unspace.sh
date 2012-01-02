#!/bin/sh

perl -i -wpe 's/\s+$/\n/' "$@"
