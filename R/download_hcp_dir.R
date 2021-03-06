#' @title Download an entire directory from HCP
#' @description Downloads a directory/folder from HCP database
#' @param prefix Folder to download
#' @param delimiter Delimiter for files
#' @param outdir Output directory
#' @param verbose Should diagnostic values be printed?
#' @param ... additional arguments to pass to \code{\link{hcp_list_files}}
#'
#' @return List of return from calling \code{\link{hcp_list_files}},
#' the output directory, and all destination files (not subsetted by those
#' that did in fact download)
#'
#' @export
#' @examples
#' if (have_aws_key()) {
#'    prefix = "HCP/100307/release-notes"
#'    res = download_hcp_dir(prefix = prefix, verbose = FALSE)
#' }
download_hcp_dir = function(
  prefix,
  delimiter = "",
  outdir = tempfile(),
  verbose = TRUE,
  ...) {
  ret = hcp_list_files(prefix = prefix,
                       delimiter = delimiter,
                       verbose = verbose,
                       ...)

  res = parse_list_files(ret)
  res = res$contents
  pref = ret$parsed_result$Prefix[[1]]
  if ("ListBucketResult" %in%  names(ret$parsed_result)
      && is.null(pref)) {
    pref = ret$parsed_result$ListBucketResult$Prefix[[1]]
  }
  res$sub_dir = sub(pref, "", res$Key, fixed = TRUE)
  res$destfile = file.path(outdir, res$sub_dir)

  sub_dirs = unique(dirname(res$sub_dir))
  sub_dirs = setdiff(sub_dirs, ".")
  sub_out_dirs = file.path(outdir, sub_dirs)

  de = dir.exists(sub_out_dirs)
  if (!all(de)) {
    sapply(sub_out_dirs[!de], dir.create, recursive = TRUE)
  }
  res$file = res$Key

  mapply(function(file, destfile) {
    if (verbose) {
      message("\nDownloading:")
      message(basename(file))
    }
    download_hcp_file(path_to_file = file,
                      destfile = destfile,
                      verbose = verbose,
                      ...)
  }, res[, "file"], res[, "destfile"])

  fe = file.exists(res$destfile)
  if (!all(fe)) {
    warning("Not all files were downloaded!")
  }
  L = list(outdir = outdir,
           output_files = res$destfile,
           list_ret = ret)
  return(L)

}

#' @export
#' @rdname download_hcp_dir
download_fcp_dir = function(
  ...) {
  download_hcp_dir(...,
                    bucket = "fcp-indi",
                    sign = FALSE)
}

#' @export
#' @rdname download_hcp_dir
download_openneuro_dir = function(
  ...) {
  download_hcp_dir(...,
                   bucket = "openneuro",
                   sign = FALSE)
}

