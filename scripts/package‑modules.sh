#!/bin/bash
set -e

MODULE_DIR="${WORKSPACE}/android-kernel/out/modules"
MERGE_OUT="${WORKSPACE}/out_merged"
mkdir -p "${MERGE_OUT}"

KO_LIST=()
[ -f "${MODULE_DIR}/susfs.ko" ] && KO_LIST+=("${MODULE_DIR}/susfs.ko")
[ -f "${MODULE_DIR}/ksu.ko" ] && KO_LIST+=("${MODULE_DIR}/ksu.ko")

if [ ${#KO_LIST[@]} -eq 0 ]; then
  echo "No ko files found to merge!"
  exit 1
fi

LD="${CROSS_COMPILE}ld"

echo "=== Linking ${#KO_LIST[@]} modules into single merged.ko ==="
echo "Using linker: ${LD}"

${LD} -r "${KO_LIST[@]}" -o "${MERGE_OUT}/merged.ko"

if [ -f "${MERGE_OUT}/merged.ko" ]; then
  ls -lh "${MERGE_OUT}/merged.ko"
  echo "✅ merged.ko created successfully"
else
  echo "❌ merged.ko build failed!"
  exit 1
fi
