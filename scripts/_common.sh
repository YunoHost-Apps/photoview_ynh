#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

go_version=1.18
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
}

function build_api {
    set_go_vars

    gobuild_env=(
        "PATH=$go_path_full"
        "GOENV_VERSION=$go_version"
        "CGO_ENABLED=1"
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
        ynh_exec_as "$app" env "$ynh_node_load_PATH" yarn --cache-folder "./yarn-cache" --use-yarnrc ".yarnrc" run build --public-url "$path" 2>&1
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

#!/bin/bash

ynh_go_try_bash_extension() {
    if [ -x src/configure ]; then
        src/configure && make -C src || {
            ynh_print_info --message="Optional bash extension failed to build, but things will still work normally."
        }
    fi
}

goenv_install_dir="/opt/goenv"
go_version_path="$goenv_install_dir/versions"
# goenv_ROOT is the directory of goenv, it needs to be loaded as a environment variable.
export GOENV_ROOT="$goenv_install_dir"

# Load the version of Go for an app, and set variables.
#
# ynh_use_go has to be used in any app scripts before using Go for the first time.
# This helper will provide alias and variables to use in your scripts.
#
# To use gem or Go, use the alias `ynh_gem` and `ynh_go`
# Those alias will use the correct version installed for the app
# For example: use `ynh_gem install` instead of `gem install`
#
# With `sudo` or `ynh_exec_as`, use instead the fallback variables `$ynh_gem` and `$ynh_go`
# And propagate $PATH to sudo with $ynh_go_load_path
# Exemple: `ynh_exec_as $app $ynh_go_load_path $ynh_gem install`
#
# $PATH contains the path of the requested version of Go.
# However, $PATH is duplicated into $go_path to outlast any manipulation of $PATH
# You can use the variable `$ynh_go_load_path` to quickly load your Go version
#	in $PATH for an usage into a separate script.
# Exemple: $ynh_go_load_path $install_dir/script_that_use_gem.sh`
#
#
# Finally, to start a Go service with the correct version, 2 solutions
#	Either the app is dependent of Go or gem, but does not called it directly.
#	In such situation, you need to load PATH
#		`Environment="__YNH_GO_LOAD_ENV_PATH__"`
#		`ExecStart=__INSTALL_DIR__/my_app`
#		 You will replace __YNH_GO_LOAD_ENV_PATH__ with $ynh_go_load_path
#
#	Or Go start the app directly, then you don't need to load the PATH variable
#		`ExecStart=__YNH_GO__ my_app run`
#		 You will replace __YNH_GO__ with $ynh_go
#
#
# one other variable is also available
#	 - $go_path: The absolute path to Go binaries for the chosen version.
#
# usage: ynh_use_go
#
# Requires YunoHost version 3.2.2 or higher.
ynh_use_go() {
 	go_version=$(ynh_app_setting_get --app=$app --key=go_version)

    # Get the absolute path of this version of Go
    go_path="$go_version_path/$go_version/bin"

    # Allow alias to be used into bash script
    shopt -s expand_aliases

    # Create an alias for the specific version of Go and a variable as fallback
    ynh_go="$go_path/go"
    alias ynh_go="$ynh_go"

    # Load the path of this version of Go in $PATH
    if [[ :$PATH: != *":$go_path"* ]]; then
        PATH="$go_path:$PATH"
    fi
    # Create an alias to easily load the PATH
    ynh_go_load_path="PATH=$PATH"

    # Sets the local application-specific Go version
    pushd $install_dir
    $goenv_install_dir/bin/goenv local $go_version
    popd
}

# Install a specific version of Go
#
# ynh_install_go will install the version of Go provided as argument by using goenv.
#
# This helper creates a /etc/profile.d/goenv.sh that configures PATH environment for goenv
# for every LOGIN user, hence your user must have a defined shell (as opposed to /usr/sbin/nologin)
#
# Don't forget to execute go-dependent command in a login environment
# (e.g. sudo --login option)
# When not possible (e.g. in systemd service definition), please use direct path
# to goenv shims (e.g. $goenv_ROOT/shims/bundle)
#
# usage: ynh_install_go --go_version=go_version
# | arg: -v, --go_version= - Version of go to install.
#
# Requires YunoHost version 3.2.2 or higher.
ynh_install_go() {
    # Declare an array to define the options of this helper.
    local legacy_args=v
    local -A args_array=([v]=go_version=)
    local go_version
    # Manage arguments with getopts
    ynh_handle_getopts_args "$@"

    # Load goenv path in PATH
    local CLEAR_PATH="$goenv_install_dir/bin:$PATH"

    # Remove /usr/local/bin in PATH in case of Go prior installation
    PATH=$(echo $CLEAR_PATH | sed 's@/usr/local/bin:@@')

    # Move an existing Go binary, to avoid to block goenv
    test -x /usr/bin/go && mv /usr/bin/go /usr/bin/go_goenv

    # Install or update goenv
    goenv="$(command -v goenv $goenv_install_dir/bin/goenv | head -1)"
    if [ -n "$goenv" ]; then
        ynh_print_info --message="goenv already seems installed in \`$goenv'."
        pushd "${goenv%/*/*}"
        if git remote -v 2>/dev/null | grep "https://github.com/syndbg/goenv.git"; then
            echo "Trying to update with git..."
            git pull -q --tags origin master
            cd ..
            ynh_go_try_bash_extension
        fi
        popd
    else
        ynh_print_info --message="Installing goenv with git..."
        mkdir -p $goenv_install_dir
        pushd $goenv_install_dir
        git init -q
        git remote add -f -t master origin https://github.com/syndbg/goenv.git >/dev/null 2>&1
        git checkout -q -b master origin/master
        ynh_go_try_bash_extension
        goenv=$goenv_install_dir/bin/goenv
        popd
    fi

    goenv_latest="$(command -v "$goenv_install_dir"/plugins/*/bin/goenv-latest goenv-latest | head -1)"
    if [ -n "$goenv_latest" ]; then
        ynh_print_info --message="\`goenv latest' command already available in \`$goenv_latest'."
        pushd "${goenv_latest%/*/*}"
        if git remote -v 2>/dev/null | grep "https://github.com/momo-lab/xxenv-latest.git"; then
            ynh_print_info --message="Trying to update xxenv-latest with git..."
            git pull -q origin master
        fi
        popd
    else
        ynh_print_info --message="Installing xxenv-latest with git..."
        mkdir -p "${goenv_install_dir}/plugins"
        git clone -q https://github.com/momo-lab/xxenv-latest.git "${goenv_install_dir}/plugins/xxenv-latest"
    fi

    # Enable caching
    mkdir -p "${goenv_install_dir}/cache"

    # Create shims directory if needed
    mkdir -p "${goenv_install_dir}/shims"

    # Restore /usr/local/bin in PATH
    PATH=$CLEAR_PATH

    # And replace the old Go binary
    test -x /usr/bin/go_goenv && mv /usr/bin/go_goenv /usr/bin/go

    # Install the requested version of Go
    local final_go_version=$(goenv latest --print $go_version)
    ynh_print_info --message="Installation of Go-$final_go_version"
    goenv install --skip-existing --quiet $final_go_version

    # Store go_version into the config of this app
    ynh_app_setting_set --app=$YNH_APP_INSTANCE_NAME --key=go_version --value=$final_go_version

    # Cleanup Go versions
    ynh_cleanup_go

    # Set environment for Go users
    echo "#goenv
export GOENV_ROOT=$goenv_install_dir
export PATH=\"$goenv_install_dir/bin:$PATH\"
eval \"\$(goenv init -)\"
#goenv" >/etc/profile.d/goenv.sh

    # Load the environment
    eval "$(goenv init -)"
}

# Remove the version of Go used by the app.
#
# This helper will also cleanup Go versions
#
# usage: ynh_remove_go
ynh_remove_go() {
    local go_version=$(ynh_app_setting_get --app=$YNH_APP_INSTANCE_NAME --key=go_version)

    # Load goenv path in PATH
    local CLEAR_PATH="$goenv_install_dir/bin:$PATH"

    # Remove /usr/local/bin in PATH in case of Go prior installation
    PATH=$(echo $CLEAR_PATH | sed 's@/usr/local/bin:@@')

    # Remove the line for this app
    ynh_app_setting_delete --app=$YNH_APP_INSTANCE_NAME --key=go_version

    # Cleanup Go versions
    ynh_cleanup_go
}

# Remove no more needed versions of Go used by the app.
#
# This helper will check what Go version are no more required,
# and uninstall them
# If no app uses Go, goenv will be also removed.
#
# usage: ynh_cleanup_go
ynh_cleanup_go() {

    # List required Go versions
    local installed_apps=$(yunohost app list | grep -oP 'id: \K.*$')
    local required_go_versions=""
    for installed_app in $installed_apps; do
        local installed_app_go_version=$(ynh_app_setting_get --app=$installed_app --key="go_version")
        if [[ $installed_app_go_version ]]; then
            required_go_versions="${installed_app_go_version}\n${required_go_versions}"
        fi
    done

    # Remove no more needed Go versions
    local installed_go_versions=$(goenv versions --bare --skip-aliases | grep -Ev '/')
    for installed_go_version in $installed_go_versions; do
        if ! $(echo ${required_go_versions} | grep "${installed_go_version}" 1>/dev/null 2>&1); then
            ynh_print_info --message="Removing of Go-$installed_go_version"
            $goenv_install_dir/bin/goenv uninstall --force $installed_go_version
        fi
    done

    # If none Go version is required
    if [[ ! $required_go_versions ]]; then
        # Remove goenv environment configuration
        ynh_print_info --message="Removing of goenv"
        ynh_secure_remove --file="$goenv_install_dir"
        ynh_secure_remove --file="/etc/profile.d/goenv.sh"
    fi
}

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
