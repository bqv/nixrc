{ lib, fetchFromGitHub, autoreconfHook, pkg-config, llvmPackages_latest, gcc
, libsodium, openssl, file, boost, gmp, rocksdb
, llvm ? if useClang then llvmPackages_latest.llvm else null
, graphicsmagick ? if withGraphicsMagick then graphicsmagick else null
, jemalloc ? if useJemalloc then jemalloc else null

, stdenv ? if useClang # Build Chain
           then (if stdenv.cc.isClang then stdenv else llvmPackages_latest.stdenv)
           else (if stdenv.cc.isGNU then stdenv else gcc.stdenv)
, debug ? false # Debug Build
, useClang ? false # Use Clang over GCC
, useJemalloc ? true # Use the Dynamic Memory Allocator
, withGraphicsMagick ? true # Allow Media Thumbnails
, ... }:

stdenv.mkDerivation rec {
  pname = "matrix-construct";
  version = "2020.04.11";

  src = fetchFromGitHub {
    owner = "jevolk";
    repo = "charybdis";
    rev = "21d9f4792bb59f5657ae5c94e1bf52a8288b247d";
    hash = "sha256-t3b5LdCCgEXnUr9gdAeqIoRqzKLbSqXtThhDIBg76aw=";
  };

  configureFlags = [
    "--enable-generic"
    "--with-boost-libdir=${boost.out}/lib"
    "--with-boost=${boost.dev}"
  ] ++ lib.optional useJemalloc "--enable-jemalloc"
    ++ lib.optional withGraphicsMagick [
    "--with-imagemagick-includes=${graphicsmagick}/include/GraphicsMagick"
  ] ++ lib.optional debug "--with-log-level=DEBUG";

  postConfigure = ''
    sed -i '/RB_CONF_DIR/s%^.*$%#define RB_CONF_DIR "/etc"%' include/ircd/config.h
    sed -i '/RB_DB_DIR/s%^.*$%#define RB_DB_DIR "/var/db/${pname}"%' include/ircd/config.h
    sed -i '/RB_LOG_DIR/s%^.*$%#define RB_LOG_DIR "/var/log/${pname}"%' include/ircd/config.h
    substituteInPlace ircd/magic.cc --replace "/usr/local/share/misc/magic.mgc" "${file}/share/misc/magic.mgc"
  '';

  enableParallelBuilding = true;

  nativeBuildInputs = [ autoreconfHook pkg-config ];
  buildInputs = [
    libsodium openssl file boost gmp
    (rocksdb.overrideAttrs (super: rec {
      version = "5.16.6";
      src = fetchFromGitHub {
        owner = "facebook"; repo = "rocksdb"; rev = "v${version}";
        sha256 = "0yy09myzbi99qdmh2c2mxlddr12pwxzh66ym1y6raaqglrsmax66";
      };
      NIX_CFLAGS_COMPILE = "${super.NIX_CFLAGS_COMPILE} -Wno-error=redundant-move";
    }))
    graphicsmagick
    jemalloc llvm
  ];
}
