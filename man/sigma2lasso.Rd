% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sigma2.R
\name{sigma2lasso}
\alias{sigma2lasso}
\alias{sigma2lasso.default}
\alias{sigma2lasso.fullrank}
\title{Estimation of Sigma2 for Linear Mixed Model with Lasso Penalty}
\usage{
sigma2lasso(ggmix_object, ...)

\method{sigma2lasso}{default}(ggmix_object, ...)

\method{sigma2lasso}{fullrank}(ggmix_object, ..., n, beta, eta)
}
\arguments{
\item{ggmix_object}{A ggmix_object object of class \code{lowrank} or
\code{fullrank}}

\item{...}{Extra parameters. Currently ignored.}

\item{n}{number of observations}

\item{beta}{current estimate of the beta parameter including the intercept.
this should be of length p+1, where p is the number of variables.}

\item{eta}{current estimate of the eta parameter}
}
\value{
A descreasing sequence of tuning parameters
}
\description{
\code{sigma2lasso} estimates the value of the sigma2 for the
  linear mixed model with lasso penalty
}
\note{
There is a closed form solution for sigma^2, given beta and eta. This
  funciton isn't meant to be called directly by the user.
}
\seealso{
\code{\link{ggmix}}
}
