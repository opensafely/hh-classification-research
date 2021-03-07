import pandas as pd

MSOAs = pd.read_csv(
    filepath_or_buffer = './lookups/MSOAs.csv'
)
dict_msoa = { msoa : 1/len(MSOAs.index) for msoa in MSOAs['msoa_id'].tolist() }