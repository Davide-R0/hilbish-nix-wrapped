{
  pkgs,
  self,
  ...
}:

let
  wrapped =
    (self.wrappers.hilbish.apply {
      inherit pkgs;
    }).wrapper;
in
pkgs.runCommand "hilbish-test" { } ''
  # the -v flag prints the version and exits, which is enough to check if it's runnable
  ${wrapped}/bin/hilbish -v > /dev/null
  touch $out
''
