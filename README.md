# Household composition and risk of severe COVID-19 

This is a study looking at the association between generational composition of a household and risk of severe COVID-19 in older people by ethnicity. 

This is the code and configuration for our paper, "Association between household composition and severe COVID-19 outcomes in older people by ethnicity: an observational cohort study using the OpenSAFELY platform" (published as a pre-print here: https://www.medrxiv.org/content/10.1101/2022.04.22.22274176v1)

* If you are interested in how we defined our variables, take a look at the [study definition](analysis/study_definition.py); this is written in `python`, but non-programmers should be able to understand what is going on there
* If you are interested in how we defined our code lists, look in the [codelists folder](./codelists/).
* Developers and epidemiologists interested in the code should review
[DEVELOPERS.md](./docs/DEVELOPERS.md).

# About the OpenSAFELY framework

The OpenSAFELY framework is a new secure analytics platform for
electronic health records research in the NHS.

Instead of requesting access for slices of patient data and
transporting them elsewhere for analysis, the framework supports
developing analytics against dummy data, and then running against the
real data *within the same infrastructure that the data is stored*.
Read more at [OpenSAFELY.org](https://opensafely.org).

The framework is under fast, active development to support rapid
analytics relating to COVID19; we're currently seeking funding to make
it easier for outside collaborators to work with our system.  You can
read our current roadmap [here](ROADMAP.md).
