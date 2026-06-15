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
  # the -V flag prints the version and exits, which is enough to check if it's runnable
  ${wrapped}/bin/hilbish -V > /dev/null
  touch $out
''
