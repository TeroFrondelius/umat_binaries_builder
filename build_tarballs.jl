# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "umat_binaries"
version = v"0.1.0"

# Collection of sources required to build umat_binaries
sources = [
    "https://raw.githubusercontent.com/KratosMultiphysics/Kratos/80d68b9a7e89d97438fd04726e5198084b7be43e/applications/constitutive_laws_application/custom_external_libraries/umat/mises_umat.f" =>
    "bfb0f46ae0c9cef0cc91c1dbf78943dd7afd24a5a757dd3224ed66cdd71e7ec6",

    "https://raw.githubusercontent.com/KratosMultiphysics/Kratos/80d68b9a7e89d97438fd04726e5198084b7be43e/applications/constitutive_laws_application/custom_external_libraries/umat/ABA_PARAM.INC" =>
    "b7d74a332dda559e06720db8b7f907aedb72f58b8ed957c7c67ba7007a8e93a8",

    "https://raw.githubusercontent.com/KratosMultiphysics/Kratos/80d68b9a7e89d97438fd04726e5198084b7be43e/applications/constitutive_laws_application/custom_external_libraries/umat/xit.f" =>
    "14f74acd4a20ad680b0c354416f302e5f2e078f3a5750df60888b9b41cb887a5",

    #"https://sourceforge.net/code-snapshots/svn/p/pa/parafem/code/parafem-code-r2281-trunk-parafem-src-umats-dp.zip" =>
    #"114d5773e806de0070eee7379131ceae25c3516fb49b8e3fb8f0f9e1926717bf"

    # The above is the original but for some reason sourceforge blogged the trafic
    "https://github.com/TeroFrondelius/umat_binaries_builder/releases/download/v0.3.1/parafem-code-r2281-trunk-parafem-src-umats-dp.zip" =>
    "114d5773e806de0070eee7379131ceae25c3516fb49b8e3fb8f0f9e1926717bf",

    # Gurson model from UMAT.jl/umat_models
    "https://github.com/JuliaFEM/UMAT.jl.git" =>
    "0225216125884a4a9439d5444221be450e9d9212"

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
add_library(elastic SHARED elastic.f)
add_library(isotropic_plast_exp SHARED isotropic_plast_exp.f)
add_library(isotropic_plast_imp SHARED isotropic_plast_imp.f)

install(TARGETS mises_umat DESTINATION lib)
install(TARGETS elastic DESTINATION lib)
install(TARGETS isotropic_plast_exp DESTINATION lib)
install(TARGETS isotropic_plast_imp DESTINATION lib)
EOL

export dp=parafem-code-r2281-trunk-parafem-src-umats-dp
cp $dp/elasticity/elastic.f .
cp $dp/plasticity_exp/code_exp.f isotropic_plast_exp.f
cp $dp/plasticity_imp/code_imp.f isotropic_plast_imp.f

sed -i -e '1i\       IMPLICIT REAL*8(A-H,O-Z)' ABA_PARAM.INC

cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain
make
make install

# From this forward is Gurson model building
cd UMAT.jl/umat_models

cat >CMakeLists.txt <<EOL
cmake_minimum_required(VERSION 3.5)
project(Umat)
set(VERSION 0.1.0)
enable_language(Fortran)
set(CMAKE_Fortran_FLAGS "-fdefault-real-8")
add_library(gurson_porous_plasticity SHARED gurson_porous_plasticity.f90)
target_link_libraries(gurson_porous_plasticity openblas64_)
install(TARGETS gurson_porous_plasticity DESTINATION lib)
EOL

sed -i 's/CALL ROTSIG(/!CALL ROTSIG(/g' gurson_porous_plasticity.f90
sed -i 's/call dgesv(/call dgesv_64(/g' gurson_porous_plasticity.f90

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
    Linux(:x86_64, libc=:glibc),
    Linux(:i686, libc=:glibc),
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
    LibraryProduct(prefix, "libmises_umat", :mises_umat),
    LibraryProduct(prefix, "libelastic", :elastic),
    LibraryProduct(prefix, "libisotropic_plast_exp", :isotropic_plast_exp),
    LibraryProduct(prefix, "libisotropic_plast_imp", :isotropic_plast_imp),
    LibraryProduct(prefix, "libgurson_porous_plasticity", :gurson_porous_plasticity)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaLinearAlgebra/OpenBLASBuilder/releases/download/v0.3.0-3/build_OpenBLAS.v0.3.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
