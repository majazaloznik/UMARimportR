# Set proxy BEFORE renv activation
Sys.setenv(http_proxy="http://proxy.gov.si:80")
Sys.setenv(https_proxy="http://proxy.gov.si:80")
cat("UMAR proxy is set!\n")

# Then activate renv
source("renv/activate.R")

# renv settings
options(renv.config.auto.snapshot = TRUE)
options(repos = c(CRAN = "https://cloud.r-project.org/"))
options(renv.download.method = "libcurl")

# Other settings
options(continue = " ")
Sys.setenv(PATH = paste("C:\\Program Files\\qpdf 11.4.0\\bin", Sys.getenv("PATH"), sep=";"))

