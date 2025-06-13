# package announcement
.onAttach <- function(libname, pkgname) {
  # respect quiet option
  if (isTRUE(getOption("boilerplate.quiet"))) {
    return(invisible())
  }

  version <- utils::packageDescription(pkgname, fields = "Version")
  packageStartupMessage("boilerplate ", version)
}