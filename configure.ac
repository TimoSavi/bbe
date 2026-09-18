dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT([bbe], [0.2.2-24], [tjsa@iki.fi])
AC_CONFIG_SRCDIR([src/bbe.c])
AC_CONFIG_AUX_DIR([config])
AM_INIT_AUTOMAKE([foreign tar-pax -Wall])
AM_SILENT_RULES([yes])

dnl Create a config.h file (Automake will add -DHAVE_CONFIG_H)
AC_CONFIG_HEADERS([config.h])

dnl Checks for programs.
AC_PROG_INSTALL
AC_PROG_CC
AC_PROG_CC_C99
AC_USE_SYSTEM_EXTENSIONS

dnl Checks for libraries.

dnl Checks for header files.
AC_CHECK_HEADERS([features.h error.h errno.h getopt.h])

dnl Checks for library functions.
AC_CHECK_FUNCS([getline getopt_long])

dnl Checks for typedefs, structures, and compiler characteristics.
AC_SYS_LARGEFILE
AC_CHECK_TYPES([off_t])
AC_C_INLINE

AC_CONFIG_FILES([Makefile src/Makefile doc/Makefile])
AC_OUTPUT
