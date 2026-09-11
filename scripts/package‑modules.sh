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

if [ ! -f "${MERGE_OUT}/merged.ko" ]; then
  echo "❌ merged.ko build failed!"
  exit 1
fi

ls -lh "${MERGE_OUT}/merged.ko"
echo "✅ merged.ko created successfully"

# ---------------------- Vermagic 校验打印 ----------------------
echo -e "\n===== Vermagic check ====="
# 读取ko的vermagic，使用modinfo
MODINFO="${CROSS_COMPILE}modinfo"

echo -e "\n[Original modules vermagic]"
for ko in "${KO_LIST[@]}"; do
  if [ -f "$ko" ]; then
    vermagic=$($MODINFO "$ko" | grep vermagic | cut -d: -f2 | xargs)
    echo "$(basename "$ko") : $vermagic"
  fi
done

echo -e "\n[Merged merged.ko vermagic]"
MERGED_VERMAGIC=$($MODINFO "${MERGE_OUT}/merged.ko" | grep vermagic | cut -d: -f2 | xargs)
echo "merged.ko : $MERGED_VERMAGIC"

# 校验：所有原始ko vermagic必须完全一致
FIRST_VERMAGIC=""
for ko in "${KO_LIST[@]}"; do
  if [ -f "$ko" ]; then
    cur=$($MODINFO "$ko" | grep vermagic | cut -d: -f2 | xargs)
    if [ -z "$FIRST_VERMAGIC" ]; then
      FIRST_VERMAGIC="$cur"
    else
      if [ "$cur" != "$FIRST_VERMAGIC" ]; then
        echo -e "\n⚠️ WARNING: Vermagic mismatch between modules!"
        echo "Expected: $FIRST_VERMAGIC"
        echo "Got: $cur for $(basename "$ko")"
        # 不直接exit，方便看日志，实际insmod会失败
      fi
    fi
  fi
done

# 校验合并后模块vermagic和原始是否一致
if [ "$MERGED_VERMAGIC" != "$FIRST_VERMAGIC" ] && [ -n "$FIRST_VERMAGIC" ]; then
  echo -e "\n⚠️ WARNING: merged.ko vermagic differs from source modules!"
  echo "Source: $FIRST_VERMAGIC"
  echo "Merged: $MERGED_VERMAGIC"
fi

echo -e "\n===== Vermagic check done ====="
