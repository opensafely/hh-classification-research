#!/usr/bin/env python
# coding: utf-8

# TH edits completed 18 Nov 2020:
# Add Cauchemez adjustment
# Due to large data, hardcode no ridge
# Change bounds on the basis of previous results

import numpy as np
import scipy.stats as st
import scipy.optimize as op
import pandas as pd
from numpy import linalg as LA
import matplotlib.pyplot as plt
import seaborn as sns
import logging
import numba
import argparse
import pathlib
import os
import sys
import pickle

optimize_maxiter = 1000  #  Reduce to run faster but possibly not solve

# Bounding box on parameters - TO DO: since this contains nages implicitly, edit later
bb = np.array(
    [
        [-3.0, -1.0],
        [-7.0, -3.0],
        [-10.0, 10.0],
        [-10.0, 10.0],
        [-3.0, 3.0],
        [-3.0, 3.0],
        [-3.0, 3.0],
        [-3.0, 3.0],
        [-3.0, 3.0],
        [-3.0, 3.0],
    ]
)

## Starting parameters - and check that the target function evaluates OK at them
#x0_candidates = [
    #np.array([-2.0, -6.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,]),
    #np.array([-1.5, -6.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,]),
#]

parser = argparse.ArgumentParser()
parser.add_argument("--add-ridge", type=float, default=0.0)
parser.add_argument("--starting-parameter", type=int)
args = parser.parse_args()

ridgestr = str(args.add_ridge).replace('.','_')
if args.starting_parameter:
    logname = (
        f"opensafely_age_hh_ridge_{ridgestr}_and_seed_{args.starting_parameter}.log"
    )
else:
    logname = f"opensafely_age_hh_ridge_{ridgestr}_midpoint_start.log"

add_ridge = float(args.add_ridge)  # To keep numba JIT happy

if args.starting_parameter:
    np.random.seed(args.starting_parameter)
    x0 = np.random.uniform(bb[:,0],bb[:,1])
else:
    x0 = np.mean(bb,1)

homedir = pathlib.Path(__file__).resolve().parent.parent

logging.basicConfig(
    filename=homedir / logname,
    # stream=sys.stdout,
    level=logging.INFO,
    format="%(asctime)s %(message)s",
)
logging.info("Libraries imported and logging started")

logging.info("Starting parameters: %s", x0)

with open("output/case_series.pickle", "rb") as f:
    Y = pickle.load(f)
with open("output/age_categories_series.pickle", "rb") as f:
    XX = pickle.load(f)

XX = numba.typed.List(XX)
Y = numba.typed.List(Y)

hhnums = len(Y)
assert hhnums == len(XX)

logging.info("Data pre-processing completed, %s households loaded", hhnums)


# # Define functions
#
# We need two functions:
#
# * phi is the Laplace transform of the distribution of heterogeneity in transmissibility
# * mynll is the negative log likelihood function for the model


@numba.jit(nopython=True)
def phi(s, logtheta=0.0):
    theta = np.exp(logtheta)
    return (1.0 + theta * s) ** (-1.0 / theta)


@numba.jit(nopython=True)
def decimal_to_bit_array(d, n_digits):
    powers_of_two = int(2) ** np.arange(32)[::-1]
    return ((d & powers_of_two) / powers_of_two)[-n_digits:]


@numba.jit(nopython=True)
def mynll(x, Y, XX):
    # This is the number of age classes; here we will follow Roz's interests and consider two young ages
    nages = 2
    if True:  # Ideally catch the linear algebra fail directly
        llaL = x[0]
        llaG = x[1]
        logtheta = x[2]
        eta = (4.0 / np.pi) * np.arctan(x[3])
        alpha = x[4 : (4 + nages)]
        beta = x[(4 + nages) : (4 + 2 * nages)]
        gamma = x[(4 + 2 * nages) :]

        nlv = np.zeros(hhnums)  # Vector of negative log likelihoods
        for i in range(0, hhnums):
            y = Y[i]
            # At this point, X is a np.array whose elements are an int
            # representing the classfication of each household member's age. We
            # need to turn this into an ndarray whose rows are bitarrays
            # representating this age.
            #
            # To do this in a numba-compliant way, we need to make a
            #  list-of-lists before casting to an ndarray.
            X = []
            for age in XX[i]:
                X.append(list(decimal_to_bit_array(age, 2)))
            X = np.array(X)

            if np.all(y == 0):
                nlv[i] = np.exp(llaG) * np.sum(np.exp(alpha @ (X.T)))
            else:
                # Sort to go zeros then ones WLOG (could do in pre-processing)
                ii = np.argsort(y)
                y = y[ii]
                X = X[ii, :]
                q = np.sum(y > 0)
                r = 2 ** q
                m = len(y)

                # Quantities that don't vary through the sum
                Bk = np.exp(-np.exp(llaG) * np.exp(alpha @ (X.T)))
                laM = (
                    np.exp(llaL)
                    * np.outer(np.exp(beta @ (X.T)), np.exp(gamma @ (X.T)))
                    * (m ** eta)
                )

                BB = np.zeros((r, r))  # To be the Ball matrix
                for jd in range(0, r):
                    j = decimal_to_bit_array(jd, m)
                    for omd in range(0, jd + 1):
                        om = decimal_to_bit_array(omd, m)
                        if np.all(om <= j):
                            # devide by zero encountered in double_scalars
                            # overflow encountered in double_scalars
                            my_phi = phi((1 - j) @ laM, logtheta)

                            if np.any(
                                np.floor(np.log10(np.abs(my_phi[my_phi != 0]))) < -100
                            ):
                                return np.inf

                            BB[jd, omd] = 1.0 / np.prod(
                                (my_phi ** om) * (Bk ** (1 - j))
                            )
                if np.any(np.isnan(BB)) or np.any(np.isinf(BB)):
                    return np.inf
                nlv[i] = -np.log(LA.solve(BB, np.ones(r))[-1])
        nll = np.sum(nlv)
        nll += add_ridge * np.sum(x ** 2)
        return nll
    else:
        nll = np.inf
        return nll


logging.info("Helper functions defined")


# # Fit the model
#
# The code here uses the simplest kind of maximum likelihood estimation that one might try - it is likely that there may need to be some tuning of this process to the data and computational resources available, and also that in the current context it will fail because almost by definition the model is mis-specified compared to the data.
#


mynll(x0, Y, XX)

logging.info("Objective function evaluated at one value")


def callbackF(x):
    print(f"Evaluated at {x}")



# First try from (essentially) the origin using Nelder-Mead
# The exact optimisation method to use is expected to depend a lot on the actual data
fout = op.minimize(
    mynll,
    x0,
    (Y, XX),
    bounds=bb,
    method="TNC",
    callback=callbackF,
    options={"maxiter": optimize_maxiter, "ftol": 1e-4},
)
xhat = fout.x
logging.info(fout)
if not fout.success:
    logging.info("No convergence. Exiting.")
    sys.exit(0)


pn = len(x0)
delta = 1e-3  # This finite difference needs some unavoidable tuning by hand
dx = delta * xhat
ej = np.zeros(pn)
ek = np.zeros(pn)
Hinv = np.zeros((pn, pn))
for j in range(0, pn):
    ej[j] = dx[j]
    for k in range(0, j):
        ek[k] = dx[k]
        Hinv[j, k] = (
            mynll(xhat + ej + ek, Y, XX)
            - mynll(xhat + ej - ek, Y, XX)
            - mynll(xhat - ej + ek, Y, XX)
            + mynll(xhat - ej - ek, Y, XX)
        )
        ek[k] = 0.0
    Hinv[j, j] = (
        -mynll(xhat + 2 * ej, Y, XX)
        + 16 * mynll(xhat + ej, Y, XX)
        - 30 * mynll(xhat, Y, XX)
        + 16 * mynll(xhat - ej, Y, XX)
        - mynll(xhat - 2 * ej, Y, XX)
    )
    ej[j] = 0.0
Hinv += np.triu(Hinv.T, 1)
# We get some divide by zero warnings here. Investigate with
# np.seterr(all=None, divide=None, over=None, under=None, invalid="raise")
Hinv = Hinv / (
    4.0 * np.outer(dx, dx) + np.diag(8.0 * dx ** 2)
)  # TO DO: replace with a chol ...
try:
    covmat = LA.inv(0.5 * (Hinv + Hinv.T))
except np.linalg.LinAlgError:
    logging.warn("Matrix is singular or ill-conditioned. Exiting. %s", Hinv + Hinv.T)
    import sys

    sys.exit(0)
stds = np.sqrt(np.diag(covmat))


logging.info("One optimisation run")


logging.info(
    "Baseline probability of infection from outside is {:.5f} ({:.5f},{:.5f}) %".format(
        100.0 * (1.0 - np.exp(-np.exp(xhat[1]))),
        100.0 * (1.0 - np.exp(-np.exp(xhat[1] - 1.96 * stds[1]))),
        100.0 * (1.0 - np.exp(-np.exp(xhat[1] + 1.96 * stds[1]))),
    )
)

mymu = xhat[[0, 2, 3]]
mySig = covmat[[0, 2, 3], :][:, [0, 2, 3]]
m = 4000

for k in range(2, 7):
    sarvec = np.zeros(m)
    try:
        for i in range(0, m):
            uu = np.random.multivariate_normal(mymu, mySig)
            eta = (4.0 / np.pi) * np.arctan(uu[2])
            sarvec[i] = 100.0 * (1.0 - phi(np.exp(uu[0]) * (k ** eta), uu[1]))
    except ValueError as e:
        if str(e) == "array must not contain infs or NaNs":
            logging.info("Unable to compute baseline p({:d}), got: {!r}".format(k, e))
        else:
            raise
    else:
        eta = (4.0 / np.pi) * np.arctan(xhat[3])
        logging.info(
            "p({:d}) is {:.5f} ({:.5f},{:.5f}) %".format(
                k,
                100.0 * (1.0 - phi(np.exp(xhat[0]) * (k ** eta), xhat[2])),
                np.percentile(sarvec, 2.5),
                np.percentile(sarvec, 97.5),
            )
        )

logging.info(
    "Relative external exposure for <=9yo {:.5f} ({:.5f},{:.5f}) %".format(
        100.0 * np.exp(xhat[4]),
        100.0 * np.exp(xhat[4] - 1.96 * stds[4]),
        100.0 * np.exp(xhat[4] + 1.96 * stds[4]),
    )
)
logging.info(
    "Relative external exposure for 10-18yo {:.5f} ({:.5f},{:.5f}) %".format(
        100.0 * np.exp(xhat[5]),
        100.0 * np.exp(xhat[5] - 1.96 * stds[5]),
        100.0 * np.exp(xhat[5] + 1.96 * stds[5]),
    )
)

logging.info(
    "Relative susceptibility for <=9yo {:.5f} ({:.5f},{:.5f}) %".format(
        100.0 * np.exp(xhat[6]),
        100.0 * np.exp(xhat[6] - 1.96 * stds[6]),
        100.0 * np.exp(xhat[6] + 1.96 * stds[6]),
    )
)
logging.info(
    "Relative susceptibility for 10-18yo {:.5f} ({:.5f},{:.5f}) %".format(
        100.0 * np.exp(xhat[7]),
        100.0 * np.exp(xhat[7] - 1.96 * stds[7]),
        100.0 * np.exp(xhat[7] + 1.96 * stds[7]),
    )
)

logging.info(
    "Relative transmissibility for <=9yo {:.5f} ({:.5f},{:.5f}) %".format(
        100.0 * np.exp(xhat[8]),
        100.0 * np.exp(xhat[8] - 1.96 * stds[8]),
        100.0 * np.exp(xhat[8] + 1.96 * stds[8]),
    )
)
logging.info(
    "Relative transmissibility for 10-18yo {:.5f} ({:.5f},{:.5f}) %".format(
        100.0 * np.exp(xhat[9]),
        100.0 * np.exp(xhat[9] - 1.96 * stds[9]),
        100.0 * np.exp(xhat[9] + 1.96 * stds[9]),
    )
)
