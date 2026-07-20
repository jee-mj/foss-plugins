{ lib }:

let
  normalizeLicenses = license: if builtins.isList license then license else [ license ];

  isFreeLicense = license:
    (license.free or false) && (license ? spdxId) && license.spdxId != "";

  assertFreePackage = package:
    assert lib.all isFreeLicense (normalizeLicenses package.meta.license);
    package;

  assertFreePackages = packages:
    lib.mapAttrs (_: assertFreePackage) packages;
in
{
  inherit normalizeLicenses isFreeLicense assertFreePackages;
}
