!< JSON strings of FLAP's machine-readable outputs (issue #128).
program flap_test_json
!< JSON strings of FLAP's machine-readable outputs (issue #128).
use flap_test_utils, only : assert_equal
use flap_utils_m, only : flap_string, json_array, json_string

implicit none
character(1), parameter :: BS = achar(92) !< Backslash.
type(flap_string)       :: items(2)       !< Items of an array.
type(flap_string)       :: none(0)        !< No item.

call assert_equal(json_string(''), '""', 'empty')
call assert_equal(json_string('abc'), '"abc"', 'plain')
call assert_equal(json_string('a"b'), '"a'//BS//'"b"', 'a quote')
call assert_equal(json_string('a'//BS//'b'), '"a'//BS//BS//'b"', 'a backslash')
call assert_equal(json_string('a'//new_line('a')//'b'), '"a'//BS//'nb"', 'a newline')
call assert_equal(json_string('a'//achar(9)//'b'), '"a'//BS//'tb"', 'a tab')
call assert_equal(json_string(achar(13)//achar(8)//achar(12)), '"'//BS//'r'//BS//'b'//BS//'f"', 'return, backspace, feed')
call assert_equal(json_string(achar(27)//'[0m'), '"'//BS//'u001b[0m"', 'an escape code')
call assert_equal(json_string('/'), '"/"', 'a slash needs no escape')
! valid UTF-8 passes through
call assert_equal(json_string('caff'//char(195)//char(168)), '"caff'//char(195)//char(168)//'"', 'two bytes')
call assert_equal(json_string(char(226)//char(130)//char(172)), '"'//char(226)//char(130)//char(172)//'"', 'three bytes')
call assert_equal(json_string(char(240)//char(159)//char(152)//char(128)), '"'//char(240)//char(159)//char(152)//char(128)//'"', &
                  'four bytes')
! invalid UTF-8 is replaced, byte by byte
call assert_equal(json_string('a'//char(255)//'b'), '"a'//BS//'ufffdb"', 'an invalid byte')
call assert_equal(json_string(char(195)), '"'//BS//'ufffd"', 'a truncated sequence')
call assert_equal(json_string(char(192)//char(128)), '"'//BS//'ufffd'//BS//'ufffd"', 'an overlong form')
call assert_equal(json_string(char(237)//char(160)//char(128)), '"'//BS//'ufffd'//BS//'ufffd'//BS//'ufffd"', 'a surrogate')
call assert_equal(json_string(char(244)//char(144)//char(128)//char(128)), &
                  '"'//BS//'ufffd'//BS//'ufffd'//BS//'ufffd'//BS//'ufffd"', 'above U+10FFFF')
! arrays
items(1)%s = 'a'
items(2)%s = 'b"'
call assert_equal(json_array(items), '["a","b'//BS//'""]', 'an array')
call assert_equal(json_array(none), '[]', 'an empty array')
endprogram flap_test_json
