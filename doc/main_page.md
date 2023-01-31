project: FLAP
src_dir: ../src
exclude_dir: ../src/third_party/PENF/src/lib
             ../src/third_party/PENF/src/tests
output_dir: html/publish/
project_github: https://github.com/szaghi/FLAP
summary: Fortran command Line Arguments Parser for poor people
author: Stefano Zaghi
github: https://github.com/szaghi
email: stefano.zaghi@gmail.com
md_extensions: markdown.extensions.toc
               markdown.extensions.smarty
               markdown.extensions.extra
docmark: <
display: public
         protected
         private
source: true
warn: true
graph: true
extra_mods: iso_fortran_env:https://gcc.gnu.org/onlinedocs/gfortran/ISO_005fFORTRAN_005fENV.html

{!README-FLAP.md!}
