#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

function set_go_vars {

    export GOPATH="$install_dir/build/go"
    export GOCACHE="$install_dir/build/.cache"

    go_shims_path=$go_dir/shims
    go_path_full="$go_shims_path":"$(ynh_exec_as_app bash -c 'echo $PATH')"
    heif_lib_path="$install_dir/local/lib":"$(ynh_exec_as_app bash -c 'echo $LIBRARY_PATH')"
    heif_ld_lib_path="$install_dir/local/lib":"$(ynh_exec_as_app bash -c 'echo $LD_LIBRARY_PATH')"
    heif_cgo_cflags="-I$install_dir/local/include"
}

function build_libheif {
    export GOPATH="$install_dir/build/go"
    export GOCACHE="$install_dir/build/.cache"

    pushd "$install_dir/libheif" || ynh_die
        ynh_exec_as_app mkdir build
        pushd build
            ynh_exec_and_print_stderr_only_if_error ynh_exec_as_app \
                cmake --preset=release -DCMAKE_INSTALL_PREFIX="$install_dir/local" -DWITH_GDK_PIXBUF=OFF -G Ninja ..
            ynh_exec_and_print_stderr_only_if_error ynh_exec_as_app \
                ninja
            ynh_exec_and_print_stderr_only_if_error ynh_exec_as_app \
                ninja install
        popd
    popd || ynh_die
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
        ynh_hide_warnings corepack prepare  yarn@4.12 --activate
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
    ynh_safe_rm "$install_dir/libheif"
    ynh_safe_rm "$install_dir/sources"
    ynh_safe_rm "$install_dir/go"
    ynh_safe_rm "$install_dir/.cache/go-build"
}
