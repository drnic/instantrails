require "mkmf"
require "ftools"

have_func("EnumServicesStatusEx")
have_func("QueryServiceStatusEx")

create_makefile("win32/service")
