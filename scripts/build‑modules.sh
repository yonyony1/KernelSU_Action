#!/bin/bash
set -e
cd "${WORKSPACE}/android-kernel"

# 目标内核编译环境（仅给内核代码）
export ARCH=arm64
export LLVM=1
export CLANG_TRIPLE=aarch64-linux-gnu-
export PATH="${CLANG_PATH}:$PATH"

# 强制主机工具使用系统原生gcc，清空主机编译flags，避免arm参数污染HOSTCC
unset HOSTCC HOSTCXX HOSTCFLAGS HOSTLDFLAGS

# 生成 .config
make ${KERNEL_CONFIG}
if [[ -n "${EXTRA_DEFCONFIG}" ]]; then
  make ${EXTRA_DEFCONFIG}
fi
make olddefconfig

echo "===== Building modules only, skip kernel Image ====="
make -j$(nproc) HOSTCC=gcc HOSTCXX=g++ modules

# 收集所有ko到输出目录
mkdir -p out/modules
find . -name "*.ko" -exec cp {} out/modules/ \;
ls -la out/modules/
