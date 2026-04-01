#!/bin/bash
CLANG_VERSION=22.1.2
CLANG_BINARIES_OUPUT=./clang_binaries_output/LLVM-$CLANG_VERSION-Linux-X64
CLANG_SOURCES_OUTPUT=./clang_sources_output/llvm-project-llvmorg-$CLANG_VERSION
# User inputs


echo "!!! Installer need at least 20GB of available storage during installation !!!"
echo
echo "Are you sure you want to continue ?"

read -p "Type yes to continue: " user_input
read -p "Where would you install clang ?: " clang_path

if [[ "$user_input" == "yes" ]]; then
	echo "Downloading binaries"
	if [ ! -f "clang_binaries.tar.xz" ]; then
		curl -L "https://github.com/llvm/llvm-project/releases/download/llvmorg-$CLANG_VERSION/LLVM-$CLANG_VERSION-Linux-X64.tar.xz" -o "clang_binaries.tar.xz"
	fi
	echo "Unzipping clang binaries (this step can take a while)..."
	mkdir -p ./clang_binaries_output
	tar -xf ./clang_binaries.tar.xz -C ./clang_binaries_output

	echo "Copy clang binaries"
	cp -r $CLANG_BINARIES_OUPUT/bin $clang_path
	cp -r $CLANG_BINARIES_OUPUT/include $clang_path
	cp -r $CLANG_BINARIES_OUPUT/lib $clang_path
	cp -r $CLANG_BINARIES_OUPUT/libexec $clang_path
	cp -r $CLANG_BINARIES_OUPUT/share $clang_path

	echo "Downloading source code to build missing libs"
	if [ ! -f "clang_sources.tar.xz" ]; then
		curl -L "https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-$CLANG_VERSION.tar.gz" -o "clang_sources.tar.xz"
	fi

	echo "Unzipping clang source code (this step can take a while)..."
	mkdir -p ./clang_sources_output
	tar -xf ./clang_sources.tar.xz -C ./clang_sources_output

	echo "Compiling missing libs..."
	cd $CLANG_SOURCES_OUTPUT
	echo "$clang_path/bin/cc"
	cmake -S runtimes -B build \
		-DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
		-DCMAKE_INSTALL_PREFIX="$clang_path" \
		-DCMAKE_CXX_COMPILER="$clang_path/bin/c++" \
		-DCMAKE_C_COMPILER="$clang_path/bin/cc" \
		-DCMAKE_BUILD_TYPE=Release \
		-DLIBCXX_INCLUDE_TESTS=OFF \
		-DLIBCXXABI_INCLUDE_TESTS=OFF \
		-DLIBUNWIND_INCLUDE_TESTS=OFF \
		-DLIBCXX_ENABLE_SHARED=ON

	cmake --build build -j $(nproc) --target install
	echo "Installing missing libs"
	cmake --install build

else
    echo "Exiting."
    exit 1
fi