call cli%add(switch='--level', switch_ab='-l', help='Verbosity level', required=.false., act='store', def='1', &
             choices='1,3,5')
! case_sensitive=.false.: WENO5 matches weno5, and get returns the declared spelling
call cli%add(switch='--scheme', help='Space scheme', required=.false., act='store', def='muscl', &
             choices='weno5,muscl', case_sensitive=.false.)
