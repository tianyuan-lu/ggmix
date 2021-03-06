library(bnpsd) # to simulate an admixed population

# dimensions of data/model
m <- 10000 # number of loci
n_ind <- 2000 # number of individuals, smaller than usual for easier visualizations
k <- 3 # number of intermediate subpops

# define population structure
F <- 1:k # FST values for k=3 subpopulations
s <- 0.5 # bias coeff of standard Fst estimator
Fst <- 0.3 # desired final Fst
obj <- q1d(n_ind, k, s=s, F=F, Fst=Fst) # data
# in this case return value is a named list with three items:
Q <- obj$Q # admixture proportions
F <- obj$F # rescaled Fst vector for intermediate subpops

# get pop structure parameters of the admixed individuals
Theta <- coanc(Q,F) # the coancestry matrix
Theta[1,]
Phi <- coanc_to_kinship(Theta) # kinship matrix
popkin::plotPopkin(Phi)
# draw allele freqs and genotypes
out <- rbnpsd(Q, F, m, wantP=FALSE, wantB=FALSE, noFixed=TRUE) # exclude variables not of interest
X <- out$X # genotypes
p_anc <- out$Pa # ancestral AFs


# this doesnt work, it just creates two independent populations
# out_test <- rbnpsd(Q, F, m, wantP=FALSE, wantB=FALSE, noFixed=TRUE) # exclude variables not of interest
# Xtest <- out_test$X # genotypes
# p_anc_test <- out_test$Pa # ancestral AFs


library(simtrait) # load this package

# parameters of simulation
m_causal <- m * 0.005
herit <- 0.4

# create simulated trait and associated data

# version 1: known p_anc (prefered, only applicable to simulated data)
obj <- sim_trait(X=X, m_causal=m_causal, herit=herit, p_anc=p_anc)
# obj_test <- sim_trait(X=Xtest, m_causal=m_causal, herit=herit, p_anc=p_anc_test)

# version 2: known kinship (more broadly applicable but fewer guarantees)
# obj <- sim_trait(X=X, m_causal=m_causal, herit=herit, kinship=Phi)

# outputs in both versions:
# trait vector
obj$y
library(magrittr)
obj$y %>% hist
# randomly-picked causal locus index
obj$i
# locus effect size vector
obj$beta

# theoretical covariance of the simulated traits
V <- cov_trait(kinship=Phi, herit=herit)

# set.seed(123)
ind <- caret::createDataPartition(obj$y, p = 0.7, list = FALSE)[,1]
ytrain <- obj$y[ind]
ytest <- obj$y[-ind]

rownames(X) <- paste0("V",1:m)
Xtrain <- t(X[,ind])
Xtest <- t(X[,-ind])
dim(Xtrain)
dim(Xtest)

library(popkin)
popkin::plotPopkin(Phi)

Phi_train <- Phi[ind,ind]
dim(Phi_train)
Phi_test_train <- Phi[-ind,ind]
dim(Phi_test_train)
plotPopkin(Phi_train)
plotPopkin(Phi_test_train)


devtools::load_all()



fit <- ggmix(x = Xtrain,
             y = ytrain,
             kinship = 2*Phi_train,
             verbose = 1, dfmax = 100)
# hdbic <- gic(fit, an = log(length(draw[["ytrain"]])))
hdbic <- gic(fit, an = log(length(obj$y)))
plot(hdbic)
# hdbic <- gic(fit)
# plot(hdbic)
# dev.off()
# help(ggmix:::coef.ggmix_gic)
nzcoef_ggmix <- setdiff(rownames(coef(hdbic, type = "nonzero")), c("(Intercept)","eta","sigma2"))
nzcoef_ggmix

# true positive rate
sum(nzcoef_ggmix %in% paste0("V",obj$i)) / length(obj$i)

# false positive rate
FP <- length(setdiff(nzcoef_ggmix, paste0("V",obj$i))) # false positives
TN <- m-m_causal # True negatives
FPR <- FP / (FP + TN)
FPR

correct_sparsity <- function(nzcoef, obj, p = m){
                                 causal <- paste0("V",obj$i)
                                 not_causal <- setdiff(paste0("V",1:p),paste0("V",obj$i))
                                 active <- nzcoef


                                 correct_nonzeros <- sum(active %in% causal)
                                 correct_zeros <- length(setdiff(not_causal, active))
                                 #correct sparsity
                                 (1 / p) * (correct_nonzeros + correct_zeros)
                               }

correct_sparsity(nzcoef = nzcoef_ggmix, obj = obj, p = m)

yhat <- predict(hdbic, s="lambda.min", newx = Xtest, type = "individual", covariance = 2*Phi_test_train)
l2norm(yhat-ytest)
cor(yhat,ytest)
dev.off()
plot(yhat, ytest)
abline(a=0,b=1)

PC <- prcomp(Xtrain)
xtrain_lasso <- cbind(Xtrain, PC$x[,1:10])

library(glmnet)

fit_glmnet <- cv.glmnet(x = xtrain_lasso,
                        y = ytrain,
                        alpha = 1,
                        standardize = T,
                        penalty.factor = c(rep(1, ncol(Xtrain)), rep(0,10)))
plot(fit_glmnet)
nzcoef_lasso <- setdiff(rownames(coef(fit_glmnet, s = "lambda.min")[nonzeroCoef(coef(fit_glmnet, s = "lambda.min")),,drop=FALSE]),c("(Intercept)",paste0("PC",1:10)))
nzcoef_lasso

correct_sparsity(nzcoef = nzcoef_lasso, obj = obj, p = m)

sum(nzcoef %in% paste0("V",obj$i)) / length(obj$i)

xtest_pc <- predict(PC, newdata = Xtest)
xtest_lasso <- cbind(Xtest, xtest_pc[,1:10])


l2norm(predict(fit_glmnet, s="lambda.min", newx = xtest_lasso) - ytest)
