#!/bin/bash
# Usage: rif2website.sh --mint | --redbox
#
# Copyright (c) 2013, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
##############################################################################
BIN_DIR=$HOME/opt/rif2website
EXE_FNAME=rif2website.rb

PATH=/bin:/usr/bin:/usr/local/bin; export PATH
RUBY_VERSION=1.8.7
if ! ruby -v |grep -q "^ruby *$RUBY_VERSION"; then
  echo "WARNING: Incompatible ruby version! Expected $RUBY_VERSION"
  sleep 3
fi

cd $BIN_DIR && ruby $EXE_FNAME $@

