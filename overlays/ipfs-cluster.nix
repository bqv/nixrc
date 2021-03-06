inputs@{...}: final: prev: {
  ipfs-cluster = if final.lib.versionAtLeast prev.ipfs-cluster.version "0.13.1"
  then builtins.trace "pkgs.ipfs-cluster: overlay expired" prev.ipfs-cluster
  else (with prev.ipfs-cluster; final.buildGoModule {
    inherit pname version doCheck meta;
    src = final.fetchgit {
      url = src.meta.homepage;
      rev = "c78f7839a2d5645806e01bfbf7af862600f8fbc4";
      sha256 = "c9amvmxU+3P14NygJK2hTNR+lTdFK7eEj1eoqv2FTDs=";
    };
    vendorSha256 = "bejsbVMp5HnfUgG6pETK8Beeiax+BItVQh57sgmFbik=";
  });
}
