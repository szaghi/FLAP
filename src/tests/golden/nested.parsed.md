# test_nested

Manual page for `test_nested` version v2.1.5

`test_nested [--authors] [--help] [--markdown] [--version] {init,commit,tag} ...`

<DATE>

### Short description

Toy program for testing FLAP with nested commands

### Command line options:

Optional switches:  

* `--authors`, `-a`    
    default value .false.  
    Print authors names  

* `--help`, `-h`    
    Print this help message  

* `--markdown`, `-md`    
    Save this help message in a Markdown file  

* `--version`, `-v`    
    Print version  

Commands:
  init
      fake init versioning
  commit
      fake commit changes to current branch
  tag
      fake tag current commit

For more detailed commands help try:
  test_nested init -h,--help
  test_nested commit -h,--help
  test_nested tag -h,--help

### Examples

`test_nested` 

`test_nested -h` 

`test_nested init` 

`test_nested commit -m "fix bug-1"` 

`test_nested tag -a "v2.1.5"` 
