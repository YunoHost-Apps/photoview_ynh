#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

go_version=1.20
node_version=16

#=================================================
# PERSONAL HELPERS
#=================================================

function set_go_vars {
    ynh_use_go

    export GOPATH="$install_dir/build/go"
    export GOCACHE="$install_dir/build/.cache"

    go_shims_path=$goenv_install_dir/shims
    go_path_full="$go_shims_path":"$(sudo -u $app bash -c 'echo $PATH')"
    heif_lib_path="$install_dir/local/lib":"$(sudo -u $app bash -c 'echo $LIBRARY_PATH')"
    heif_ld_lib_path="$install_dir/local/lib":"$(sudo -u $app bash -c 'echo $LD_LIBRARY_PATH')"
    heif_cgo_cflags="-I$install_dir/local/include"
}

function build_libheif {
    export GOPATH="$install_dir/build/go"
    export GOCACHE="$install_dir/build/.cache"

    pushd "$install_dir/libheif" || ynh_die
        # mkdir -p "$install_dir/local"
        # chown -R $app:$app "$install_dir/local"
        ynh_exec_as "$app" ./autogen.sh 2>&1
        ynh_exec_as "$app" ./configure --prefix="$install_dir/local" --disable-gdk-pixbuf 2>&1
        ynh_exec_as "$app" make clean 2>&1
        ynh_exec_as "$app" make 2>&1
        ynh_exec_as "$app" make install 2>&1
        ynh_exec_as "$app" make clean 2>&1
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
            ynh_exec_as "$app" env "${gobuild_env[@]}" go mod download 2>&1 && break
            sleep 5
        done
        set -e
        ynh_exec_as "$app" env "${gobuild_env[@]}" go install github.com/mattn/go-sqlite3 github.com/Kagami/go-face 2>&1
        ynh_exec_as "$app" env "${gobuild_env[@]}" go build -o photoview . 2>&1
    popd || ynh_die

    cp -T "$install_dir/sources/api/photoview" "$install_dir/output/photoview"
    cp -rT "$install_dir/sources/api/data" "$install_dir/output/data"
}

function build_ui {
    ynh_use_nodejs

    pushd "$install_dir/sources/ui" || ynh_die
        ynh_replace_string -m "cd .. && " -r "" -f "package.json"
        # chown -R "$app:$app" $install_dir
        ynh_exec_as "$app" touch ".yarnrc"
        ynh_exec_as "$app" env "$ynh_node_load_PATH" yarn --cache-folder "./yarn-cache" --use-yarnrc ".yarnrc" import 2>&1
        # ynh_exec_as "$app" env "$ynh_node_load_PATH" yarn --cache-folder "./yarn-cache" --use-yarnrc ".yarnrc" add husky 2>&1
        ynh_exec_as "$app" env "$ynh_node_load_PATH" yarn --cache-folder "./yarn-cache" --use-yarnrc ".yarnrc" install --production 2>&1
        ynh_exec_as "$app" env "$ynh_node_load_PATH" yarn --cache-folder "./yarn-cache" --use-yarnrc ".yarnrc" add graphql --production --ignore-engines 2>&1
        ynh_exec_as "$app" env "$ynh_node_load_PATH" yarn --cache-folder "./yarn-cache" --use-yarnrc ".yarnrc" run build 2>&1
        # ynh_exec_as "$app" env "$ynh_node_load_PATH" NODE_ENV=production "$ynh_npm" install
        # ynh_exec_as "$app" env "$ynh_node_load_PATH" NODE_ENV=production "$ynh_npm" run build
    popd || ynh_die

    cp -rT "$install_dir/sources/ui/build" "$install_dir/output/ui"
}

function cleanup_sources {
    ynh_secure_remove --file="$install_dir/libheif"
    ynh_secure_remove --file="$install_dir/sources"
    ynh_secure_remove --file="$install_dir/go"
    ynh_secure_remove --file="$install_dir/.cache/go-build"
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
