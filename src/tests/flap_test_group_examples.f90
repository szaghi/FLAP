!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_group_examples
  !< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
  !<
  !<### Compile
  !< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
  !<
  !<###Usage Compile
  !< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
  
  use flap, only : command_line_interface
  use penf
  
  implicit none
  type(command_line_interface) :: cli       !< Command Line Interface (CLI).
  character(99)                :: a_string  !< String value.
  integer(I4P)                 :: int_value !< Integer value.
  real(R4P)                    :: f_value   !< Float value.
  integer(I4P)                 :: error     !< Error trapping flag.
  
  call cli%init(description = 'group examples usage FLAP example',                      &
                examples = ["flap_test_group_examples -s 'test string'      ",          &
                            "flap_test_group_examples --string 'test string'"])

  call cli%add(switch='--string', switch_ab='-s',  help='String input', required=.false., act='store',  def='test', error=error)

  call cli%add_group(group = 'gwe', description = 'Group with examples',                &
                     examples = ["flap_test_group_examples gwe --integer 32",           &
                                 "flap_test_group_examples gwe -i 12       "])
  call cli%add(group = "gwe",                                                           &
               switch='--integer', switch_ab='-i', help='Integer input', required=.false., act='store', def='-1',   error=error)

  call cli%add_group(group = 'gne', description = 'Group without examples')
  call cli%add(group = 'gne',                                                           &
               switch='--float', switch_ab='-f',   help='Float input', required=.false., act='store',   def='-1.0', error=error)

  print '(A)', cli%progname//' has been called with the following arguments:'
  call cli%get(switch='-s', val=a_string, error=error)
  print '(A)', 'String       = '//trim(adjustl(a_string))
  if(cli%run_command('gwe')) then 
    call cli%get(group = 'gwe', switch = '-i', val=int_value, error=error)
    print '(A)', 'Integer      = '//trim(str(int_value))
  endif
  if(cli%run_command('gne')) then 
    call cli%get(group = 'gne', switch = '-f', val=f_value, error=error)
    print '(A)', 'Float        = '//trim(str(f_value))
  endif
  print '(A,I0)', 'Error code   = ', error
endprogram flap_test_group_examples
  