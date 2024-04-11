#!/bin/bash

#---------------- CONSTANTS ---------------- 

TRUE=0
FALSE=1

SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
MAIN_DIR="${HOME}/.bubblebox"
BOX_DIR="${MAIN_DIR}/boxes"
PROF_DIR="${MAIN_DIR}/profiles"

#------------ GLOBAL VARIABLES  ------------ 

g_boxname=""
g_boxpath=""
g_bwrapargs=()

#---------------- EXTRA ----------------

did_read_yes () {
  read -p "Capital Y - yes; anything else - no: " -n1
  echo
  if [ "$REPLY" = "Y" ]; then
    return $TRUE
  fi
  return $FALSE
}

#--------------- PROFILES ---------------- 

disable_prof () {
  g_bwrapargs=()
}

get_profile_path () {
  local prof="$@"
  local profname="${prof##*/}"

  if [ "$prof"="$profname" -a -f "${PROF_DIR}/${profname}.profile" ]; then
    # config name
    echo "${PROF_DIR}/${prof}.profile"
  elif [ -f "$prof" ]; then
    # absolute path
    echo "${prof}"
  else
    echo "No profile $prof found" 1>&2
    return 1
  fi
}

flatten_profile () {
  local profpath="$@"
  local tempa=()

  echo "Include profile $profpath" 1>&2

  # strip the arglist file from comments and read the args into the array
  IFS=$'\n' read -d '' -r -a tempa < <(sed -e '/^#/ d' -e 's/#.*//' "$profpath")

  for i in "${tempa[@]}"; do
    if [ "${i:0:8}" = "!include" ]; then
      flatten_profile "$( get_profile_path "${i:9}" )"
    else
      printf "%s\n" "$i"
    fi
  done
}

include_prof () {
  local tempa=()

  local profpath="$( get_profile_path "$@" )"
  if [ -z "$profpath" ]; then
    return 1;
  fi

  IFS=$'\n' read -d '' -r -a tempa < <( flatten_profile "$profpath" )
  g_bwrapargs+=( "${tempa[@]}" )
}

list_profiles () {
  for i in "${PROF_DIR}"/*.profile; do
    echo "${i##*/}"
  done
}

#---------------- BOX ---------------- 

init_box () {
  g_boxname="$@"
  g_boxpath="$BOX_DIR"/"$g_boxname"
  # include_prof "homebox"
}

get_boxroot () {
  echo "${g_boxpath}"
}

get_home () {
  echo "${g_boxpath}/home"
}

is_box_active () {
  [ -n "$g_boxname" ];
}

is_box_real () {
  [ -d "$g_boxpath" ];
}

make_box () {
  if is_box_real; then
    echo "Error: box $g_boxname exists already"
    exit 1
  fi
  echo "Creating the box at $g_boxpath"
  mkdir -p "$( get_home )"
}

del_box () {
  if is_box_real; then
    echo "Delete the box on ${g_boxpath}?"
    did_read_yes && rm -rf "${g_boxpath}"
  elif is_box_active; then
    echo "There is no box for ${g_boxname}"
    exit 1
  fi
}

list_boxes () {
  for i in "${BOX_DIR}"/*; do
    echo "${i##*/}"
  done
}

run_box () {
  local extra_bwrap_args=${@}
  # g_bwrapargs+=( "$@" )
  echo "Bwrap args:"
  printf '%s\n' "${g_bwrapargs[@]}"
  echo "$extra_bwrap_args"
  eval "bwrap ${g_bwrapargs[@]} $extra_bwrap_args bash"
}

print_help () {
  cat <<EOF
  -b boxname | "box name": specify box
  -c: create specified box
  -d: delete specified box
  -B: list boxes
  -p /absolute/path/profile_name.profile | profile_name: include profile
    Can include profiles within a profile file using the following syntax:
    !include /absolute/path/profile_name.profile | profile_name
  -P: list available profiles
  -r: run bash in the box
    Can propagate arguments to bwrap like that: '-r -- [bwrap arguments]'
  -R: run bash in the box with the most recently used configuration for that box
    If the last command for the box 'mybox' was 'box.sh -b mybox -p myprofile -r',
    then running 'box.sh -b mybox -R' is the same as 'box.sh -b mybox -p myprofile -r'
    The args can be edited in '${MAIN_DIR}/boxes/mybox/lastargs'
  -h: print this message
EOF
}

#---------------- MAIN ----------------

# include_prof "basic"

current_args=$(printf "%q\n" "$@")
# current_args="${*@Q}"
# exit

while getopts ":b:Bcdp:PrRh" Option; do
  case $Option in
    b ) # Specify box
      init_box $OPTARG
      echo "Initialized box: $g_boxname"
      ;;
    c ) # Make box
      make_box
      exit 0
      ;;
    d ) # Delete box
      if ! is_box_active; then
        echo "Need to first specify the box with -b boxname"
        exit 1
      fi
      del_box "$OPTARG"
      ;;
    B ) # List boxes
      list_boxes
      ;;
    # n ) # Disable profile
    #   echo "Disable bubblewrap profiles"
    #   disable_prof
    #   ;;
    p ) # Include profile
      include_prof "$OPTARG"
      if [ $? -ne 0 ]; then
        exit 1;
      fi
      ;;
    P ) # List profiles
      echo "Profiles in $PROF_DIR:"
      list_profiles
      exit 0
      ;;
    r ) # Run shell
      echo "Run box"

      if is_box_active; then 
        if ! is_box_real; then
          echo "Was asked to run a box, however the specified box is not set up yet"
          exit 1
        fi
        # save the command
        echo "$current_args" > "$( get_boxroot )/lastargs"
      fi
      # remaining arguments go to bwrap
      shift $(($OPTIND-1))
      # expecting -- after -r before bwrap args
      run_box ${@:2}
      exit 0
      ;;
    R ) # Run the most recent box config
      if ! is_box_active; then
        echo "You need to specify a box"
        exit 1
      fi
      echo "Run the box with its most recent configuration:"
      if [ -f "$( get_boxroot)/lastargs" ]; then
        mapfile -t <"$( get_boxroot)/lastargs"
        $0 "${MAPFILE[@]}"
        exit 0
      else
        echo "Previous configuration for the box is not found"
        exit 1
      fi
      ;;
    h ) # Help
      print_help
      exit 0
      ;;
  esac
done
# shift $(($OPTIND - 1))
