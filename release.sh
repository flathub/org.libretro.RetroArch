#!/bin/sh
# SPDX-License-Identifier: Unlicense
APP_ID="org.libretro.RetroArch"
MANIFEST_FILE="$APP_ID.json"
MANIFEST_TMPL_FILE="$MANIFEST_FILE.tmpl"
APPSTREAM_FILE="$APP_ID.appdata.xml"
CMD="$0"

print_help_text() {
    cat << EOF
release.sh - Release a new version of this project

Usage: $CMD [OPTION...] VERSION

Options:
    --dry-run     Only output what would be done, but don't actually do
                  anything
    --git-tag=TAG Git tag to pull from libretro repositories. In case this
                  distribution caries a different versioning scheme or needs a
                  rebuild to fix downstream specific issues
                  (eg. upstream v1.10.0 -> 1.10.0.1 downstream)
    --no-push     Don't push changes to remote git repository at the end
 -v --verbose     Output debug information (-vv very verbose)
 -h --help        Print this help text and exit

Examples:
    $CMD 1.10.0
    $CMD --git-tag=v1.10.0 1.10.0.hotfix.1
EOF

    exit 0
}

log_error() { printf '%s\n' "$(date -I'seconds') ERROR $*" >&2; }
log_warn() { printf '%s\n' "$(date -I'seconds') WARN $*" >&2; }
log_info() { printf '%s\n' "$(date -I'seconds') INFO $*"; }
log_debug() { [ "$is_verbose" ] && printf '%s\n' "$(date -I'seconds') DEBUG $*"; }
log_trace() { [ "$is_vv" ] && printf '%s\n' "$(date -I'seconds') TRACE $*"; }
abort() { log_error "$*"; exit 1; }
unknown_option() { abort "Unknown option $*. Run $CMD --help"; }

get_argv() {
    [ "$argc" ] || argc=0
    argc=$(($argc + 1))

    case "$argc" in
        1) next_version="$1"
            next_version_tag="v$next_version" ;;
        *) abort "Too many arguments. Run $CMD --help" ;;
    esac
}

read_arguments() {
    for arg in "$@"; do
        case "$arg" in
            --dry-run) is_dry_run=1 ;;
            --git-tag=*) git_tag="${arg#'--git-tag='}" ;;
            --no-push) is_no_push=1 ;;
            --verbose|-v) is_verbose=1 ;;
            -vv) is_vv=1; is_verbose=1 ;;
            --help|-h) print_help_text ;;
            -*) unknown_option "$arg" ;;
            *) get_argv "$arg" ;;
        esac
    done

    [ "$next_version" ] || abort "Missing VERSION argument. Run $CMD --help"
    [ "$git_tag" ] || git_tag="$next_version_tag"

    log_debug "is_dry_run=$is_dry_run"
    log_debug "is_no_push=$is_no_push"
    log_debug "is_verbose=$is_verbose"
    log_debug "is_vv=$is_vv"
    log_debug "git_tag=$git_tag"
    log_debug "next_version=$next_version"
    log_debug "next_version_tag=$next_version_tag"
}

# Escapes text for literal use inside regular expressions
regex_escape() {
    printf '%s' "$(printf '%s' "$*" | sed -E 's/[+*?^$.[{}()|\/\\]|]/\\&/g')"
}

validate_arguments() {
    local version="$(regex_escape "$next_version")"
    local pattern="<release\b[^>]+\bversion=\"$version\"[^>]*>"
    log_debug "validate_arguments() escaped version=$version"
    log_debug "validate_arguments() escaped pattern=$pattern"
    local version_exists="$(grep -E -c -m 1 "$pattern" "$APPSTREAM_FILE")"
    log_debug "validate_arguments() version_exists=$version_exists"

    if [ "$version_exists" -gt 0 ]; then
        if [ "$is_verbose" ]; then
            local matches="$(grep -EnH "$pattern" "$APPSTREAM_FILE")"
            log_debug "$matches"
        fi

        abort "Version $next_version already exists in the AppStream file"
    fi
}

check_dependencies() {
    for dep in "$@"; do
        if ! [ -x "$(command -v "$dep")" ]; then
            log_error "$dep is not installed"
            missing=1
        fi
    done

    if [ "$missing" ]; then
        abort "Aborted due to missing dependencies. Make sure all dependencies are available in the PATH"
    fi
}

check_dependencies cat date git grep sed
read_arguments "$@"
validate_arguments

# Escapes text for use as replacement string in sed's 's' command
sed_replacement_escape() {
    printf '%s' "$(printf '%s' "$*" | sed -E 's/[\\|/&]/\\&/g')"
}

# Escapes text for use in JSON string.
# Only do the minimum escaping for our use-case, not control characters.
json_string_escape() {
    printf '%s' "$(printf '%s' "$*" | sed -E 's/[\\"]/\\&/g')"
}

# Renders a template from a file with simple string substitution
render_tmpl() {
    local tmpl_file="$1"
    local VERSION_TAG="$(sed_replacement_escape "$(json_string_escape "$2")")"
    log_debug "render_tmpl() escaped VERSION_TAG=$VERSION_TAG"
    local result="$(cat "$tmpl_file")"
    local result="$(printf '%s' "$result" | sed -E "s/%%VERSION_TAG%%/$VERSION_TAG/g")"

    [ "$result" ] || abort "render_tmpl() result is null"
    render_tmpl_result="$result"
}

log_info "Rendering template from $MANIFEST_TMPL_FILE with VERSION_TAG=$git_tag to file $MANIFEST_FILE"
render_tmpl "$MANIFEST_TMPL_FILE" "$git_tag"

log_trace "CMD: printf '%s' \"${render_tmpl_result}\" > \"$MANIFEST_FILE\""
if [ "$is_dry_run" ]; then
    log_info "DRY-RUN CMD: printf '%s' \"\$render_tmpl_result\" > \"$MANIFEST_FILE\""
else
    printf '%s' "$render_tmpl_result" > "$MANIFEST_FILE" || abort "Failed to write file $MANIFEST_FILE"
fi

# Escapes text for use in XML attributes
xml_attr_escape() {
    local result="$*"
    local result="$(printf '%s' "$result" | sed -E 's/&/\&amp;/g')" # & must be first
    local result="$(printf '%s' "$result" | sed -E 's/"/\&quot;/g')"
    local result="$(printf '%s' "$result" | sed -E 's/</\&lt;/g')"
    local result="$(printf '%s' "$result" | sed -E 's/>/\&gt;/g')"
    local result="$(printf '%s' "$result" | sed -E "s/'/\&apos;/g")"
    printf '%s' "$result"
}

# Adds a new release tag to AppStream metadata xml
render_appstream() {
    local file="$1"
    local version="$(sed_replacement_escape "$(xml_attr_escape "$2")")"
    local date="$(sed_replacement_escape "$(xml_attr_escape "$3")")"
    log_debug "render_appstream() escaped version=$version"
    log_debug "render_appstream() escaped date=$date"
    local pattern='^\s*<releases>$'
    local result="$(cat "$file")"
    # Use `1,/$pattern/` to match only once. Not strictly necessary here, but safer
    local result="$(printf '%s' "$result" | sed -E "1,/$pattern/ s/$pattern/&\n\
    <release version=\"$version\" date=\"$date\" \/>/")"

    [ "$result" ] || abort "render_appstream() result is null"
    render_appstream_result="$result"
}

current_date="$(date -I'date')"
log_info "Adding release version=\"$next_version\" date=\"$current_date\" to file $APPSTREAM_FILE"
render_appstream "$APPSTREAM_FILE" "$next_version" "$current_date"

log_trace "CMD: printf '%s' \"${render_appstream_result}\" > \"$APPSTREAM_FILE\""
if [ "$is_dry_run" ]; then
    log_info "DRY-RUN CMD: printf '%s' \"\$render_appstream_result\" > \"$APPSTREAM_FILE\""
else
    printf '%s' "$render_appstream_result" > "$APPSTREAM_FILE" || abort "Failed to write file $APPSTREAM_FILE"
fi

log_info "Committing changes to git repository: \"Release $next_version_tag\""
if [ "$is_dry_run" ]; then
    log_info "DRY-RUN CMD: git commit -a -m \"Release $next_version_tag\""
else
    git commit -a -m "Release $next_version_tag" || abort "Failed to commit changes to git repository"
fi

log_info "Creating git tag: $next_version_tag"
if [ "$is_dry_run" ]; then
    log_info "DRY-RUN CMD: git tag \"$next_version_tag\""
else
    git tag "$next_version_tag" || abort "Failed to create git tag"
fi

if [ ! "$is_no_push" ]; then
    log_info "Pushing changes to remote git repository"
    if [ "$is_dry_run" ]; then
        log_info "DRY-RUN CMD: git push origin"
        log_info "DRY-RUN CMD: git push origin \"refs/tags/${next_version_tag}:refs/tags/${next_version_tag}\""
    else
        git push origin || abort "Failed to push commits to remote git repository"
        git push origin "refs/tags/${next_version_tag}:refs/tags/${next_version_tag}" \
            || abort "Failed to push tag to remote git repository"
    fi
fi
