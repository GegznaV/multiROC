#' [+] Test if data in folds is stratified and blocked
#'
#' This function run tests, that help to evaluate if data in folds is
#'  (a) stratified and (b) blocked.
#'
#' @param obj A list with validation/test set indices in folds.
#'        \bold{Note:} If indices are from training set, the result will be
#'        incorrect.
#' @param data A data frame, for which \code{obj} was created.
#' @param stratify_by A name of variable used for stratification.
#' @param block_by A name of variable used for blocking.
#' @param n_col_show Number of blocking variable cross-tabulation's columns to
#'        be shown. Default is 10.
#'
#' @return Print tables that help to evaluate if data is \strong{(a)} stratified,
#'  \strong{(b)} blocked.
#' @export
#'
#' @author Vilmantas Gegzna
#' @examples
#' library(manyROC)
#'
#' # [!!!] Load data
#' DataSet1 <- data.frame(ID = rep(1:20, each = 2),
#'   gr = gl(4, 10, labels = LETTERS[1:4]),
#'   .row = 1:40)
#'
#' obj <- cvo_create_folds(data = DataSet1,
#'   stratify_by = "gr",
#'   block_by = "ID",
#'   returnTrain = FALSE)
#'
#' cvo_test_bs(obj,
#'   stratify_by = "gr",
#'   block_by = "ID",
#'   data = DataSet1)
#'
#'
#'
#' # >  ************************************************************
#' # >      Test for STRATIFICATION
#' # >
#' # >        A B C D      <<<     >>>              A    B    C    D
#' # >  Fold1 2 2 2 2  <-Counts | Proportions->  0.25 0.25 0.25 0.25
#' # >  Fold2 2 2 2 2  <-Counts | Proportions->  0.25 0.25 0.25 0.25
#' # >  Fold3 2 2 2 2  <-Counts | Proportions->  0.25 0.25 0.25 0.25
#' # >  Fold4 2 2 2 2  <-Counts | Proportions->  0.25 0.25 0.25 0.25
#' # >  Fold5 2 2 2 2  <-Counts | Proportions->  0.25 0.25 0.25 0.25
#' # >
#' # >  If stratified, the proportions of each group in each fold
#' # >  (row) should be (approximately) equal and with no zero values.
#' # >  ____________________________________________________________
#' # >  Test for BLOCKING: BLOCKED
#' # >
#' # >        1 2 3 4 5 6 7 8 9 10 ..
#' # >  Fold1 0 0 0 0 2 0 0 2 0  0 ..
#' # >  Fold2 2 0 0 0 0 2 0 0 0  0 ..
#' # >  Fold3 0 0 2 0 0 0 0 0 2  0 ..
#' # >  Fold4 0 0 0 2 0 0 2 0 0  0 ..
#' # >  Fold5 0 2 0 0 0 0 0 0 0  2 ..
#' # >
#' # >  Number of unique IDs in each fold (first 10 columns).
#' # >  If blocked, the same ID appears just in one fold.
#' # >  ************************************************************
cvo_test_bs <- function(obj,
                        stratify_by = NULL,
                        block_by = NULL,
                        data = NULL,
                        n_col_show = 10) {
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (is.null(block_by) & is.null(stratify_by))
    stop("Either `block_by` or `stratify_by`, or both must be provided.")
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (inherits(data, "hyperSpec"))
    data <- data$..
  gr <- getVarValues(stratify_by, data)  %>% as.factor()
  ID <- getVarValues(block_by, data)     %>% as.factor()
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # Calculate:
  count_in_each_fold <-  function(By) {

    if (length(By) == 0)
      return(NULL)

    make_table <- function(inds_in_fold, By) {
      table(By[inds_in_fold])
    }
    do.call("rbind", lapply(obj, make_table, By))

  }

  rezB <- count_in_each_fold(By = ID)
  rezS <- count_in_each_fold(By = gr)

  bru("*")

  if (!is.null(rezS)) {
    # STRATIFICATION test results
    S <- as.data.frame(round(prop.table(rezS, 1), 2))
    SS <- cbind(rep(" <-Counts | Proportions-> ", nrow(S)), S)
    names(SS)[1] <- " <<<     >>>          "
    SS <- cbind(rezS, SS)

    # Print the results:
    bru("_")

    cat("                Test for STRATIFICATION \n\n")
    print(SS)
    cat("\nIf stratified, the proportions of each group in each fold\n")
    cat("(row) should be (approximately) equal and with no zero values.\n")
    cat("Test is not valid if data is blocked and number of cases in \n")
    cat("each block differs significantly.\n")

  }

  if (!is.null(rezB)) {
    # BLOCKING Test
    # Include all columns, even those, that are not displayed.
    B <- if (any(colSums(rezB != 0) != 1) == FALSE) {
      "BLOCKED" # "The same ID appears just in one fold"
    } else {
      "NOT BLOCKED"
    }

    # BLOCKING visualization
    nColExist <- ncol(rezB)
    nColToShow <- min(n_col_show, nColExist)
    B2 <- (rezB[, 1:nColToShow])
    if (n_col_show < ncol(rezB)) {
      `..` <- rep("..", nrow(rezB))
      B2 <- as.data.frame(cbind(B2, `..`))
    }

    # Print the results:
    bru("_")

    cat(sprintf("                Test for BLOCKING: %s\n\n", B))
    cat("      ID\n")
    print(B2)

    cat("\nTable shows number of observations in each fold.\n")
    cat("If blocked, the same ID appears just in one fold.\n")
    cat(sprintf(
      "%d (of %d) first columns are displayed.\n",
      nColToShow,
      nColExist
    ))
  }

  bru("*")

}
# =============================================================================
