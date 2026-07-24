{ curl-impersonate }:

curl-impersonate.override {
  c-aresSupport = true;
}
// {
  meta = lib.removeAttrs (curl-impersonate.meta or { }) [ "position" ];
}
