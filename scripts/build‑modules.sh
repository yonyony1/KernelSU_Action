#!/bin/bash
set -e
cd "${WORKSPACE}/android-kernel"

# 手动生成 .config，替代 build.sh config
make -j$(nproc) $KERNEL_CONFIG
# 加载额外defconfig
if [[ -n "${EXTRA_DEFCONFIG}" ]]; then
  make -j$(nproc) ${EXTRA_DEFCONFIG}
fi
make -j$(nproc) olddefconfig

echo "===== Building modules only, skip kernel Image ====="
make -j$(nproc) modules

# 收集所有ko到输出目录
mkdir -p out/modules
find . -name "*.ko" -exec cp {} out/modules/ \;
ls -la out/modules/
