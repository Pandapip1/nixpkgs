{ lib, curl-impersonate }:

(curl-impersonate.override {
  c-aresSupport = true;
}).overrideAttrs
  (prevAttrs: {
    meta = lib.removeAttrs (prevAttrs.meta or { }) "position";
  })
