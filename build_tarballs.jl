# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "umat_binaries"
version = v"0.3.0"

# Collection of sources required to build umat_binaries
sources = [
    "https://raw.githubusercontent.com/KratosMultiphysics/Kratos/80d68b9a7e89d97438fd04726e5198084b7be43e/applications/constitutive_laws_application/custom_external_libraries/umat/mises_umat.f" =>
    "bfb0f46ae0c9cef0cc91c1dbf78943dd7afd24a5a757dd3224ed66cdd71e7ec6",

    "https://raw.githubusercontent.com/KratosMultiphysics/Kratos/80d68b9a7e89d97438fd04726e5198084b7be43e/applications/constitutive_laws_application/custom_external_libraries/umat/ABA_PARAM.INC" =>
    "b7d74a332dda559e06720db8b7f907aedb72f58b8ed957c7c67ba7007a8e93a8",

    "https://raw.githubusercontent.com/KratosMultiphysics/Kratos/80d68b9a7e89d97438fd04726e5198084b7be43e/applications/constitutive_laws_application/custom_external_libraries/umat/xit.f" =>
    "14f74acd4a20ad680b0c354416f302e5f2e078f3a5750df60888b9b41cb887a5",

    "http://www.columbia.edu/~jk2079/fem/umatcrystal_mod.f" =>
    "e0e5384d958020622e66ed6520d28bce34517a5f3f2be3f2485a5a8fb6e2f6b6"

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cat >CMakeLists.txt <<EOL
cmake_minimum_required(VERSION 3.5)
project(Umat)
set(VERSION 0.1.0)
enable_language(Fortran)
set(SOURCE_FILES mises_umat.f xit.f)
set(LIBRARY_NAME mises_umat)
add_library(\${LIBRARY_NAME} SHARED \${SOURCE_FILES})
add_library(umatcrystal_mod SHARED umatcrystal_mod.f)
install(TARGETS mises_umat DESTINATION lib)
install(TARGETS umatcrystal_mod DESTINATION lib)
EOL

cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain
make
make install


"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Windows(:x86_64),
    MacOS(:x86_64),
    Windows(:i686),
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    FreeBSD(:x86_64)
]

platforms = expand_gcc_versions(platforms)

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libmises_umat", :mises_umat)
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
