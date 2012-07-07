#!/bin/sh

perl -i -wpe 's/(^|\G)  /\t/g;' "$@"
