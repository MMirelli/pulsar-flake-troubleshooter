# README

This repo contains scripts to quickly repro issues in pulsar flaky tests. Each subdirectory is named after the pulsar issue describing the flaky test addressed by the scripts.

## Install

```
echo "source <YOUR_DEV_HOME>/pulsar-flake-troubleshooter/utils.sh" >> ~/.bashrc
source ~/.bashrc
```
## Requirements

Scripts assume the following are installed in your system:
1. pulsar-contributor-toolbox - https://github.com/lhotari/pulsar-contributor-toolbox/
2. emacs - https://www.gnu.org/software/emacs/
3. GitHub CLI - https://cli.github.com/
