!< Unit tests of the string helpers of flap_utils_m (issue #125, B10).
program flap_test_utils_m
!< Unit tests of the string helpers of flap_utils_m (issue #125, B10).
use flap_utils_m, only : count_substring => count, replace, replace_all, tokenize, unique
use flap_test_utils, only : assert_equal
use penf, only : I4P

implicit none
character(*), parameter    :: LIST = 'a||!||b||!||' !< A list value as stored by FLAP.
character(len(LIST)), allocatable :: toks(:)        !< Tokens (tokenize requires the length of the input string).
integer(I4P)               :: Nt                    !< Number of tokens.

! count: non-overlapping occurrences
call assert_equal(count_substring('aa', 'a'),    2_I4P, "count('aa','a')")
call assert_equal(count_substring('abab', 'ab'), 2_I4P, "count('abab','ab')")
call assert_equal(count_substring('aaa', 'aa'),  1_I4P, "count('aaa','aa'), non-overlapping")
call assert_equal(count_substring('abc', 'x'),   0_I4P, "count('abc','x')")
call assert_equal(count_substring('a', ''),      0_I4P, "count('a',''), empty substring")
call assert_equal(count_substring('', 'a'),      0_I4P, "count('','a')")

! unique: runs of a substring reduced to one occurrence
call assert_equal(trim(unique('a  b   c', ' ')),          'a b c',      "unique('a  b   c',' ')")
call assert_equal(trim(unique('x--y----z', '--')),        'x--y--z',    "unique('x--y----z','--')")
call assert_equal(trim(unique(' ab-cre-cre-ab', '-cre')), ' ab-cre-ab', "unique(' ab-cre-cre-ab','-cre')")
call assert_equal(trim(unique('ab--', '--')),             'ab--',       "unique('ab--','--'), no read past the end")
call assert_equal(trim(unique('x-y', '')),                'x-y',        "unique('x-y',''), empty substring")

! replace and replace_all
call assert_equal(replace('a b c', ' ', '_'),           'a_b c',         "replace, first occurrence only")
call assert_equal(replace_all('a b c', ' ', '||!||'),   'a||!||b||!||c', "replace_all(' ' -> ARGS_SEP)")
call assert_equal(replace_all('a||!||b', '||!||', ' '), 'a b',           "replace_all(ARGS_SEP -> ' ')")
call assert_equal(replace_all('aXb', 'X', 'XX'),        'aXXb',          "replace_all, replacement containing the substring")
call assert_equal(replace_all('  a b ', ' ', '_'),      'a_b',           "replace_all strips leading and trailing blanks")

! tokenize: the trailing empty token is dropped; list storage (v1||!||v2||!||) relies on it, do not "fix" it
call tokenize(strin=LIST, delimiter='||!||', toks=toks, Nt=Nt)
call assert_equal(Nt, 2_I4P, 'tokenize: trailing empty token dropped')
call assert_equal(trim(toks(1)), 'a', 'tokenize: token 1')
call assert_equal(trim(toks(2)), 'b', 'tokenize: token 2')
endprogram flap_test_utils_m
