#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/subcommand_common.bash
source "$SCRIPT_DIR/../common/subcommand_common.bash"

usage() {
    cat <<EOF
Usage: ${BASE_COMMAND:-$(basename "${BASH_SOURCE[0]}")} METASCHEMA_XML OUTPUT_DIR SCHEMA_NAME [ADDITIONAL_ARGS]

Produces XML Schema (XSD) and JSON Schema from Metaschema XML source, using XML Calabash invoked from Maven.

SCHEMA_NAME specifies the prefix output files will be written to, for example:
    outdir/a-metaschema -> outdir/a-metaschema_schema.xsd, outdir/a-metaschema_schema.json

Additional arguments for XML Calabash should be specified in the 'key=value' format.
EOF
}

[[ -z "${1-}" ]] && { echo "Error: METASCHEMA_XML not specified"; usage; exit 1; }
METASCHEMA_XML=$1
[[ -z "${2-}" ]] && { echo "Error: SCHEMA_NAME not specified"; usage; exit 1; }
SCHEMA_NAME=$2

ADDITIONAL_ARGS=$(shift 2; echo "${*// /\\ }")

PIPELINE="${SCRIPT_DIR}/METASCHEMA-ALL-SCHEMAS.xpl"

XSD_FILE="${SCHEMA_NAME}_schema.xsd"
JSONSCHEMA_FILE="${SCHEMA_NAME}_schema.json"

CALABASH_ARGS="-i METASCHEMA=\"$METASCHEMA_XML\" \
               -o INT_0_echo-input=/dev/null \
               -o INT_1_composed-metaschema=/dev/null \
               -o OUT_json-schema-xml=/dev/null \
               -o OUT_json-schema=\"$JSONSCHEMA_FILE\" \
               -o OUT_xml-schema=\"$XSD_FILE\" \
               $ADDITIONAL_ARGS \"$PIPELINE\""

# Ensure the base directory exists
mkdir -p "$(dirname "$SCHEMA_NAME")"

if [ -e "$XSD_FILE" ]; then 
    echo "Deleting prior $XSD_FILE..." >&2
    rm -f "$XSD_FILE"
fi

if [ -e "$JSONSCHEMA_FILE" ]; then 
    echo "Deleting prior $JSONSCHEMA_FILE..." >&2
    rm -f "$JSONSCHEMA_FILE"
fi

invoke_calabash "${CALABASH_ARGS}"

if [ -e "$XSD_FILE" ] && [ -e "$JSONSCHEMA_FILE" ]; then 
    echo "Results can be found in $XSD_FILE and $JSONSCHEMA_FILE" >&2
fi