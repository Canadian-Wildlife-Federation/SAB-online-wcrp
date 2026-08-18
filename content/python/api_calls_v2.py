from pathlib import Path

import pandas as pd
import requests

HABITAT_STATS_API_URL = "https://cabd-pro.cwf-fcf.org/nsfishpass/functions/postgisftw.get_habitat_stats_spp/items.json"
STRUCTURE_COUNT_API_URL = "https://cabd-pro.cwf-fcf.org/nsfishpass/functions/postgisftw.get_structure_count_spp/items.json"
COMBINED_OUTPUT_CSV = (
    Path(__file__).resolve().parents[1] / "data" / "combined_output_table_vw.csv"
)

WCRP_ALIASES = {
    "CHETI": "cheticamp",
    "cheti": "cheticamp",
}


def normalize_wcrp(wcrp):
    if not wcrp:
        return wcrp

    return WCRP_ALIASES.get(wcrp, wcrp)


def get_habitat_stats(wcrp=None, spp=None):
    params = {}

    if wcrp:
        params["wcrp"] = normalize_wcrp(wcrp)

    if spp:
        params["spp"] = spp

    response = requests.get(HABITAT_STATS_API_URL, params=params)
    response.raise_for_status()

    data = response.json()
    return pd.DataFrame(data)


def get_habitat_stat_value(wcrp, spp, metric_name, digits=2):
    df = get_habitat_stats(wcrp=wcrp, spp=spp)

    if df.empty:
        raise KeyError(
            f"No habitat stats were returned for wcrp '{wcrp}' "
            f"and spp '{spp}'."
        )

    if metric_name not in df.columns:
        raise KeyError(
            f"Metric '{metric_name}' was not found for wcrp '{wcrp}' "
            f"and spp '{spp}'."
        )

    return round(float(df.loc[0, metric_name]), digits)


def get_structure_count(wcrp=None, spp=None):
    params = {}

    if wcrp:
        params["wcrp"] = normalize_wcrp(wcrp)

    if spp:
        params["spp"] = spp

    response = requests.get(STRUCTURE_COUNT_API_URL, params=params)
    response.raise_for_status()

    data = response.json()
    return pd.DataFrame(data)


def get_structure_count_value(wcrp, spp, metric_name):
    df = get_structure_count(wcrp=wcrp, spp=spp)

    if df.empty:
        raise KeyError(
            f"No structure count data was returned for wcrp '{wcrp}' "
            f"and spp '{spp}'."
        )

    if metric_name not in df.columns:
        raise KeyError(
            f"Metric '{metric_name}' was not found for wcrp '{wcrp}' "
            f"and spp '{spp}'."
        )

    return int(df.loc[0, metric_name])


def get_combined_output():
    return pd.read_csv(COMBINED_OUTPUT_CSV)


def count_assessed_structures():
    df = get_combined_output()

    assessed_mask = (
        df["reason_for_exclusion"].notna()
        | df["assessment_step_completed"].notna()
    )

    return int(df.loc[assessed_mask, "barrier_id"].nunique())
