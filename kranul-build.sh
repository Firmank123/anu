#!/usr/bin/env bash
#
# Copyright (C) 2022-2023, Neebe3289 <neebexd@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Personal script for kranul compilation !!
# Inspired the script from Panchajanya1999 based.
#

# Function to show an informational message.
msg()
{
    echo -e "\e[1;32m$*\e[0m"
}

err()
{
    echo -e "\e[1;31m$*\e[0m"
}

# Check telegtam token/id
export TELEGRAM_TOKEN=""
export TELEGRAM_CHAT="-1001429581761"

if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT" ]
then
    err "Missing environment! .Please check again . ."
    exit
fi

#####################
# Basic Information #
#####################

# Set main directory of kernel source.
MAIN_DIR="$(pwd)"

# Specify name of device model.
# e.g: 'Redmi note 8 Pro'
DEVICE_MODEL="Poco M5s"

# Specify name of device codename.
# e.g: 'begonia'
DEVICE_CODENAME="rosemary"

# Set default achitecture.
ARCH=arm64

# Set device defconfig name.
# e.g: 'begonia_user_defconfig'
DEVICE_DEFCONFIG=rosemary_defconfig

# Set default image files/artifacts.
IMAGE=Image.gz-dtb

# Specify kernel name for ZIP name
KERNEL_NAME="SiLonT"

# Check kernel version.
SUBLEVEL=$(make kernelversion)

# Grab git current branch.
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Grab git commit hash.
COMMIT_HASH=$(git rev-parse --short HEAD)

# Set date into ZIP name.
DATE=$(date +"%Y%m%d-%H%M")

# Specify command to get KernelSU function.
# 'n' is NO(default) | 'y' is YES
KERNELSU=n

# Specify command to update submodule for KernelSU.
# 'n' is NO(default) | 'y' is YES
SUBMODULE=n

# Specify command name to set default compiler or toolchain.
# 'aosp'(default) | 'azure' | 'neutron' | 'proton'| 'eva'
TOOLCHAIN=aosp

# Clone compiler, anykernel3 and telegram.sh
clone()
{
     if [ "$TOOLCHAIN" = "aosp" ]
     then
          msg "Clone latest aosp clang toolchain"
          wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r498229.tar.gz -O "aosp-clang.tar.gz"
          mkdir clang-llvm && tar -xf aosp-clang.tar.gz -C clang-llvm && rm -rf aosp-clang.tar.gz
          git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 -b lineage-19.1 gcc64
          git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 -b lineage-19.1 gcc32
     elif [ "$TOOLCHAIN" = "azure" ]
     then
          msg "Clone latest azure clang toolchain"
          git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang.git clang-llvm
     elif [ "$TOOLCHAIN" = "neutron" ]
     then
          msg "Clone latest neutron clang toolchain"
          mkdir clang-llvm
          cd clang-llvm
          curl -LO "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman"
          chmod +x antman && bash antman -S=latest
          bash antman --patch=glibc
          cd ..
     elif [ "$TOOLCHAIN" = "proton" ]
     then
          msg "Clone latest proton clang toolchain"
          git clone --depth=1 https://github.com/kdrag0n/proton-clang.git clang-llvm
     elif [ "$TOOLCHAIN" = "eva" ]
     then
          msg "Clone latest eva gcc toolchain"
          git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git gcc-arm64
          git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git gcc-arm
     fi

     msg "Clone AnyKernel3 source"
     git clone --depth=1 https://github.com/ChuckProjekt/AnyKernel3

     msg "Clone telegram.sh source"
     git clone --depth=1 https://github.com/fabianonline/telegram.sh telegram
}

# Export
exports()
{
       # Set Indonesian timezone
       TZ="Asia/Jakarta"

       # Specify user name and host name
       KBUILD_BUILD_USER="Chuck"
       KBUILD_BUILD_HOST="gengkapak"

       if [ "$TOOLCHAIN" = "aosp" ]
       then
            PATH=$MAIN_DIR/clang-llvm/bin:$MAIN_DIR/gcc64/bin:$MAIN_DIR/gcc32/bin:$PATH
            LD_LIBRARY_PATH=$MAIN_DIR/clang-llvm/lib:$LD_LIBRARY_PATH
            KBUILD_COMPILER_STRING=$("$MAIN_DIR"/clang-llvm/bin/clang --version | head -n 1)
            COMPILER=$KBUILD_COMPILER_STRING
       elif [ "$TOOLCHAIN" = "azure" ] || [ "$TOOLCHAIN" = "neutron" ] || [ "$TOOLCHAIN" = "proton" ]
       then
            PATH=$MAIN_DIR/clang-llvm/bin:$PATH
            KBUILD_COMPILER_STRING=$("$MAIN_DIR"/clang-llvm/bin/clang --version | head -n 1)
            COMPILER=$KBUILD_COMPILER_STRING
       elif [ "$TOOLCHAIN" = "eva" ]
       then
            PATH=$MAIN_DIR/gcc-arm64/bin:$MAIN_DIR/gcc-arm/bin:$PATH
            KBUILD_COMPILER_STRING=$("$MAIN_DIR"/gcc-arm64/bin/aarch64-elf-gcc --version | head -n 1)
            COMPILER=$KBUILD_COMPILER_STRING
       fi

       # Specify CPU core/thread for compilation.
       # e.g: '2'/'4'/'8'/'12' or set default by using 'nproc --all'
       CORES=$(nproc --all)

       # Telegram directory.
       TELEGRAM=$MAIN_DIR/telegram/telegram

       export TZ ARCH DEVICE_DEFCONFIG KBUILD_BUILD_USER KBUILD_BUILD_HOST \
              PATH KBUILD_COMPILER_STRING COMPILER CORES \
              TELEGRAM
}

# Function to show an informational message to telegram.
send_msg()
{
    "${TELEGRAM}" -H -D \
        "$(
            for POST in "${@}"; do
                echo "${POST}"
            done
        )"
}

send_file()
{
    "${TELEGRAM}" -H \
        -f "$1" \
        "$2"
}

# Function for KernelSU.
# This is the default setting from my own.
# If facing loop issue when you added KernelSU support manually to your own kernel source, don't try to enable 'CONFIG_KPROBES' in your defconfig.
# It is known that 'KPROBES' is broken in some cases, which is causing loop. so never activate it.
# Reference: https://github.com/tiann/KernelSU/pull/453.

# Make it ZIP.
make_zip()
{
    msg "Make it a flashable ZIP files.."
    ZIPNAME="$KERNEL_NAME-$DEVICE_CODENAME-$COMMIT_HASH-$DATE"
    ZIP_FINAL="$ZIPNAME.zip"
    cd AnyKernel3 || exit 1
    sed -i "s/kernel.string=.*/kernel.string=$KERNEL_NAME by $KBUILD_BUILD_USER/g" anykernel.sh
    zip -r9 "$ZIP_FINAL" ./* -x .git .gitignore README.md *placeholder ./*.zip
    cd ..
}

# Upload ZIP files to Telegram.
send_zip()
{
    msg "Start to upload ZIP files.."
    cd AnyKernel3
    ZIPFILE=$(echo *.zip)
    SHA1=$(sha1sum "$ZIPFILE" | cut -d' ' -f1)
    send_file "$ZIPFILE" "✅ Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s) for $DEVICE_CODENAME | SHA1 : <code>$SHA1</code>"
}

# Function for upload error log during compiled.
send_log()
{
    ERROR_LOG=$(echo error.log)
    send_file "$ERROR_LOG" "❌ Build failed to compile, Please check log to fix it!"
    exit 1
}

# Compilation setup.
compile()
{
     BUILD_START=$(date +"%s")
     send_msg "<b>============================================</b>" \
        "<b>• DATE :</b> <code>$(TZ=Asia/Jakarta date +"%A, %d %b %Y, %H:%M:%S")</code>" \
        "<b>• DEVICE :</b> <code>$DEVICE_MODEL [$DEVICE_CODENAME]</code>" \
        "<b>• KERNEL NAME :</b> <code>$KERNEL_NAME</code>" \
        "<b>• LINUX VERSION :</b> <code>$SUBLEVEL</code>" \
        "<b>• BRANCH NAME :</b> <code>$BRANCH</code>" \
        "<b>• COMPILER :</b> <code>$COMPILER</code>" \
        "<b>• LAST COMMIT :</b> <code>$(git log --pretty=format:'%s' -1)</code>" \
        "<b>============================================</b>" \

     if [ "$TOOLCHAIN" = "aosp" ]
     then
          MAKE+=(
              CC=clang \
              LD=ld.lld \
              LLVM=1 \
              LLVM_IAS=1 \
              CLANG_TRIPLE=aarch64-linux-gnu- \
              CROSS_COMPILE=aarch64-linux-android- \
              CROSS_COMPILE_ARM32=arm-linux-androideabi-
          )
     elif [ "$TOOLCHAIN" = "azure" ] || [ "$TOOLCHAIN" = "neutron" ] || [ "$TOOLCHAIN" = "proton" ]
     then
          MAKE+=(
              LLVM=1 \
              LLVM_IAS=1 \
              CROSS_COMPILE=aarch64-linux-gnu- \
              CROSS_COMPILE_ARM32=arm-linux-gnueabi-
          )
     elif [ "$TOOLCHAIN" = "eva" ]
     then
          MAKE+=(
              AR=aarch64-elf-ar \
              LD=aarch64-elf-ld.lld \
              NM=aarch64-elf-nm \
              OBCOPY=aarch64-elf-objcopy \
              OBJDUMP=aarch64-elf-objdump \
              STRIP=aarch64-elf-strip \
              CROSS_COMPILE=aarch64-elf- \
              CROSS_COMPILE_ARM32=arm-eabi-
          )
     fi

     msg "Compilation has been started.."
     make O=out ARCH=arm64 $DEVICE_DEFCONFIG
     make -j"$CORES" ARCH=arm64 O=out \
           "${MAKE[@]}" 2>&1 | tee error.log

     if ! [ -a "$MAIN_DIR"/out/arch/arm64/boot/$IMAGE ]
     then
          err "Build failed to compile, check log to fix it!"
          send_log
          exit 1
     else
          msg "Kernel succesfully to compile!"
          cp "$MAIN_DIR"/out/arch/arm64/boot/$IMAGE AnyKernel3
     fi
}

clone
exports
compile
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))
make_zip
send_zip
rm -rf AnyKernel3

