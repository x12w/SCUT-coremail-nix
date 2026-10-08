{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  glib-networking,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libpng,
  libuuid,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  pango,
  systemd,
  webkitgtk_4_1,
  xdg-utils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "coremail";
  version = "4.2.1-1427";

  src = fetchurl {
    # The vendor's Ubuntu beta download endpoint. A changed upstream release
    # must be reviewed and its version/hash updated together.
    url = "https://lunkr.coremail.cn/dl?p=mail&arch_type=amd64.ubuntu.deb&customer_type=beta";
    name = "coremail-ubuntu-${finalAttrs.version}-amd64.deb";
    hash = "sha256-QdMkudYnu7FthrqXoT7cL3+w90mHh4R4Gv5X6M+fGXs=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];
  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    glib-networking
    gtk3
    libdrm
    libgbm
    libpng
    libuuid
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    webkitgtk_4_1
  ];

  # Chromium loads graphics and udev libraries with dlopen().
  runtimeDependencies = map lib.getLib [
    libGL
    systemd
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/coremail" "$out/bin"
    cp -a opt/apps/cmclient/files/. "$out/lib/coremail/"
    # Debian maintainer scripts and the /opt launcher are not used on NixOS.
    rm "$out/lib/coremail/"{preinst,postinst,prerm,postrm,cmclient.sh}

    # This binary uses WebKit/JavaScriptCore APIs, but no libsoup APIs.
    # WebKitGTK 4.1 retains these APIs while using the supported libsoup 3.
    patchelf --replace-needed libwebkit2gtk-4.0.so.37 libwebkit2gtk-4.1.so.0 \
      --replace-needed libjavascriptcoregtk-4.0.so.18 libjavascriptcoregtk-4.1.so.0 \
      "$out/lib/coremail/cmclient"

    install -Dm644 opt/apps/cmclient/entries/applications/cmclient.desktop \
      "$out/share/applications/cmclient.desktop"
    install -Dm644 opt/apps/cmclient/entries/icons/cmclient.svg \
      "$out/share/icons/hicolor/scalable/apps/cmclient.svg"
    substituteInPlace "$out/share/applications/cmclient.desktop" \
      --replace-fail 'Exec=/opt/apps/cmclient/files/cmclient.sh' "Exec=$out/bin/coremail" \
      --replace-fail 'Icon=/opt/apps/cmclient/entries/icons/cmclient.svg' 'Icon=cmclient' \
      --replace-fail 'Terminal=0' 'Terminal=false' \
      --replace-fail 'Encoding=UTF-8' "" \
      --replace-fail 'MimeType=message/rfc822;x-scheme-handler/mailto' 'MimeType=message/rfc822;x-scheme-handler/mailto;' \
      --replace-fail 'Categories=Application;Network;X-Red-Hat-Base;X-Red-Hat-Base-Only;' 'Categories=Network;Email;'

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper "$out/lib/coremail/cmclient" "$out/bin/coremail" \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "$out/lib/coremail" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --prefix XDG_DATA_DIRS : "$out/share"
    ln -s coremail "$out/bin/cmclient"
  '';

  meta = {
    description = "Coremail email client (Ubuntu beta build)";
    homepage = "https://www.coremail.cn/";
    downloadPage = "https://www-lunkr.coremail.cn/download.html#email";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "coremail";
  };
})
