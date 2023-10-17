#!/usr/bin/env bash

# Automatic build, meant to be used

function usage() {
cat << EOF

Showing help: [ -h | --help | help ]

Without arguments, this script gets the current directory's name and the parent directory's name to build an image tag. It also uses the environment variable DOCKERUSR to build the tag, and prompts you for a docker username if DOCKERUSR is empty. Without arguments, this script then executes by default:

docker build -t ${image_tag} \\
             -f ${dockerfile_name} \\
             --build-arg image_tag=${image_tag} \\
             .

OPTIONS

    ./build.sh -d [ -p -t image_name -f dockerfile -l ]
    ./build.sh -t image_name -l -f dockerfile
    ./build.sh -p -f another_dockerfile

-d(ebug) prints variables and the command that would be executed, doesn't execute anything. Use it for debugging or seeing what would be executed.

-t and -f behave as in docker build, and its corresponding arguments override the default arguments above. Note that only one -t and one -f is supported (the ones declared last).

-l(atest tag) adds an additional "latest" tag to docker build, constructed automatically as the default -t:
-t ${docker_user}${image_name}:latest

-p(rueba) deletes any -t or -l options, default or passed, and instead uses:
-t ${docker_user}${image_name}:test
It preserves the default or passed -f

EOF
}

function debug_print() {
cat <<- EOF
Debug print to inspect variables:

dockerfile_name = ${dockerfile_name}
bc_f = ${bc_f}

docker_user = ${docker_user}
tag = ${tag}
image_name = ${image_name}
image_tag = ${image_tag}
bc_t = ${bc_t}

bc_l = ${bc_l}

test_flag = ${test_flag}
debug_flag = ${debug_flag}

build_command:
$build_command
EOF
}


### Default dockerfile
dockerfile_name="Dockerfile"
bc_f="-f ${dockerfile_name} "

### Default image tag
# docker user
#   docker_user will contain "/" unless the user leaves it empty when prompted
echo "Note: A message about DOCKERUSR is shown ALWAYS (even if passing -h | --help | help). To skip the prompt if you see one and see help just press ENTER."
echo ""
if [ "${DOCKERUSR}" != "" ] ; then
    echo "Using the DOCKERUSR (set to ${DOCKERUSR}) environment variable to automatically build the image tag (unless you passed the -t option, which overrides the automatic image tag)"
    docker_user="${DOCKERUSR}/"
else
    echo "Environment variable DOCKERUSR not found, please enter your docker username or press ENTER to leave the image tag without username (e.g., you just don't want one, or passed the -t option, which overrides the automatic image tag): "
    read d_user
    [ "${d_user}" != "" ] \
    && docker_user="${d_user}/" \
    || docker_user="${d_user}"
fi
echo ""
# current and parent directories' names by brute force
script_dir="$( dirname "$0" )"
builtin cd $script_dir
# By default, image_tag is based on how base directories are named, as in parent_dir:script_dir
tag=${PWD##*/}
image_name=$( builtin cd ../ && echo "${PWD##*/}" )
image_tag="${docker_user}${image_name}:${tag}"
bc_t="-t ${image_tag} "

# Default latest tag is empty and flags are False
bc_l=
test_flag="False"
debug_flag="False"


### Main
case "$1" in
    "-h" | "--help" | "help")
        usage
        exit 1 ;;
esac

# -t and -f are the same as in docker build
possible_option_arguments=":t:f:lpd"
while getopts ${possible_option_arguments} arg; do
    case "${arg}" in
        t)  image_tag="${OPTARG}"
            bc_t="-t ${image_tag} " ;;

        f)  dockerfile_name="${OPTARG}"
            bc_f="-f ${dockerfile_name} " ;;

        l)  bc_l="-t ${docker_user}${image_name}:latest " ;;

        p)  test_flag="True" ;;

        d)  debug_flag="True" ;;
    esac
done

[ "${test_flag}" == "True" ] \
&& image_tag="${docker_user}${image_name}:test" \
&& bc_t="-t ${image_tag} " \
&& bc_l=


# Execution
build_command="docker build ${bc_t}${bc_l}${bc_f}--build-arg image_tag=${image_tag} ."

[ "${debug_flag}" == "True" ] \
&& debug_print && exit 1

eval $build_command
