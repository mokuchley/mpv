#!/bin/sh

case "$0" in
    */*)
        MYDIR=${0%/*}
        ;;
    *)
        MYDIR=.
        ;;
esac

: ${MPV:=mpv}
: ${ILDETECT_MPV:=$MPV}
: ${ILDETECT_MPV:=$MPV}
: ${ILDETECT_MPVFLAGS:=-start 40 -end 60}
: ${ILDETECT_DRY_RUN:=}
: ${MAKE:=make}

# exit status:
# 0 progressive
# 1 telecine
# 2 interlaced
# 8 unknown
# 15 compile fail
# 16 detect fail
# 17+ mpv's status | 16

$MAKE -C "$MYDIR" ildetect.so || exit 15

testfun()
{
    $ILDETECT_MPV "$@" \
        -vf dlopen="$MYDIR/ildetect.so" \
        -o /dev/null -of rawvideo -ofopts-clr -ovc rawvideo -ovcopts-clr -no-audio \
        $ILDETECT_MPVFLAGS \
        | tee /dev/stderr | grep "^ildetect:"
}

out=`testfun "$@"`
case "$out" in
    *"probably: PROGRESSIVE"*)
        [ -n "$ILDETECT_DRY_RUN" ] || $ILDETECT_MPV "$@"
        r=$?
        [ $r -eq 0 ] || exit $(($r | 16))
        exit 0
        ;;
    *"probably: TELECINED"*)
        [ -n "$ILDETECT_DRY_RUN" ] || $ILDETECT_MPV "$@" -vf-pre pullup
        r=$?
        [ $r -eq 0 ] || exit $(($r | 16))
        exit 1
        ;;
    *"probably: INTERLACED"*)
        [ -n "$ILDETECT_DRY_RUN" ] || $ILDETECT_MPV "$@" -vf-pre yadif
        r=$?
        [ $r -eq 0 ] || exit $(($r | 16))
        exit 2
        ;;
    *"probably: "*)
        exit 8
        ;;
    *)
        exit 16
        ;;
esac