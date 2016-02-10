#!/bin/sh

MLCP=/Users/adamfowler/Documents/marklogic/software/mlcp-8.0-4/bin/mlcp.sh

$MLCP import -username admin -password admin -host 192.168.123.4 -port 8000 -input_file_path ./data/rdf/simplecities.ttl -database GraphQueries -mode local -input_file_type rdf -output_graph 128cities
