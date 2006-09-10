require "mkmf"
require "ftools"

File.copy("lib/win32/service.c",".")
File.copy("lib/win32/service.h",".")

have_func("EnumServicesStatusEx")
have_func("QueryServiceStatusEx")

create_makefile("win32/service")