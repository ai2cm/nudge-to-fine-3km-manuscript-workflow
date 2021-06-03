# Make a training dataset for a radiative flux prediction model.

import sys
import numpy as np
import xarray as xr
import intake
import fsspec
import os
from dask.diagnostics import ProgressBar
from vcm.catalog import catalog as CATALOG
from vcm.fv3.metadata import standardize_fv3_diagnostics
from vcm.safe import get_variables


VARIABLES = ["DSWRFsfc", "DLWRFsfc", "USWRFsfc", "PRATEsfc"]
RENAME = {
    'DSWRFsfc': 'override_for_time_adjusted_total_sky_downward_shortwave_flux_at_surface',
    'DLWRFsfc': 'override_for_time_adjusted_total_sky_downward_longwave_flux_at_surface',
    'NSWRFsfc': 'override_for_time_adjusted_total_sky_net_shortwave_flux_at_surface'
}


def _verification_fluxes(dataset_key: str) -> xr.Dataset:
    ds = CATALOG[dataset_key].to_dask()
    ds = standardize_fv3_diagnostics(ds)
    ds = get_variables(ds, VARIABLES)
    ds = ds.assign({'NSWRFsfc': _net_shortwave(ds['DSWRFsfc'], ds['USWRFsfc'])}).drop_vars('USWRFsfc')
    ds = ds.assign({"total_precipitation": _total_precipitation(ds["PRATEsfc"])}).drop_vars("PRATEsfc")
    return _clear_encoding(ds.rename(RENAME))


def _net_shortwave(downward_shortwave: xr.DataArray, upward_shortwave: xr.DataArray) -> xr.DataArray:
    swnetrf_sfc = downward_shortwave - upward_shortwave
    return swnetrf_sfc.assign_attrs(
        {"long_name": "net shortwave surface radiative flux (down minus up)", "units": "W/m^2"}
    )

def _total_precipitation(precipitation_rate: xr.DataArray) -> xr.DataArray:
    timestep_seconds = 900.0
    m_per_mm = 1/1000.0
    total_precipitation = precipitation_rate * m_per_mm * timestep_seconds
    return total_precipitation.assign_attrs({
        "long_name": "precipitation increment to land surface",
        "units": "m",
    })

def _clear_encoding(ds: xr.Dataset) -> xr.Dataset:
    for var in ds.data_vars:
        ds[var].encoding = {}
    return ds

def _state(dataset_path: str, consolidated: bool) -> xr.Dataset:
    ds = intake.open_zarr(dataset_path, consolidated=consolidated).to_dask()
    return standardize_fv3_diagnostics(ds)

def cast_to_double(ds: xr.Dataset) -> xr.Dataset:
    new_ds = {}
    for name in ds.data_vars:
        if ds[name].dtype != np.float64:
            new_ds[name] = (
                ds[name]
                .astype(np.float64, casting="same_kind")
                .assign_attrs(ds[name].attrs)
            )
        else:
            new_ds[name] = ds[name]
    return xr.Dataset(new_ds).assign_attrs(ds.attrs)


verification_dataset_key = '40day_c48_gfsphysics_15min_may2020'


state_path = sys.argv[1]
output_path = sys.argv[2]

verif_ds = _verification_fluxes(verification_dataset_key)


print(
    f"Writing training data zarr using state from {state_path} "
    f"to output location {output_path}"
)
state_ds = _state(state_path, consolidated=True)
state_chunks = state_ds.chunks
ds = xr.merge([verif_ds, state_ds], join='inner')
ds = ds.chunk(state_chunks)
ds = cast_to_double(ds)

mapper = fsspec.get_mapper(output_path)
with ProgressBar():
    ds.to_zarr(mapper, consolidated=True)

