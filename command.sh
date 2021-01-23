#!/bin/bash

tail -f /usr/local/lsws/logs/access.log | sed 's/^/LOG: /' & tail -f /usr/local/lsws/logs/error.log | sed 's/^/ERROR: /'