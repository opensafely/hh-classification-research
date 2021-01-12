#!/usr/bin/env python
# coding: utf-8

# In[1]:


# Process Vo data for a final size analysis by age
# Edit 17 Aug: just look at adults and children to
# Edit 25 Aug: add Cauchemez model and other updates for ONS
# Edit 7 Oct: Try to debug the sub-epidemics problem Lorenzo noticed
# Remember to atleast_2d the design matrices!


# In[2]:


# get_ipython().run_line_magic('matplotlib', 'inline')
import numba
import numpy as np
import scipy.stats as st
import scipy.optimize as op
import pandas as pd
from numpy import linalg as LA
import matplotlib.pyplot as plt
from tqdm.notebook import tqdm
from collections import namedtuple
import sys
import pathlib

has_arguments = len(sys.argv) > 1
nrestarts = 1
if has_arguments:
    nrestarts = int(sys.argv[1])
    sys.stdout = open("vo.txt", "w")


# In[3]:
df = pd.read_csv(
    pathlib.Path(__file__).resolve().parent / "vo_data.csv",
    usecols=["household_id", "first_sampling", "second_sampling", "age_group"],
    dtype={
        "first_sampling": "category",
        "second_sampling": "category",
        "age_group": "category",
    },
)


# In[4]:


# Indices of ever positive cases
posi = (df["first_sampling"].values == "Positive") | (
    df["second_sampling"].values == "Positive"
)


# In[5]:


hcol = df.household_id.values
hhids = pd.unique(df.household_id)
num_households = len(hhids)


# In[6]:


household_tests = numba.typed.List()
household_ages = numba.typed.List()
for hid in hhids:
    dfh = df[df.household_id == hid]
    tests = (dfh["first_sampling"].values == "Positive") | (
        dfh["second_sampling"].values == "Positive"
    )
    aa = dfh["age_group"].values
    household_tests.append(tests)
    household_ages.append(numba.typed.List(aa.to_list()))


# In[7]:


age_gs = pd.unique(df.age_group).to_list()
age_gs.sort()
age_gs


# In[8]:


counts_by_agegroup = np.zeros(len(age_gs))
positives_by_agegroup = np.zeros(len(age_gs))


# In[9]:


for i, ag in enumerate(age_gs):
    dfa = df[df.age_group == ag]
    counts_by_agegroup[i] = len(dfa)
    dfp = df[posi]
    dfa = dfp[dfp.age_group == ag]
    positives_by_agegroup[i] = len(dfa)


# In[10]:


# Dictionary that puts ages in categories
# 0 is reference class
as2rg = numba.typed.Dict.empty(
    key_type=numba.core.types.unicode_type, value_type=numba.core.types.int8
)
as2rg.update(
    {
        "00-10": 1,
        "11-20": 1,
        "21-30": 0,
        "31-40": 0,
        "41-50": 0,
        "51-60": 0,
        "61-70": 0,
        "71-80": 0,
        "81-90": 0,
        "91+": 0,
    }
)
# In[11]:


na = max(as2rg.values())


# In[12]:

# XXX I would separate out the data preparation into a separate action so we can re-run the model without recompiling the intermediate datasets

# XXX this might benefit from parallel=True when using larger datasets
@numba.jit(nopython=True, cache=True, parallel=False)
def get_storage_lists(as2rg, household_tests, household_ages):
    Y = numba.typed.List()  # To store outcomes
    XX = numba.typed.List()  # To store design matrices
    for i in range(0, num_households):
        mya = [as2rg[a] for a in household_ages[i]]
        m = len(mya)
        myx = np.zeros((m, na))
        myy = np.zeros(m)
        for j, a in enumerate(mya):
            if a > 0:
                myx[j, a - 1] = 1
            if household_tests[i][j]:
                myy[j] = 1
        Y.append(myy)
        XX.append(np.atleast_2d(myx))
    return Y, XX


Y, XX = get_storage_lists(as2rg, household_tests, household_ages)

# In[13]:


# The above processes the data - now add final size analysis; first do a run through


# In[14]:


@numba.jit(nopython=True, cache=True)
def phi(s, logtheta=0.0):
    theta = np.exp(logtheta)
    return (1.0 + theta * s) ** (-1.0 / theta)


@numba.jit(nopython=True, cache=True)
def decimal_to_bit_array(d, n_digits):
    powers_of_two = 2 ** np.arange(32)[::-1]
    return ((d & powers_of_two) / powers_of_two)[-n_digits:]


# In[15]:


x = np.array(
    [
        -3.0,
        -2.0,
        0.1,
        0.2,
        0.3,
        0.4,
        0.5,
    ]
)


# In[16]:


@numba.jit(nopython=True, cache=True)
def firstnll(Y, XX):
    llaL = x[0]
    llaG = x[1]
    logtheta = x[2]
    eta = (4.0 / np.pi) * np.arctan(x[3])
    alpha = x[4 : (4 + na)]
    beta = x[(4 + na) : (4 + 2 * na)]
    gamma = x[(4 + 2 * na) :]

    nlv = np.zeros(num_households)  # Vector of negative log likelihoods
    for i in range(0, num_households):
        y = Y[i]
        X = XX[i]
        if np.all(y == 0.0):
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
            laM = np.exp(llaL) * np.outer(np.exp(beta @ (X.T)), np.exp(gamma @ (X.T)))
            laM *= m ** eta

            BB = np.zeros((r, r))  # To be the Ball matrix
            for jd in range(0, r):
                j = decimal_to_bit_array(jd, m)
                for omd in range(0, jd + 1):
                    om = decimal_to_bit_array(omd, m)
                    BB[jd, omd] = 1.0 / np.prod(
                        (phi((1 - j) @ laM, logtheta) ** om) * (Bk ** (1 - j))
                    )
            nlv[i] = -np.log(LA.solve(BB, np.ones(r))[-1])
            if q > 2:
                break
    nll = np.sum(nlv)
    return nll, r, m


nll, r, m = firstnll(Y, XX)
# In[ ]:


# In[17]:

# XXX is it deliberate that the value of `r` (and `m`) is the one set in the last loop of the main loop in `firstnll`?
for jd in range(0, r):
    j = decimal_to_bit_array(jd, m)
    for omd in range(0, jd + 1):
        om = decimal_to_bit_array(omd, m)
        if np.all(om <= j):
            print("({:d},{:d}) j: {}; omega: {}.".format(jd, omd, j, om))


# In[18]:


om >= j


# In[ ]:


# In[19]:


@numba.jit(nopython=True, parallel=False, fastmath=False, cache=True)
def mynll(x, Y, XX):
    if True:  # Ideally catch the linear algebra fail directly
        llaL = x[0]
        llaG = x[1]
        logtheta = x[2]
        eta = (4.0 / np.pi) * np.arctan(x[3])
        alpha = x[4 : (4 + na)]
        beta = x[(4 + na) : (4 + 2 * na)]
        gamma = x[(4 + 2 * na) :]

        nlv = np.zeros(num_households)  # Vector of negative log likelihoods
        for i in range(0, num_households):
            y = Y[i]
            X = XX[i]
            if np.all(y == 0.0):
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
                laM = np.exp(llaL) * np.outer(
                    np.exp(beta @ (X.T)), np.exp(gamma @ (X.T))
                )
                laM *= m ** eta

                BB = np.zeros((r, r))  # To be the Ball matrix
                for jd in range(0, r):
                    j = decimal_to_bit_array(jd, m)
                    for omd in range(0, jd + 1):
                        om = decimal_to_bit_array(omd, m)
                        if np.all(om <= j):
                            BB[jd, omd] = 1.0 / np.prod(
                                (phi((1 - j) @ laM, logtheta) ** om) * (Bk ** (1 - j))
                            )
                nlv[i] = -np.log(LA.solve(BB, np.ones(r))[-1])
        nll = np.sum(nlv)
        # nll += 7.4*np.sum(x**2) # Add a Ridge if needed
        nll += np.sum(x ** 2)  # Add a Ridge if needed
        return nll
    else:
        # This was a try/except block but these are not supported by numba. TODO: work out and implement correct branching logic
        nll = np.inf
        return nll


# In[20]:


# Indicative parameters - to do, add bounds and mulitple restarts
x0 = np.array(
    [
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
    ]
)
mynll(x0, Y, XX)


# In[21]:


bb = np.array(
    [
        [-5.0, 0.0],
        [-5.0, 0.0],
        [-10.0, 10.0],
        [-10.0, 10.0],
        [-3.0, 3.0],
        [-3.0, 3.0],
        [-3.0, 3.0],
    ]
)


# In[22]:

# XXX this could be compiled
def callbackF(x, x2=0.0, x3=0.0):
    print(
        "Evaluated at [{:.3f},{:.3f},{:.3f},{:.3f},{:.3f},{:.3f},{:.3f}]: {:.8f}".format(
            x[0], x[1], x[2], x[3], x[4], x[5], x[6], mynll(x, Y, XX)
        )
    )


# In[23]:


# First try from (essentially) the origin
foutstore = []
fout = op.minimize(
    mynll,
    x0,
    (Y, XX),
    method="TNC",
    callback=callbackF,
    bounds=bb,
    options={"maxiter": 10000},
)
# xhat = fout.x
foutstore.append(fout)


# In[24]:


# Because box bounded, try multiple restarts with stable algorithm
np.random.seed(46)

print(f"nrestarts: {nrestarts}")
for k in range(0, nrestarts):
    nll0 = np.nan
    while (np.isnan(nll0)) or (np.isinf(nll0)):
        xx0 = np.random.uniform(bb[:, 0], bb[:, 1])
        nll0 = mynll(xx0, Y, XX)
    try:
        print("Starting at:")
        print(xx0)
        print(nll0)
        fout = op.minimize(
            mynll,
            xx0,
            (Y, XX),
            bounds=bb,
            method="TNC",
            callback=callbackF,
            options={"maxiter": 1000, "ftol": 1e-9},
        )
        print("Found:")
        print(fout.x)
        print("")
        foutstore.append(fout)
    except:
        k -= 1


# In[25]:


foutstore


# In[26]:


ff = np.inf * np.ones(len(foutstore))
for i in range(0, len(foutstore)):  # In case of crash
    if foutstore[i].success:
        ff[i] = foutstore[i].fun


# In[27]:


xhat = foutstore[ff.argmin()].x
print(xhat)


# In[28]:


pn = len(x0)
delta = (
    1e-2  # This will need some tuning, but here set at sqrt(default delta in optimiser)
)
dx = delta * xhat
ej = np.zeros(pn)
ek = np.zeros(pn)
Hinv = np.zeros((pn, pn))
for j in tqdm(range(0, pn)):
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
Hinv /= 4.0 * np.outer(dx, dx) + np.diag(
    8.0 * dx ** 2
)  # TO DO: replace with a chol ...
covmat = LA.inv(0.5 * (Hinv + Hinv.T))
stds = np.sqrt(np.diag(covmat))
stds


# In[29]:


print(
    "Baseline probability of infection from outside is {:.1f} ({:.1f},{:.1f}) %".format(
        100.0 * (1.0 - np.exp(-np.exp(xhat[1]))),
        100.0 * (1.0 - np.exp(-np.exp(xhat[1] - 1.96 * stds[1]))),
        100.0 * (1.0 - np.exp(-np.exp(xhat[1] + 1.96 * stds[1]))),
    )
)

# phi gets bigger as xhat[1] gets smaller and bigger as xhat[2] gets bigger
# 'Safest' method is Monte Carlo - sample

mymu = xhat[[0, 2, 3]]
mySig = covmat[[0, 2, 3], :][:, [0, 2, 3]]
m = 4000

for k in range(2, 7):
    sarvec = np.zeros(m)
    for i in range(0, m):
        uu = np.random.multivariate_normal(mymu, mySig)
        eta = (4.0 / np.pi) * np.arctan(uu[2])
        sarvec[i] = 100.0 * (1.0 - phi(np.exp(uu[0]) * (k ** eta), uu[1]))

    eta = (4.0 / np.pi) * np.arctan(xhat[3])
    print(
        "HH size {:d} baseline pairwise infection probability is {:.1f} ({:.1f},{:.1f}) %".format(
            k,
            100.0 * (1.0 - phi(np.exp(xhat[0]) * (k ** eta), xhat[2])),
            np.percentile(sarvec, 2.5),
            np.percentile(sarvec, 97.5),
        )
    )


print(
    "Relative external exposure for <=20yo {:.1f} ({:.1f},{:.1f}) %".format(
        100.0 * np.exp(xhat[4]),
        100.0 * np.exp(xhat[4] - 1.96 * stds[4]),
        100.0 * np.exp(xhat[4] + 1.96 * stds[4]),
    )
)
print(
    "Relative susceptibility for <=20yo {:.1f} ({:.1f},{:.1f}) %".format(
        100.0 * np.exp(xhat[5]),
        100.0 * np.exp(xhat[5] - 1.96 * stds[5]),
        100.0 * np.exp(xhat[5] + 1.96 * stds[5]),
    )
)
print(
    "Relative transmissibility for <=20yo {:.1f} ({:.1f},{:.1f}) %".format(
        100.0 * np.exp(xhat[6]),
        100.0 * np.exp(xhat[6] - 1.96 * stds[6]),
        100.0 * np.exp(xhat[6] + 1.96 * stds[6]),
    )
)


# In[ ]:
