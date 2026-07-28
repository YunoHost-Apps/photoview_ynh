#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

function set_go_vars {

    export GOPATH="$install_dir/build/go"
    export GOCACHE="$install_dir/build/.cache"

    go_shims_path=$go_dir/shims
    go_path_full="$go_shims_path":"$(ynh_exec_as_app bash -c 'echo $PATH')"

    heif_lib_path="$install_dir/vips/lib":"$(ynh_exec_as_app bash -c 'echo $LIBRARY_PATH')"
    heif_ld_lib_path="$install_dir/vips/lib":"$(ynh_exec_as_app bash -c 'echo $LD_LIBRARY_PATH')"
    heif_cgo_cflags="-I$install_dir/vips/include"
}

function build_api {
    set_go_vars

    gobuild_env=(
        "PATH=$go_path_full"
        "LIBRARY_PATH=$heif_lib_path"
        "LD_LIBRARY_PATH=$heif_ld_lib_path"
        "CGO_CFLAGS=$heif_cgo_cflags"
        "GOENV_VERSION=$go_version"
        CGO_ENABLED=1
    )

    pushd "$install_dir/sources/api" || ynh_die
        set +e
        for i in {1..5}; do
            ynh_exec_as_app "${gobuild_env[@]}" go mod download 2>&1 && break
            sleep 5
        done
        set -e
        ynh_exec_as_app "${gobuild_env[@]}" go install github.com/mattn/go-sqlite3 github.com/Kagami/go-face 2>&1
        ynh_exec_as_app "${gobuild_env[@]}" go build -o photoview . 2>&1
    popd || ynh_die

    cp -T "$install_dir/sources/api/photoview" "$install_dir/output/photoview"
    cp -rT "$install_dir/sources/api/data" "$install_dir/output/data"
}

function build_ui {

    pushd "$install_dir/sources/ui" || ynh_die
        ynh_replace -m "cd .. && " -r "" -f "package.json"
        chown -R "$app:$app" $install_dir
        corepack enable
        ynh_hide_warnings corepack prepare yarn@4.12.0 --activate
        ynh_exec_as_app touch ".yarnrc"
        ynh_exec_as_app yarn --cache-folder "./yarn-cache" --use-yarnrc ".yarnrc" import 2>&1
        # ynh_exec_as_app yarn --cache-folder "./yarn-cache" --use-yarnrc ".yarnrc" add husky 2>&1
        ynh_exec_as_app yarn --cache-folder "./yarn-cache" --use-yarnrc ".yarnrc" install --production 2>&1
        ynh_exec_as_app yarn --cache-folder "./yarn-cache" --use-yarnrc ".yarnrc" add graphql --production --ignore-engines 2>&1
        ynh_exec_as_app yarn --cache-folder "./yarn-cache" --use-yarnrc ".yarnrc" run build 2>&1
        # ynh_exec_as_app NODE_ENV=production npm install
        # ynh_exec_as_app NODE_ENV=production npm run build
    popd || ynh_die

    cp -rT "$install_dir/sources/ui/dist" "$install_dir/output/ui"
}

function cleanup_sources {
    ynh_safe_rm "$install_dir/sources"
    ynh_safe_rm "$install_dir/go"
    ynh_safe_rm "$install_dir/.cache/go-build"
}

tools_prefix="$install_dir/dependencies"

# Path for the service to retrieve the Calibre tools
path_with_imagemagick="$tools_prefix/bin:$PATH"

install_imagemagick() {
    ynh_setup_source --source_id="imagemagickv7" --dest_dir="$install_dir/imagemagick_source"
    mkdir -p "$tools_prefix"
    chown -R "$app:$app" "$install_dir/imagemagick_source" "$tools_prefix"

    pushd "$install_dir/imagemagick_source"
        ynh_exec_as_app CFLAGS="-O2 -I$tools_prefix/include -Wno-deprecated-declarations" \
            ./configure \
            --prefix="$tools_prefix" \
            --enable-static \
            --enable-bounds-checking \
            --enable-hdri \
            --enable-hugepages \
            --with-threads \
            --with-modules \
            --with-quantum-depth=16 \
            --without-magick-plus-plus \
            --with-bzlib \
            --with-zlib \
            --without-autotrace \
            --with-freetype \
            --with-jpeg \
            --without-lcms \
            --with-lzma \
            --with-png \
            --with-tiff \
            --with-heic \
            --with-rsvg \
            --with-webp
        ynh_exec_as_app make all -j"$(nproc)"
        ynh_exec_as_app LIBTOOLFLAGS=-Wnone make install
    popd
    ynh_safe_rm "$install_dir/imagemagick_source"
}