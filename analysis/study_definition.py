# IMPORT STATEMENTS
# This imports the cohort extractor package. This can be downloaded via pip
from cohortextractor import (
    StudyDefinition,
    patients,
    codelist_from_csv,
    codelist,
    combine_codelists,
    filter_codes_by_category,
    combine_codelists,
)

# IMPORT CODELIST DEFINITIONS FROM CODELIST.PY (WHICH PULLS THEM FROM
# CODELIST FOLDER
from codelists import *


# STUDY DEFINITION
# Defines both the study population and points to the important covariates and outcomes
study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1970-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.2,
    },
    # STUDY POPULATION
    population=patients.registered_with_one_practice_between(
        "2019-11-01", "2020-02-01"
    ),
    dereg_date=patients.date_deregistered_from_all_supported_practices(
        on_or_after="2020-02-01",
        date_format="YYYY-MM",
    ),
    # FOLLOW UP
    has_12_m_follow_up=patients.registered_with_one_practice_between(
        "2019-02-01",
        "2020-01-31",  ### 12 months prior to 1st Feb 2020
        return_expectations={
            "incidence": 0.95,
        },
    ),
    # OUTCOMES
    # sgss test results
    first_tested_for_covid=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="any",
        on_or_after="2020-02-01",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest" : "2020-02-01"},
        "rate" : "exponential_increase"},
    ),
    first_positive_test_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        on_or_after="2020-02-01",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest" : "2020-02-01"},
        "rate" : "exponential_increase"},
    ),
    # deaths  
    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        on_or_after="2020-02-01",
        match_only_underlying_cause=False,
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence": 0.6},
    ),
    died_ons_covid_flag_underlying=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        on_or_after="2020-02-01",
        match_only_underlying_cause=True,
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence": 0.6},
    ),
    died_date_ons=patients.died_from_any_cause(
        on_or_after="2020-02-01",
        returning="date_of_death",
        include_month=True,
        include_day=True,
        return_expectations={
            "date": {"earliest": "2020-02-01"},
            "rate": "exponential_increase",
        },
    ),
    # cpns
    died_date_cpns=patients.with_death_recorded_in_cpns(
        on_or_after="2020-02-01",
        returning="date_of_death",
        include_month=True,
        include_day=True,
        return_expectations={
            "date": {"earliest": "2020-02-01"},
            "rate": "exponential_increase",
        },
    ),
    # covid primary care cases
    covid_tpp_probable=patients.with_these_clinical_events(
        combine_codelists(
            covid_identification_in_primary_care_case_codes_clinical,
            covid_identification_in_primary_care_case_codes_test,
            covid_identification_in_primary_care_case_codes_seq,
        ),
        return_first_date_in_period=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence": 0.6},
    ),
    covid_tpp_probableCLINDIAG=patients.with_these_clinical_events(
        covid_identification_in_primary_care_case_codes_clinical,
        return_first_date_in_period=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence": 0.6},
    ),
    covid_tpp_probableTEST=patients.with_these_clinical_events(
        covid_identification_in_primary_care_case_codes_test,
        return_first_date_in_period=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence": 0.6},
    ),
    covid_tpp_probableSEQ=patients.with_these_clinical_events(
        covid_identification_in_primary_care_case_codes_seq,
        return_first_date_in_period=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence": 0.6},
    ),
    covid_admission_date=patients.admitted_to_hospital(
        returning="date_admitted",  # defaults to "binary_flag"
        with_these_diagnoses=covid_codelist,  # optional
        on_or_after="2020-02-01",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-03-01"}, "incidence": 0.95},
    ),
    covid_admission_primary_diagnosis=patients.admitted_to_hospital(
        returning="primary_diagnosis",
        with_these_diagnoses=covid_codelist,  # optional
        on_or_after="2020-02-01",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-03-01"},
            "incidence": 0.95,
            "category": {"ratios": {"U071": 0.5, "U072": 0.5}},
        },
    ),
    positive_covid_test_ever=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        on_or_after="2020-02-01",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-02-01"},
            "rate": "exponential_increase",
        },
    ),
    ## DEMOGRAPHIC COVARIATES
    # AGE
    age=patients.age_as_of(
        "2020-02-01",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    # SEX
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    # DEPRIVIATION
    imd=patients.address_as_of(
        "2020-02-01",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),
    # RURAL OR URBAN LOCATION
    rural_urban=patients.address_as_of(
        "2020-02-01",
        returning="rural_urban_classification",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"rural": 0.1, "urban": 0.9}},
        },
    ),
    # GEOGRAPHIC REGION CALLED STP
    stp=patients.registered_practice_as_of(
        "2020-02-01",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "STP1": 0.1,
                    "STP2": 0.1,
                    "STP3": 0.1,
                    "STP4": 0.1,
                    "STP5": 0.1,
                    "STP6": 0.1,
                    "STP7": 0.1,
                    "STP8": 0.1,
                    "STP9": 0.1,
                    "STP10": 0.1,
                }
            },
        },
    ),
    # OTHER REGION
    region=patients.registered_practice_as_of(
        "2020-02-01",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and the Humber": 0.1,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East of England": 0.1,
                    "London": 0.2,
                    "South East": 0.2,
                },
            },
        },
    ),
    # ETHNICITY IN 6 CATEGORIES
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
            "incidence": 0.75,
        },
    ),
    ## HOUSEHOLD INFORMATION
    # CAREHOME STATUS
    care_home_type=patients.care_home_status_as_of(
        "2020-02-01",
        categorised_as={
            "PC": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='Y'
              AND LocationRequiresNursing='N'
            """,
            "PN": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='N'
              AND LocationRequiresNursing='Y'
            """,
            "PS": "IsPotentialCareHome",
            "U": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "PC": 0.05,
                    "PN": 0.05,
                    "PS": 0.05,
                    "U": 0.85,
                },
            },
        },
    ),
    # HOUSEHOLD INFORMATION
    household_id=patients.household_as_of(
        "2020-02-01",
        returning="pseudo_id",
        return_expectations={
            "int": {"distribution": "normal", "mean": 500, "stddev": 500},
            "incidence": 1,
        },
    ),
    household_size=patients.household_as_of(
        "2020-02-01",
        returning="household_size",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
    ),
)
