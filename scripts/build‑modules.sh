#!/bin/bash
set -e

cd "${WORKSPACE}/android-kernel"

# 仅复用原build.sh的config逻辑，只生成.config，不编译内核镜像
bash "${GITHUB_WORKSPACE}/scripts/build.sh" config

echo "===== Building modules only, skip kernel Image ====="
make "-j$(nproc)" modules

# 收集所有ko到输出目录
mkdir -p out/modules
find . -name "*.ko" -exec cp {} out/modules/ \;
ls -la out/modules/
