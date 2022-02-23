
# FIXME: set default config, old c64, pepto palette
#C64HDLOPTS+=" -no-driver"
#C64HDLOPTS+=" -debugcart"
#C64HDLOPTS+=" -ane-magic 0xef"
#C64HDLOPTS+=" -lax-magic 0xee"
#C64HDLOPTS+=" -autostart-prg 2"
#C64HDLOPTS+=" -fast-testbench"

# extra options for the different ways tests can be run
#C64HDLOPTSEXITCODE+=" -no-gui"
#C64HDLOPTSSCREENSHOT+=" -no-gui"

# X and Y offsets for saved screenshots. when saving a screenshot in the
# computers reset/startup screen, the offset gives the top left pixel of the
# top left character on screen.
C64HDLSXO=32
C64HDLSYO=35

C64HDLREFSXO=32
C64HDLREFSYO=35

function c64hdl_check_environment
{
    C64HDL="$EMUDIR"c64hdl
    if ! [ -x "$(command -v $C64HDL)" ]; then
        echo 'Error: '$C64HDL' not found.' >&2
        exit 1
    fi
    # is this correct?
    emu_default_videosubtype="6569"
}

# $1  option
# $2  test path
function c64hdl_get_options
{
#    echo c64hdl_get_options "$1" "$2"
    exitoptions=""
    case "$1" in
        "default")
                exitoptions=""
            ;;
        "vicii-pal")
                exitoptions="-vic-6569R3"
                testprogvideotype="PAL"
            ;;
        "vicii-ntsc")
                exitoptions="-vic-6567R8"
                testprogvideotype="NTSC"
            ;;
        "vicii-ntscold")
                exitoptions="-vic-6567R56A"
                testprogvideotype="NTSCOLD"
            ;;
        "vicii-old") 
                if [ x"$testprogvideotype"x == x"PAL"x ]; then
                    # "old" PAL
                    exitoptions="-vic-6569R3"
                    testprogvideosubtype="6569"
                fi
                if [ x"$testprogvideotype"x == x"NTSC"x ]; then
                    # "old" NTSC
                    exitoptions="-vic-6567R8"
                    testprogvideosubtype="6567"
                fi
            ;;
        "vicii-new") 
                if [ x"$testprogvideotype"x == x"PAL"x ]; then
                    # "new" PAL
                    exitoptions="-vic-8565"
                    testprogvideosubtype="8565"
                fi
                if [ x"$testprogvideotype"x == x"NTSC"x ]; then
                    # "new" NTSC
                    exitoptions="-vic-8562"
                    testprogvideosubtype="8562"
                fi
            ;;
        "cia-old")
                exitoptions="-cia-6526"
                new_cia_enabled=0
            ;;
        "cia-new")
                exitoptions="-cia-6526a"
                new_cia_enabled=1
            ;;
        "sid-old")
                exitoptions="-sid-6581"
                new_sid_enabled=0
            ;;
        "sid-new")
                exitoptions="-sid-8580"
                new_sid_enabled=1
            ;;
        "reu128k")
                exitoptions="-reu 128"
                reu_enabled=1
            ;;
        "reu256k")
                exitoptions="-reu 256"
                reu_enabled=1
            ;;
        "reu512k")
                exitoptions="-reu 512"
                reu_enabled=1
            ;;
        "reu1m")
                exitoptions="-reu 1024"
                reu_enabled=1
            ;;
        "reu2m")
                exitoptions="-reu 2048"
                reu_enabled=1
            ;;
        "reu4m")
                exitoptions="-reu 4096"
                reu_enabled=1
            ;;
        "reu8m")
                exitoptions="-reu 8192"
                reu_enabled=1
            ;;
        "reu16m")
                exitoptions="-reu 16384"
                reu_enabled=1
            ;;
        "geo512k")
                exitoptions="-georam 512"
                georam_enabled=1
            ;;
            
        *)
                exitoptions=""
                if [ "${1:0:9}" == "mountd64:" ]; then
                    exitoptions=" $2/${1:9}"
                    mounted_d64="${1:9}"
                    echo -ne "(disk:${1:9}) "
                fi
                if [ "${1:0:9}" == "mountg64:" ]; then
                    exitoptions=" $2/${1:9}"
                    mounted_g64="${1:9}"
                    echo -ne "(disk:${1:9}) "
                fi
                if [ "${1:0:9}" == "mountp64:" ]; then
                    exitoptions=" $2/${1:9}"
                    mounted_p64="${1:9}"
                    echo -ne "(disk:${1:9}) "
                fi
                if [ "${1:0:9}" == "mountcrt:" ]; then
                    exitoptions=" $2/${1:9}"
                    mounted_crt="${1:9}"
                    echo -ne "(cartridge:${1:9}) "
                fi
            ;;
    esac
}

# $1  option
# $2  test path
function c64hdl_get_cmdline_options
{
#    echo c64hdl_get_cmdline_options "$1" "$2"
    exitoptions=""
    case "$1" in
        "PAL")
                exitoptions=""
            ;;
        "NTSC")
                exitoptions=""
            ;;
        "NTSCOLD")
                exitoptions=""
            ;;
        "6569") # "old" PAL
                exitoptions="-vic-6569R3"
            ;;
        "6567") # "old" NTSC
                exitoptions="-vic-6567R8"
            ;;
        "8565") # "new" PAL
                exitoptions="-vic-8565"
            ;;
        "8562") # "new" NTSC
                exitoptions="-vic-8562"
            ;;
        "6526") # "old" CIA
                exitoptions="-CIA6526"
            ;;
        "6526A") # "new" CIA
                exitoptions="-CIA6526A"
            ;;
    esac
}

# called once before any tests run
function c64hdl_prepare
{
    true
}

################################################################################
# reset
# run test program
# exit when write to $d7ff occurs - the value written determines success (=$00) or fail (=$ff)
# exit after $timeout cycles (exitcode=$01)
# save a screenshot at exit - success or failure is determined by comparing screenshots

# $1  test path
# $2  test program name
# $3  timeout cycles
# $4  test full path+name (may be empty)
# $5- extra options for the emulator
function c64hdl_run_screenshot
{
    if [ "$2" == "" ] ; then
        screenshottest="$mounted_crt"
    else
        screenshottest="$2"
    fi

    mkdir -p "$1"/".testbench"
    rm -f "$1"/.testbench/"$screenshottest"-c64hdl.png
    if [ $verbose == "1" ]; then
        echo $C64HDL $C64HDLOPTS $C64HDLOPTSSCREENSHOT ${@:5} "-t" "$3" "-s" "$1"/.testbench/"$screenshottest"-c64hdl.png "-p" "$4"
    fi
    $C64HDL $C64HDLOPTS $C64HDLOPTSSCREENSHOT ${@:5} "-t" "$3" "-s" "$1"/.testbench/"$screenshottest"-c64hdl.png "-p" "$4" 1> /dev/null
    exitcode=$?
    if [ $exitcode -ne 0 ]
    then
        if [ $exitcode -ne 1 ]
        then
            if [ $exitcode -ne 255 ]
            then
                echo -ne "\nerror: call to $C64HDL failed.\n"
                exit -1
            fi
        fi
    fi
    if [ -f "$refscreenshotname" ]
    then

        # defaults for PAL
        C64HDLREFSXO=32
        C64HDLREFSYO=35
        C64HDLSXO=32
        C64HDLSYO=35
        
        #FIXME: NTSC
    
        if [ $verbose == "1" ]; then
            echo ./cmpscreens "$refscreenshotname" "$C64HDLREFSXO" "$C64HDLREFSYO" "$1"/.testbench/"$screenshottest"-c64hdl.png "$C64HDLSXO" "$C64HDLSYO"
        fi
        ./cmpscreens "$refscreenshotname" "$C64HDLREFSXO" "$C64HDLREFSYO" "$1"/.testbench/"$screenshottest"-c64hdl.png "$C64HDLSXO" "$C64HDLSYO"
        exitcode=$?
    else
        echo -ne "reference screenshot missing - "
        exitcode=255
    fi
}

################################################################################
# reset
# run test program
# exit when write to $d7ff occurs - the value written determines success (=$00) or fail (=$ff)
# exit after $timeout cycles (exitcode=$01)

# $1  test path
# $2  test program name
# $3  timeout cycles
# $4  test full path+name (may be empty)
# $5- extra options for the emulator
function c64hdl_run_exitcode
{
    if [ $verbose == "1" ]; then
        echo $C64HDL $C64HDLOPTS $C64HDLOPTSEXITCODE ${@:5} "-t" "$3" "-p" "$4"
    fi
    $C64HDL $C64HDLOPTS $C64HDLOPTSEXITCODE ${@:5} "-t" "$3" "-p" "$4" 1> /dev/null 2> /dev/null
    exitcode=$?
    if [ $verbose == "1" ]; then
        echo $C64HDL "exited with: " $exitcode
    fi
}
