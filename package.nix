{ stdenv
, lib

, meson
, ninja

, pkg-config
, vala
, lessc

, glib
, gtk4
, linuxHeaders
, libmanette

, fabric-ui

# Used to hardcode GDK_PIXBUF_MODULE_FILE in the project for intrinsic SVG support.
, gdk-pixbuf
, librsvg
}:

stdenv.mkDerivation {
  pname = "fabric.tenfoot";
  version = "0.1";

  src = lib.cleanSource ./.;

  buildInputs = [
    glib
    gtk4
    linuxHeaders
    libmanette

    fabric-ui

    gdk-pixbuf
    librsvg
  ];

  nativeBuildInputs = [
    meson
    ninja

    pkg-config
    vala
    lessc
  ];

  preConfigure = ''
    mesonFlags+=" -Dgdk_pixbuf_module_file=$GDK_PIXBUF_MODULE_FILE "
  '';
}
