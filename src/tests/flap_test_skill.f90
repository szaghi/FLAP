!< The Agent Skill of a program (issue #129).
program flap_test_skill
!< The Agent Skill of a program (issue #129).
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains, assert_equal, delete_file, read_file, scratch_file
use flap_utils_m, only : skill_name
use penf, only : I4P

implicit none

call check_names
call check_full
call check_minimal
call check_save

contains
  subroutine check_names
  !< The rules of the format on a name.
  call assert_equal(skill_name('solver'), 'solver', 'a valid name')
  call assert_equal(skill_name('./bin/My_Solver.x'), 'my-solver-x', 'path, case and other characters')
  call assert_equal(skill_name('--a__b--'), 'a-b', 'no leading, trailing or repeated hyphen')
  call assert_equal(skill_name('___'), 'program', 'nothing left')
  call assert_equal(len(skill_name(repeat('a', 99))), 64, 'at most 64')
  call assert(skill_name(repeat('a', 63)//'-b') /= repeat('a', 63)//'-', 'no trailing hyphen at the limit')
  endsubroutine check_names

  subroutine check_full
  !< Every part, with what must stay out.
  type(command_line_interface) :: cli   !< CLI.
  character(:), allocatable    :: text  !< Skill.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='my_solver', version='1', description='Solves "things"', schema_option=.true., check_option=.true., &
                dry_run_option=.true., error_format_env='MY_FORMAT')
  call cli%add(switch='--steps', help='Time steps', required=.true., val_type='I4P', error=error)
  call cli%add(switch='--mode', help='Mode', required=.false., def='a', choices='a,b', error=error)
  call cli%add(switch='--flag', help='A flag', required=.false., def='.false.', act='store_true', error=error)
  call cli%add(switch='--token', help='Token', required=.false., def='DEFSECRET', sensitive=.true., error=error)
  call cli%add(switch='--hide', help='Hidden', required=.false., def='0', hidden=.true., error=error)
  call cli%add(position=1, positional=.true., help='Input', required=.true., metavar='FILE', error=error)
  call cli%add_group(group='run', description='Run it', aliases='go')
  call cli%add(group='run', switch='--inner', help='Inner', required=.false., def='0', error=error)
  text = cli%skill()
  call assert(index(text, '---'//new_line('a')//'name: my-solver'//new_line('a')) == 1, 'frontmatter first')
  call assert_contains(text, 'description: "Solves '//achar(92)//'"things'//achar(92)//'". Use when running my_solver."', &
                       'description, quoted')
  call assert_contains(text, '- `--steps value`, required, I4P: Time steps', 'typed, required')
  call assert_contains(text, '- `--mode value`, one of a,b: Mode', 'choices')
  call assert_contains(text, '- `--flag`: A flag', 'a flag takes no value')
  call assert_contains(text, '- `--token value`, sensitive: Token', 'sensitive')
  call assert_contains(text, '- `FILE` (position 1), required: Input', 'positional')
  call assert_contains(text, '- `run, go`: Run it', 'a command')
  call assert_contains(text, '`my_solver COMMAND --schema`.', 'how to read a command')
  call assert_contains(text, '`--check` validates', 'check')
  call assert_contains(text, '`--dry-run` reports', 'dry run')
  call assert_contains(text, '`MY_FORMAT=json`', 'error format')
  call assert_contains(text, '2 fix the command line', 'exit statuses')
  call assert(index(text, 'DEFSECRET') == 0, 'no sensitive default')
  call assert(index(text, '--hide') == 0, 'no hidden option')
  call assert(index(text, '--inner') == 0, 'the options of a command are read on demand')
  call assert(index(text, '--help') == 0, 'no builtin among the options')
  endsubroutine check_full

  subroutine check_minimal
  !< Nothing enabled: nothing promised.
  type(command_line_interface) :: cli   !< CLI.
  character(:), allocatable    :: text  !< Skill.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='p')
  call cli%add(switch='--n', help='N', required=.false., def='0', error=error)
  text = cli%skill()
  call assert_contains(text, 'description: "Use when running p."', 'always a description')
  call assert(index(text, '--schema') == 0, 'no --schema')
  call assert(index(text, '--check') == 0, 'no --check')
  call assert(index(text, '--dry-run') == 0, 'no --dry-run')
  call assert(index(text, '## Commands') == 0, 'no commands')
  endsubroutine check_minimal

  subroutine check_save
  !< Saved as returned; a long description is cut at the limit.
  type(command_line_interface) :: cli   !< CLI.
  character(:), allocatable    :: file  !< File.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='p', description=repeat('x', 2000))
  call assert(index(cli%skill(), repeat('x', 1024)//'"') > 0, 'the limit of the description')
  file = scratch_file('SKILL.md')
  call cli%save_skill(file, error=error)
  call assert_equal(error, 0_I4P, 'saved')
  call assert_contains(read_file(file), 'name: p', 'the file')
  call delete_file(file)
  call cli%save_skill('/nonexistent-dir/SKILL.md', error=error)
  call assert(error /= 0, 'not written')
  endsubroutine check_save
endprogram flap_test_skill
