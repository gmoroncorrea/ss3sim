#' Verify and standardize SS3 input files
#'
#' This function verifies the contents of operating model (om) and estimation
#' model (em) folders. If the contents are correct, the \code{.ctl} and
#' \code{.dat} files are renamed to standardized names and the `starter.ss`
#' file is updated to reflect these names. If the contents are incorrect then
#' a warning is issued and the simulation is aborted.
#'
#' @author Curry James Cunningham; modified by Sean Anderson
#' @details This is a helper function to be used within the larger wrapper
#' simulation functions.
#
#' @param model_dir directory name for model
#' @param type One of "om" or "em" for operating or estimating model
#' @export
#' @examples \dontrun{
#' d <- system.file("extdata", package = "ss3sim")
#' om <- paste0(d, "/ss3sim_base_eg/cod_om")
#' em <- paste0(d, "/ss3sim_base_eg/cod_em")
#' file.copy(om, ".", recursive = TRUE)
#' file.copy(em, ".", recursive = TRUE)
#' # verify the correct files exist and change file names:
#' verify_input(model_dir = "cod_om", type = "om")
#' verify_input(model_dir = "cod_em", type = "om")
#' # clean up:
#' unlink("cod_om", recursive = TRUE)
#' unlink("cod_em", recursive = TRUE)
#' }

verify_input <- function(model_dir, type = c("om", "em")) {

  if (type != "om" & type != "em") {
    stop(paste("Misspecification of \"type\", read as:", type, 
        "-should be either \"om\" or \"em\""))
  }

  type <- type[1]
  ctl_name <- paste0(type, ".ctl")

  # Ensure correct files are provided
  files <- list.files(model_dir)
  if (length(grep(".ctl", files, ignore.case = TRUE))) {
    f.ctl <- grep(".ctl", files, ignore.case = TRUE)
  } else {
    f.ctl <- NA
  }
  if(type == "om") {
    if (length(grep(".dat", files, ignore.case = TRUE))) {
      f.dat <- grep(".dat", files, ignore.case = TRUE)
    } else {
      f.dat <- NA
    }
  }
  if(type == "om") {
    if (length(grep("ss3.par", files, ignore.case = TRUE))) {
      f.par <- grep("ss3.par", files, ignore.case = TRUE)
    } else {
      f.par <- NA
    }
  }
  if (length(grep("starter.ss", files, ignore.case = TRUE))) {
    f.starter <- grep("starter.ss", files, ignore.case = TRUE)
  } else {
    f.starter <- NA
  }
  if (length(grep("forecast.ss", files, ignore.case = TRUE))) {
    f.forecast <- grep("forecast.ss", files, ignore.case = TRUE)
  } else {
    f.forecast <- NA
  }
  if(type == "om") {
    file.loc <- data.frame(f.ctl, f.dat, f.par, f.starter, f.forecast)
    file.types <- c(".ctl file", ".dat file", "ss3.par file", "starter.ss
      file", "forecast.ss file")
  } 
  if(type == "em") {
    file.loc <- data.frame(f.ctl, f.starter, f.forecast)
    file.types <- c(".ctl file", "starter.ss file", "forecast.ss file")
  }
  missing.file <- which(is.na(file.loc)) # Which files are missing 
  if (length(missing.file) > 0) {
    stop(paste("Missing Files in", type, ":", file.types[missing.file], "\n"))
  }
  else { # Change names
    file.rename(from = paste0(model_dir, "/", files[file.loc$f.ctl]), to =
      paste0(model_dir, "/", ctl_name))
    if(type == "om") {
      file.rename(from = paste0(model_dir, "/", files[file.loc$f.dat]), to =
        paste0(model_dir, "/ss3.dat"))
    }
    # Alter the starter.ss file
    starter.ss <- readLines(paste0(model_dir, "/starter.ss"))
    line.dat <- grep(".dat", starter.ss, ignore.case = TRUE)[1]
    starter.ss[line.dat] <- "ss3.dat"
    line.ctl <- grep(".ctl", starter.ss, ignore.case = TRUE)[1]
    starter.ss[line.ctl] <- ctl_name
    # Write new starter.ss
    file.ext <- file(paste0(model_dir, "/starter.ss"))
    writeLines(starter.ss, file.ext)
    close(file.ext)
    # Alter the .ctl file
    ctl <- readLines(paste0(model_dir, "/", ctl_name))
    ctl.line <- grep("data_and_control_files", ctl, ignore.case = TRUE)
    ctl[ctl.line] <- paste0("#_data_and_control_files: ss3.dat // ", ctl_name)
    file.ext <- file(paste0(model_dir, "/", ctl_name))
    writeLines(ctl, file.ext)
    close(file.ext)
  }
}
