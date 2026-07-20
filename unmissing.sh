#!/bin/bash

lib=$1

missedpkg=$(slackpkg file-search ${lib} | grep "^\[" | awk -F: '{print $2}')

echo slackpkg install ${missedpkg}

slackpkg install ${missedpkg}
