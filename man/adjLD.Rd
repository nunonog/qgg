% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/multiple_marker_set_test.R
\name{adjLD}
\alias{adjLD}
\title{LD pruning of summary statistics}
\usage{
adjLD(stat = NULL, statistics = "p-value", Glist = NULL, r2 = 0.9,
  ldSets = NULL, threshold = 1, method = "pruning")
}
\arguments{
\item{stat}{vector or matrix of single marker statistics (e.g. coefficients, t-statistics, p-values)}

\item{statistics}{is the type of statistics used in stat (e.g. statistics="p-value")}

\item{Glist}{list providing information about genotypes stored on disk}

\item{r2}{threshold for r2 used in LD pruning}

\item{ldSets}{list of marker sets - names corresponds to row names in stat}

\item{threshold}{p-value threshold used in LD pruning}

\item{method}{used including method="pruning" which is default or "clumping"}
}
\description{
Perform LD pruning of summary statistics before they are used in gene set enrichment analyses.
}
