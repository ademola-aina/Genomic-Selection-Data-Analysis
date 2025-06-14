####################################
##  Genomic Selection             ##
##    Library: rrBLUP             ##
####################################

rm(list=ls()) 
setwd("C:/Users/sgeza/OneDrive/Desktop/Online_Training/GS_GWAS/Datasets/SalmonGIll/GSRR")
library(ASRgenomics)
library(rrBLUP)

# Reading Phenotypic data
data(pheno.salmon)
datag <- pheno.salmon
head(datag)

# Reading full marker data
markerFULL <- read.table('../Mclean.txt', header=TRUE)
markerFULL[1:5,1:5]
dim(markerFULL)  # 1481 x 11146
# NOTE: order does not match 
markerFULL <- markerFULL[order(rownames(markerFULL)),]
markerFULL[1:5,1:5]
sum(rownames(markerFULL) == datag$ID)

##############################

# Defining Marker Matrix for RRBLUP
Z <- as.matrix(markerFULL)-1   # -1, 0, 1
Z[1:10,1:10]

# Fitting a Model - rrBLUP - y = mu*1 + u*Z + alpha*X +  e
y <- datag$mean_gill_score
GSRR <- mixed.solve(y, Z=Z, K=NULL, X=NULL, SE=FALSE,
                    method='REML', return.Hinv=FALSE)
summary(GSRR)
str(GSRR)
GSRR$Ve  # Error variance
GSRR$Vu  # u variance (marker effects)

# Getting bHAT Parameters 
bHAT <- GSRR$u
head(bHAT)
boxplot(bHAT)

# Total Predictions 
(beta0 <- GSRR$beta) # mu
predGSRR <- matrix(data=beta0, nrow=length(y), ncol=1) + Z %*% bHAT 
head(predGSRR)
plot(y, predGSRR) # Only training data
(corr_pearson <- cor(y, predGSRR, method='pearson', use="complete.obs"))

#######################################################
# Calculating goodness-of-fit statistics

# Heritability (GS)
(Vary <- var(y,na.rm=TRUE))
(VarE <- GSRR$Ve)
(h2_GSRR <- 1 - VarE/Vary)  # 0.212

# Predictive Ability  corr(yadj,ghat)
(PA <- cor(y, predGSRR, method='pearson', use="complete.obs"))

# Predictive Accuracy corr(greal,ghat)
# Need a vector with the greal
(ACC <- PA/sqrt(h2_GSRR))  # Approximation

##############
# Appendix

# How to change from s2u to s2a?
# s2a = 2*[ Sum_i(pi(1-pi)) ]*s2u

GSRR$Vu  # variance of individual u (or beta) effect

dim(markerFULL)
ps <- colMeans(markerFULL)/2
summary(ps)
ff <- sum((ps)*(1-ps))
s2a <- 2*ff*GSRR$Vu
(h2 <- s2a/(s2a+VarE))
