#!/bin/bash

echo "SUP - System Update"

slackpkg update && (slackpkg install-new; slackpkg upgrade-all; slackpkg clean-system) || slackpkg new-config

