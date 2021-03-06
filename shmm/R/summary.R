# Spatial hidden Markov model (SHMM)
#    Copyright (C) 2015-2016  Martin Waever Pedersen, mawp@dtu.dk or wpsgodd@gmail.com
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


#' @name summary.shmmcls
#' @title Output a summary of a fit.shmm() run.
#' @details The output includes the parameter estimates with 95% confidence intervals, estimates of derived parameters (Bmsy, Fmsy, MSY) with 95% confidence intervals, and predictions of biomass, fishing mortality, and catch.
#' @param object A result report as generated by running fit.shmm.
#' @param ... additional arguments affecting the summary produced.
#' @return Nothing. Prints a summary to the screen.
#' @examples
#' rep <- fit.shmm(inp)
#' summary(rep)
#' @export
summary.shmmcls <- function(object, ...){
    #object <- x
    if(!exists('digits')) digits <- 8
    numdigits <- digits # Present values with this number of digits after the dot.
    rep <- object
    cat(paste('Convergence: ', rep$opt$convergence, '  MSG: ', rep$opt$message, '\n', sep=''))
    if(rep$opt$convergence>0){
        cat('WARNING: Model did not obtain proper convergence! Estimates and uncertainties are most likely invalid and cannot be trusted.\n')
        grad <- rep$obj$gr()
        names(grad) <- names(rep$par.fixed)
        cat('Gradient at current parameter vector\n')
        cat('', paste(capture.output(grad),' \n'))
        cat('\n')
    }
    if('sderr' %in% names(rep)) cat('WARNING: Could not calculate standard deviations. The optimum found may be invalid. Proceed with caution.\n')
    cat(paste0('Objective function at optimum: ', round(rep$opt$objective, numdigits), '\n'))
    # -- Data types --
    # -- Residual diagnostics --
    # -- Model parameters --
    cat('\nModel parameter estimates w 95% CI \n')
    resout <- sumshmm.parest(rep, numdigits=numdigits)
    cat('', paste(capture.output(resout),' \n'), '\n')
}


#' @name get.order
#' @title Get order of printed quantities.
#' @return Vector containing indices of printed quantities.
get.order <- function() return(c(2, 1, 3, 2))


#' @name get.colnms
#' @title Get column names for data.frames.
#' @return Vector containing column names of data frames.
get.colnms <- function() return(c('estimate', 'cilow', 'ciupp', 'est.in.log'))


#' @name sumshmm.parest
#' @title Parameter estimates of a fit.shmm() run.
#' @param rep A result report as generated by running fit.shmm.
#' @param numdigits Present values with this number of digits after the dot.
#' @return data.frame containing parameter estimates.
#' @export
sumshmm.parest <- function(rep, numdigits=8){
    if(rep$inp$do.sd.report){
        order <- get.order()
        colnms <- get.colnms()
        sd <- sqrt(diag(rep$cov.fixed))
        nms <- names(rep$par.fixed)
        loginds <- grep('log', nms)
        logp1inds <- grep('logp1',nms)
        logitinds <- grep('logit',nms)
        loginds <- setdiff(loginds, c(logp1inds, logitinds))
        est <- rep$par.fixed
        est[loginds] <- exp(est[loginds])
        est[logitinds] <- invlogit(est[logitinds])
        est[logp1inds] <- invlogp1(est[logp1inds])
        cilow <- rep$par.fixed-1.96*sd
        cilow[loginds] <- exp(cilow[loginds])
        cilow[logitinds] <- invlogit(cilow[logitinds])
        cilow[logp1inds] <- invlogp1(cilow[logp1inds])
        ciupp <- rep$par.fixed+1.96*sd
        ciupp[loginds] <- exp(ciupp[loginds])
        ciupp[logitinds] <- invlogit(ciupp[logitinds])
        ciupp[logp1inds] <- invlogp1(ciupp[logp1inds])
        if(FALSE){
        #if('true' %in% names(rep$inp)){
            npar <- length(nms)
            unms <- unique(nms)
            nupar <- length(unms)
            truepar <- NULL
            parnotest <- NULL
            for(i in 1:nupar){
                tp <- rep$inp$true[[unms[i]]]
                nestpar <- sum(names(est) == unms[i])
                truepar <- c(truepar, tp[1:nestpar])
                if(nestpar < length(tp)){
                    inds <- (nestpar+1):length(tp)
                    parnotest <- c(parnotest, tp[inds])
                    names(parnotest) <- c(names(parnotest), paste0(unms[i], inds))
                }
            }
            truepar[loginds] <- exp(truepar[loginds])
            truepar[logitinds] <- invlogit(truepar[logitinds])
            truepar[logp1inds] <- invlogp1(truepar[logp1inds])
            ci <- rep(0, npar)
            for(i in 1:npar) ci[i] <- as.numeric(truepar[i] > cilow[i] & truepar[i] < ciupp[i])
            resout <- cbind(estimate=round(est,numdigits),
                            true=round(truepar,numdigits),
                            cilow=round(cilow,numdigits),
                            ciupp=round(ciupp,numdigits),
                            true.in.ci=ci,
                            est.in.log=round(rep$par.fixed,numdigits))
        } else {
            resout <- cbind(estimate=round(est,numdigits),
                            cilow=round(cilow,numdigits),
                            ciupp=round(ciupp,numdigits),
                            est.in.log=round(rep$par.fixed,numdigits))
        }
        nms[loginds] <- sub('log', '', names(rep$par.fixed[loginds]))
        nms[logitinds] <- sub('logit', '', names(rep$par.fixed[logitinds]))
        nms[logp1inds] <- sub('logp1', '', names(rep$par.fixed[logp1inds]))
        unms <- unique(nms)
        for(inm in unms){
            nn <- sum(inm==nms)
            if(nn>1){
                newnms <- paste0(inm, 1:nn)
                inds <- which(inm==nms)
                nms[inds] <- newnms
            }
        }
        rownames(resout) <- nms
        if (FALSE){
        #if('true' %in% names(rep$inp)){
            colnames(resout) <- c(colnms[1], 'true', colnms[2:3], 'true.in.ci', colnms[4])
        } else {
            colnames(resout) <- colnms
        }
    } else {
        if('opt' %in% names(rep)) resout <- data.frame(estimate=rep$opt$par)
    }
    return(resout)
}
