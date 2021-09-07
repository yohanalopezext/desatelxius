#   ...rest of your script...
#
# In order for the '--version' option to work, you will need to have a
# suitably formatted comment like the one at the top of this file
# starting with '# Written by ' and ending with '# warranty; '.
#
# For '-h' and '--help' to work, you will also need a one line
# description of your script's purpose in a comment directly above the
# '# Written by ' line, like the one at the top of this file.
#
# The default options also support '--debug', which will turn on shell
# execution tracing (see the comment above debug_cmd below for another
# use), and '--verbose' and the func_verbose function to allow your script
# to display verbose messages only when your user has specified
# '--verbose'.
#
# After sourcing this file, you can plug processing for additional
# options by amending the variables from the 'Configuration' section
# below, and following the instructions in the 'Option parsing'
# section further down.
## -------------- ##
## Configuration. ##
## -------------- ##
# You should override these variables in your script after sourcing this
# file so that they reflect the customisations you have added to the
# option parser.
# The usage line for option parsing errors and the start of '-h' and
# '--help' output messages. You can embed shell variables for delayed
# expansion at the time the message is displayed, but you will need to
# quote other shell meta-characters carefully to prevent them being
# expanded when the contents are evaled.
usage='$progpath [OPTION]...'
# Short help message in response to '-h' and '--help'.  Add to this or
# override it after sourcing this library to reflect the full set of
# options your script accepts.
usage_message="\
       --debug        enable verbose shell tracing
   -W, --warnings=CATEGORY
                      report the warnings falling in CATEGORY [all]
   -v, --verbose      verbosely report processing
       --version      print version information and exit
   -h, --help         print short or long help message and exit
"
# Additional text appended to 'usage_message' in response to '--help'.
long_help_message="
Warning categories include:
       'all'          show all warnings
       'none'         turn off all the warnings
       'error'        warnings are treated as fatal errors"
# Help message printed before fatal option parsing errors.
fatal_help="Try '\$progname --help' for more information."
## ------------------------- ##
## Hook function management. ##
## ------------------------- ##
# This section contains functions for adding, removing, and running hooks
# to the main code.  A hook is just a named list of of function, that can
# be run in order later on.
# func_hookable FUNC_NAME
# -----------------------
# Declare that FUNC_NAME will run hooks added with
# 'func_add_hook FUNC_NAME ...'.
func_hookable () {     $debug_cmd;      func_append hookable_fns " $1"; }
# func_add_hook FUNC_NAME HOOK_FUNC
# ---------------------------------
# Request that FUNC_NAME call HOOK_FUNC before it returns.  FUNC_NAME must
# first have been declared "hookable" by a call to 'func_hookable'.
func_add_hook () {     $debug_cmd;      case " $hookable_fns " in       *" $1 "*) ;;       *) func_fatal_error "'$1' does not accept hook functions." ;;     esac;      eval func_append ${1}_hooks '" $2"'; }
# func_remove_hook FUNC_NAME HOOK_FUNC
# ------------------------------------
# Remove HOOK_FUNC from the list of functions called by FUNC_NAME.
func_remove_hook () {     $debug_cmd;      eval ${1}_hooks='`$ECHO "\$'$1'_hooks" |$SED "s| '$2'||"`'; }
# func_run_hooks FUNC_NAME [ARG]...
# ---------------------------------
# Run all hook functions registered to FUNC_NAME.
# It is assumed that the list of hook functions contains nothing more
# than a whitespace-delimited list of legal shell function names, and
# no effort is wasted trying to catch shell meta-characters or preserve
# whitespace.
func_run_hooks () {     $debug_cmd;      case " $hookable_fns " in       *" $1 "*) ;;       *) func_fatal_error "'$1' does not support hook funcions.n" ;;     esac;      eval _G_hook_fns=\$$1_hooks; shift;      for _G_hook in $_G_hook_fns; do       eval $_G_hook '"$@"';        eval _G_hook_result=\$${_G_hook}_result;       eval set dummy "$_G_hook_result"; shift;     done;      func_quote_for_eval ${1+"$@"};     func_run_hooks_result=$func_quote_for_eval_result; }
## --------------- ##
## Option parsing. ##
## --------------- ##
# In order to add your own option parsing hooks, you must accept the
# full positional parameter list in your hook function, remove any
# options that you action, and then pass back the remaining unprocessed
# options in '<hooked_function_name>_result', escaped suitably for
# 'eval'.  Like this:
#
#    my_options_prep ()
#    {
#        $debug_cmd
#
#        # Extend the existing usage message.
#        usage_message=$usage_message'
#      -s, --silent       don'\''t print informational messages
#    '
#
#        func_quote_for_eval ${1+"$@"}
#        my_options_prep_result=$func_quote_for_eval_result
#    }
#    func_add_hook func_options_prep my_options_prep
#
#
#    my_silent_option ()
#    {
#        $debug_cmd
#
#        # Note that for efficiency, we parse as many options as we can
#        # recognise in a loop before passing the remainder back to the
#        # caller on the first unrecognised argument we encounter.
#        while test $# -gt 0; do
#          opt=$1; shift
#          case $opt in
#            --silent|-s) opt_silent=: ;;
#            # Separate non-argument short options:
#            -s*)         func_split_short_opt "$_G_opt"
#                         set dummy "$func_split_short_opt_name" \
#                             "-$func_split_short_opt_arg" ${1+"$@"}
#                         shift
#                         ;;
#            *)            set dummy "$_G_opt" "$*"; shift; break ;;
#          esac
#        done
#
#        func_quote_for_eval ${1+"$@"}
#        my_silent_option_result=$func_quote_for_eval_result
#    }
#    func_add_hook func_parse_options my_silent_option
#
#
#    my_option_validation ()
#    {
#        $debug_cmd
#
#        $opt_silent && $opt_verbose && func_fatal_help "\
#    '--silent' and '--verbose' options are mutually exclusive."
#
#        func_quote_for_eval ${1+"$@"}
#        my_option_validation_result=$func_quote_for_eval_result
#    }
#    func_add_hook func_validate_options my_option_validation
#
# You'll alse need to manually amend $usage_message to reflect the extra
# options you parse.  It's preferable to append if you can, so that
# multiple option parsing hooks can be added safely.
# func_options [ARG]...
# ---------------------
# All the functions called inside func_options are hookable. See the
# individual implementations for details.
func_hookable func_options
func_options () {     $debug_cmd;      func_options_prep ${1+"$@"};     eval func_parse_options         ${func_options_prep_result+"$func_options_prep_result"};     eval func_validate_options         ${func_parse_options_result+"$func_parse_options_result"};      eval func_run_hooks func_options         ${func_validate_options_result+"$func_validate_options_result"};      func_options_result=$func_run_hooks_result; }
# func_options_prep [ARG]...
# --------------------------
# All initialisations required before starting the option parse loop.
# Note that when calling hook functions, we pass through the list of
# positional parameters.  If a hook function modifies that list, and
# needs to propogate that back to rest of this script, then the complete
# modified list must be put in 'func_run_hooks_result' before
# returning.
func_hookable func_options_prep
func_options_prep () {     $debug_cmd;      opt_verbose=false;     opt_warning_types=;      func_run_hooks func_options_prep ${1+"$@"};      func_options_prep_result=$func_run_hooks_result; }
# func_parse_options [ARG]...
# ---------------------------
# The main option parsing loop.
func_hookable func_parse_options
func_parse_options () {     $debug_cmd;      func_parse_options_result=;      while test $# -gt 0; do       func_run_hooks func_parse_options ${1+"$@"};        eval set dummy "$func_run_hooks_result"; shift;        test $# -gt 0 || break;        _G_opt=$1;       shift;       case $_G_opt in         --debug|-x)   debug_cmd='set -x';                       func_echo "enabling shell trace mode";                       $debug_cmd;                       ;;         --no-warnings|--no-warning|--no-warn)                       set dummy --warnings none ${1+"$@"};                       shift; 		      ;;         --warnings|--warning|-W)                       test $# = 0 && func_missing_arg $_G_opt && break;                       case " $warning_categories $1" in                         *" $1 "*)                           func_append_uniq opt_warning_types " $1";                           ;;                         *all)                           opt_warning_types=$warning_categories;                           ;;                         *none)                           opt_warning_types=none;                           warning_func=:;                           ;;                         *error)                           opt_warning_types=$warning_categories;                           warning_func=func_fatal_error;                           ;;                         *)                           func_fatal_error                              "unsupported warning category: '$1'";                           ;;                       esac;                       shift;                       ;;         --verbose|-v) opt_verbose=: ;;         --version)    func_version ;;         -\?|-h)       func_usage ;;         --help)       func_help ;; 	--*=*)        func_split_equals "$_G_opt"; 	              set dummy "$func_split_equals_lhs"                           "$func_split_equals_rhs" ${1+"$@"};                       shift;                       ;;         -W*);                       func_split_short_opt "$_G_opt";                       set dummy "$func_split_short_opt_name"                           "$func_split_short_opt_arg" ${1+"$@"};                       shift;                       ;;         -\?*|-h*|-v*|-x*);                       func_split_short_opt "$_G_opt";                       set dummy "$func_split_short_opt_name"                           "-$func_split_short_opt_arg" ${1+"$@"};                       shift;                       ;;         --)           break ;;         -*)           func_fatal_help "unrecognised option: '$_G_opt'" ;;         *)            set dummy "$_G_opt" ${1+"$@"}; shift; break ;;       esac;     done;      func_quote_for_eval ${1+"$@"};     func_parse_options_result=$func_quote_for_eval_result; }
# func_validate_options [ARG]...
# ------------------------------
# Perform any sanity checks on option settings and/or unconsumed
# arguments.
func_hookable func_validate_options
func_validate_options () {     $debug_cmd;      test -n "$opt_warning_types" || opt_warning_types=" $warning_categories";      func_run_hooks func_validate_options ${1+"$@"};      $exit_cmd $EXIT_FAILURE;      func_validate_options_result=$func_run_hooks_result; }
## ----------------- ##
## Helper functions. ##
## ----------------- ##
# This section contains the helper functions used by the rest of the
# hookable option parser framework in ascii-betical order.
# func_fatal_help ARG...
# ----------------------
# Echo program name prefixed message to standard error, followed by
# a help hint, and exit.
func_fatal_help () {     $debug_cmd;      eval \$ECHO \""Usage: $usage"\";     eval \$ECHO \""$fatal_help"\";     func_error ${1+"$@"};     exit $EXIT_FAILURE; }
# func_help
# ---------
# Echo long help message to standard output and exit.
func_help () {     $debug_cmd;      func_usage_message;     $ECHO "$long_help_message";     exit 0; }
# func_missing_arg ARGNAME
# ------------------------
# Echo program name prefixed message to standard error and set global
# exit_cmd.
func_missing_arg () {     $debug_cmd;      func_error "Missing argument for '$1'.";     exit_cmd=exit; }
# func_split_equals STRING
# ------------------------
# Set func_split_equals_lhs and func_split_equals_rhs shell variables after
# splitting STRING at the '=' sign.
test -z "$_G_HAVE_XSI_OPS"     && (eval 'x=a/b/c;
      test 5aa/bb/cc = "${#x}${x%%/*}${x%/*}${x#*/}${x##*/}"') 2>/dev/null     && _G_HAVE_XSI_OPS=yes
if test yes = "$_G_HAVE_XSI_OPS"; then   eval 'func_split_equals ()
  {
      $debug_cmd

      func_split_equals_lhs=${1%%=*}
      func_split_equals_rhs=${1#*=}
      test "x$func_split_equals_lhs" = "x$1" \
        && func_split_equals_rhs=
  }'; else   func_split_equals ()   {       $debug_cmd;        func_split_equals_lhs=`expr "x$1" : 'x\([^=]*\)'`;       func_split_equals_rhs=;       test "x$func_split_equals_lhs" = "x$1"         || func_split_equals_rhs=`expr "x$1" : 'x[^=]*=\(.*\)$'`;   }; fi #func_split_equals
# func_split_short_opt SHORTOPT
# -----------------------------
# Set func_split_short_opt_name and func_split_short_opt_arg shell
# variables after splitting SHORTOPT after the 2nd character.
if test yes = "$_G_HAVE_XSI_OPS"; then   eval 'func_split_short_opt ()
  {
      $debug_cmd

      func_split_short_opt_arg=${1#??}
      func_split_short_opt_name=${1%"$func_split_short_opt_arg"}
  }'; else   func_split_short_opt ()   {       $debug_cmd;        func_split_short_opt_name=`expr "x$1" : 'x-\(.\)'`;       func_split_short_opt_arg=`expr "x$1" : 'x-.\(.*\)$'`;   }; fi #func_split_short_opt
# func_usage
# ----------
# Echo short help message to standard output and exit.
func_usage () {     $debug_cmd;      func_usage_message;     $ECHO "Run '$progname --help |${PAGER-more}' for full usage";     exit 0; }
# func_usage_message
# ------------------
# Echo short help message to standard output.
func_usage_message () {     $debug_cmd;      eval \$ECHO \""Usage: $usage"\";     echo;     $SED -n 's|^# ||
        /^Written by/{
          x;p;x
        }
	h
	/^Written by/q' < "$progpath";     echo;     eval \$ECHO \""$usage_message"\"; }
# func_version
# ------------
# Echo version message to standard output and exit.
func_version () {     $debug_cmd;      printf '%s\n' "$progname $scriptversion";     $SED -n '
        /(C)/!b go
        :more
        /\./!{
          N
          s|\n# | |
          b more
        }
        :go
        /^# Written by /,/# warranty; / {
          s|^# ||
          s|^# *$||
          s|\((C)\)[ 0-9,-]*[ ,-]\([1-9][0-9]* \)|\1 \2|
          p
        }
        /^# Written by / {
          s|^# ||
          p
        }
        /^warranty; /q' < "$progpath";      exit $?; }
# Local variables:
# mode: shell-script
# sh-indentation: 2
# eval: (add-hook 'before-save-hook 'time-stamp)
# time-stamp-pattern: "10/scriptversion=%:y-%02m-%02d.%02H; # UTC"
# time-stamp-time-zone: "UTC"
# End:
# Set a version string.
scriptversion='(GNU libtool) 2.4.6'
# func_echo ARG...
# ----------------
# Libtool also displays the current mode in messages, so override
# funclib.sh func_echo with this custom definition.
func_echo () {     $debug_cmd;      _G_message=$*;      func_echo_IFS=$IFS;     IFS=$nl;     for _G_line in $_G_message; do       IFS=$func_echo_IFS;       $ECHO "$progname${opt_mode+: $opt_mode}: $_G_line";     done;     IFS=$func_echo_IFS; }
# func_warning ARG...
# -------------------
# Libtool warnings are not categorized, so override funclib.sh
# func_warning with this simpler definition.
func_warning () {     $debug_cmd;      $warning_func ${1+"$@"}; }
## ---------------- ##
## Options parsing. ##
## ---------------- ##
# Hook in the functions to make sure our own options are parsed during
# the option parsing loop.
usage='$progpath [OPTION]... [MODE-ARG]...'
# Short help message in response to '-h'.
usage_message="Options:
       --config             show all configuration variables
       --debug              enable verbose shell tracing
   -n, --dry-run            display commands without modifying any files
       --features           display basic configuration information and exit
       --mode=MODE          use operation mode MODE
       --no-warnings        equivalent to '-Wnone'
       --preserve-dup-deps  don't remove duplicate dependency libraries
       --quiet, --silent    don't print informational messages
       --tag=TAG            use configuration variables from tag TAG
   -v, --verbose            print more informational messages than default
       --version            print version information
   -W, --warnings=CATEGORY  report the warnings falling in CATEGORY [all]
   -h, --help, --help-all   print short, long, or detailed help message
"
# Additional text appended to 'usage_message' in response to '--help'.
func_help () {     $debug_cmd;      func_usage_message;     $ECHO "$long_help_message

MODE must be one of the following:

       clean           remove files from the build directory
       compile         compile a source file into a libtool object
       execute         automatically set library path, then run a program
       finish          complete the installation of libtool libraries
       install         install libraries or executables
       link            create a library or an executable
       uninstall       remove libraries from an installed directory

MODE-ARGS vary depending on the MODE.  When passed as first option,
'--mode=MODE' may be abbreviated as 'MODE' or a unique abbreviation of that.
Try '$progname --help --mode=MODE' for a more detailed description of MODE.

When reporting a bug, please describe a test case to reproduce it and
include the following information:

       host-triplet:   $host
       shell:          $SHELL
       compiler:       $LTCC
       compiler flags: $LTCFLAGS
       linker:         $LD (gnu? $with_gnu_ld)
       version:        $progname (GNU libtool) 2.4.6
       automake:       `($AUTOMAKE --version) 2>/dev/null |$SED 1q`
       autoconf:       `($AUTOCONF --version) 2>/dev/null |$SED 1q`

Report bugs to <bug-libtool@gnu.org>.
GNU libtool home page: <http://www.gnu.org/s/libtool/>.
General help using GNU software: <http://www.gnu.org/gethelp/>.";     exit 0; }
# func_lo2o OBJECT-NAME
# ---------------------
# Transform OBJECT-NAME from a '.lo' suffix to the platform specific
# object suffix.
lo2o=s/\\.lo\$/.$objext/
o2lo=s/\\.$objext\$/.lo/
if test yes = "$_G_HAVE_XSI_OPS"; then   eval 'func_lo2o ()
  {
    case $1 in
      *.lo) func_lo2o_result=${1%.lo}.$objext ;;
      *   ) func_lo2o_result=$1               ;;
    esac
  }';    eval 'func_xform ()
  {
    func_xform_result=${1%.*}.lo
  }'; else   func_lo2o ()   {     func_lo2o_result=`$ECHO "$1" | $SED "$lo2o"`;   };    func_xform ()   {     func_xform_result=`$ECHO "$1" | $SED 's|\.[^.]*$|.lo|'`;   }; fi
# func_fatal_configuration ARG...
# -------------------------------
# Echo program name prefixed message to standard error, followed by
# a configuration failure hint, and exit.
func_fatal_configuration () {     func__fatal_error ${1+"$@"}       "See the $PACKAGE documentation for more information."       "Fatal configuration error."; }
# func_config
# -----------
# Display the configuration for all the tags in this script.
func_config () {     re_begincf='^# ### BEGIN LIBTOOL';     re_endcf='^# ### END LIBTOOL';      $SED "1,/$re_begincf CONFIG/d;/$re_endcf CONFIG/,\$d" < "$progpath";      for tagname in $taglist; do       $SED -n "/$re_begincf TAG CONFIG: $tagname\$/,/$re_endcf TAG CONFIG: $tagname\$/p" < "$progpath";     done;      exit $?; }
# func_features
# -------------
# Display the features supported by this script.
func_features () {     echo "host: $host";     if test yes = "$build_libtool_libs"; then       echo "enable shared libraries";     else       echo "disable shared libraries";     fi;     if test yes = "$build_old_libs"; then       echo "enable static libraries";     else       echo "disable static libraries";     fi;      exit $?; }
# func_enable_tag TAGNAME
# -----------------------
# Verify that TAGNAME is valid, and either flag an error and exit, or
# enable the TAGNAME tag.  We also add TAGNAME to the global $taglist
# variable here.
func_enable_tag () {     tagname=$1;      re_begincf="^# ### BEGIN LIBTOOL TAG CONFIG: $tagname\$";     re_endcf="^# ### END LIBTOOL TAG CONFIG: $tagname\$";     sed_extractcf=/$re_begincf/,/$re_endcf/p;      case $tagname in       *[!-_A-Za-z0-9,/]*)         func_fatal_error "invalid tag name: $tagname";         ;;     esac;      case $tagname in         CC) ;;     *)         if $GREP "$re_begincf" "$progpath" >/dev/null 2>&1; then 	  taglist="$taglist $tagname";  	  extractedcf=`$SED -n -e "$sed_extractcf" < "$progpath"`; 	  eval "$extractedcf";         else 	  func_error "ignoring unknown tag $tagname";         fi;         ;;     esac; }
# func_check_version_match
# ------------------------
# Ensure that we are using m4 macros, and libtool script from the same
# release of libtool.
func_check_version_match () {     if test "$package_revision" != "$macro_revision"; then       if test "$VERSION" != "$macro_version"; then         if test -z "$macro_version"; then
          cat >&2 <<_LT_EOF
$progname: Version mismatch error.  This is $PACKAGE $VERSION, but the
$progname: definition of this LT_INIT comes from an older release.
$progname: You should recreate aclocal.m4 with macros from $PACKAGE $VERSION
$progname: and run autoconf again.
_LT_EOF
         else
          cat >&2 <<_LT_EOF
$progname: Version mismatch error.  This is $PACKAGE $VERSION, but the
$progname: definition of this LT_INIT comes from $PACKAGE $macro_version.
$progname: You should recreate aclocal.m4 with macros from $PACKAGE $VERSION
$progname: and run autoconf again.
_LT_EOF
         fi;       else
        cat >&2 <<_LT_EOF
$progname: Version mismatch error.  This is $PACKAGE $VERSION, revision $package_revision,
$progname: but the definition of this LT_INIT comes from revision $macro_revision.
$progname: You should recreate aclocal.m4 with macros from revision $package_revision
$progname: of $PACKAGE $VERSION and run autoconf again.
_LT_EOF
       fi;        exit $EXIT_MISMATCH;     fi; }
# libtool_options_prep [ARG]...
# -----------------------------
# Preparation for options parsed by libtool.
libtool_options_prep () {     $debug_mode;      opt_config=false;     opt_dlopen=;     opt_dry_run=false;     opt_help=false;     opt_mode=;     opt_preserve_dup_deps=false;     opt_quiet=false;      nonopt=;     preserve_args=;      case $1 in     clean|clea|cle|cl)       shift; set dummy --mode clean ${1+"$@"}; shift;       ;;     compile|compil|compi|comp|com|co|c)       shift; set dummy --mode compile ${1+"$@"}; shift;       ;;     execute|execut|execu|exec|exe|ex|e)       shift; set dummy --mode execute ${1+"$@"}; shift;       ;;     finish|finis|fini|fin|fi|f)       shift; set dummy --mode finish ${1+"$@"}; shift;       ;;     install|instal|insta|inst|ins|in|i)       shift; set dummy --mode install ${1+"$@"}; shift;       ;;     link|lin|li|l)       shift; set dummy --mode link ${1+"$@"}; shift;       ;;     uninstall|uninstal|uninsta|uninst|unins|unin|uni|un|u)       shift; set dummy --mode uninstall ${1+"$@"}; shift;       ;;     esac;      func_quote_for_eval ${1+"$@"};     libtool_options_prep_result=$func_quote_for_eval_result; }
func_add_hook func_options_prep libtool_options_prep
# libtool_parse_options [ARG]...
# ---------------------------------
# Provide handling for libtool specific options.
libtool_parse_options () {     $debug_cmd;      while test $# -gt 0; do       _G_opt=$1;       shift;       case $_G_opt in         --dry-run|--dryrun|-n)                         opt_dry_run=:;                         ;;         --config)       func_config ;;         --dlopen|-dlopen)                         opt_dlopen="${opt_dlopen+$opt_dlopen
}$1";                         shift;                         ;;         --preserve-dup-deps)                         opt_preserve_dup_deps=: ;;         --features)     func_features ;;         --finish)       set dummy --mode finish ${1+"$@"}; shift ;;         --help)         opt_help=: ;;         --help-all)     opt_help=': help-all' ;;         --mode)         test $# = 0 && func_missing_arg $_G_opt && break;                         opt_mode=$1;                         case $1 in                           clean|compile|execute|finish|install|link|relink|uninstall) ;;                           *) func_error "invalid argument for $_G_opt";                              exit_cmd=exit;                              break;                              ;;                         esac;                         shift;                         ;;         --no-silent|--no-quiet);                         opt_quiet=false;                         func_append preserve_args " $_G_opt";                         ;;         --no-warnings|--no-warning|--no-warn);                         opt_warning=false;                         func_append preserve_args " $_G_opt";                         ;;         --no-verbose);                         opt_verbose=false;                         func_append preserve_args " $_G_opt";                         ;;         --silent|--quiet);                         opt_quiet=:;                         opt_verbose=false;                         func_append preserve_args " $_G_opt";                         ;;         --tag)          test $# = 0 && func_missing_arg $_G_opt && break;                         opt_tag=$1;                         func_append preserve_args " $_G_opt $1";                         func_enable_tag "$1";                         shift;                         ;;         --verbose|-v)   opt_quiet=false;                         opt_verbose=:;                         func_append preserve_args " $_G_opt";                         ;;         *)		set dummy "$_G_opt" ${1+"$@"};	shift; break  ;;       esac;     done;      func_quote_for_eval ${1+"$@"};     libtool_parse_options_result=$func_quote_for_eval_result; }
func_add_hook func_parse_options libtool_parse_options
# libtool_validate_options [ARG]...
# ---------------------------------
# Perform any sanity checks on option settings and/or unconsumed
# arguments.
libtool_validate_options () {     if test 0 -lt $#; then       nonopt=$1;       shift;     fi;      test : = "$debug_cmd" || func_append preserve_args " --debug";      case $host in       *cygwin* | *mingw* | *pw32* | *cegcc* | *solaris2* | *os2*)         opt_duplicate_compiler_generated_deps=:;         ;;       *)         opt_duplicate_compiler_generated_deps=$opt_preserve_dup_deps;         ;;     esac;      $opt_help || {       func_check_version_match;        test yes != "$build_libtool_libs"         && test yes != "$build_old_libs"         && func_fatal_configuration "not configured to build any kind of library";        eval std_shrext=\"$shrext_cmds\";        if test -n "$opt_dlopen" && test execute != "$opt_mode"; then         func_error "unrecognized option '-dlopen'";         $ECHO "$help" 1>&2;         exit $EXIT_FAILURE;       fi;        generic_help=$help;       help="Try '$progname --help --mode=$opt_mode' for more information.";     };      func_quote_for_eval ${1+"$@"};     libtool_validate_options_result=$func_quote_for_eval_result; }
func_add_hook func_validate_options libtool_validate_options
# Process options as early as possible so that --help and --version
# can return quickly.
func_options ${1+"$@"}
$ git config --global user.name "Desa Yohana"
git config --global user.name "Yohana Desa"
git config --global user.email yohana.lopez.ext@telefonica.com
git config --list
git remote add origin git@github.com:yohanalopezext/desatelxius.git
echo "# desatelxius" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:yohanalopezext/desatelxius.git
git push -u origin main
git remote add origin git@github.com:yohanalopezext/desatelxius.git
git branch -M main
git push -u origin main
cd
python3 -m pip install -user virtualenv
mkdir entorno-virtual
cd entorno-virtual/
mkdir airflow
virtualenv airflow -p python3
pip3 show virtalenv
cd..
cd
cd
python3 -m pip install --user virtualenv
cd entorno-virtual
cd airflow
cd
cd
pip3 show virtualenv
python3 -m pip install -user virtualenv
python3 C:\Users\yohana\AppData\Local\Programs\Python\Python39\virtualenv
python3 C:\Users\yohana\AppData\Local\Programs\Python\Python39\virtualenv
python3 C:\Users\yohana\AppData\Local\Programs\Python\Python39\Lib\site-packages\virtualenv airflow -p python3
cd entorno-virtual
cd airflow
ls
cd
cd entrono-virtual
cd entorno-virtual
pip show virtualenv
ls
cd
python3 -m pip install --user virtalenv
python3 -m venv /path/to/new/virtual/environment
cd entorno-virtual
virtualenv airflow -p python3
pip3 show virtualenv
pip show virtualenv
cd
ls
cd entorno-virtual
cd airflow
ls
cd
cd entorno-virtual
ls
cd
ls
cd airflow
ls
airflow db init
cd
cd sqlite
ls
cd
sqlite3
sqlite3
cd sqlite
sqltile3
cd
tar xvfz sqlite-autoconf-3071502.tar.gz
cd sqlite-autoconf-3360000
./configure --prefix=/usr/local
make
make install
py -m make install
make
cd
cd entorno-vistual
cd entorno-vistual
cd entorno-virtual
cd airflow
airflow db init
cd
cd airflow
airflow initdb
exit
cd entorno-virtual
.\airflow\Scripts\activate
source airflow/bin/activate
exit
