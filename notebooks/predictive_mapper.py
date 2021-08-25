from loaders.mappers import GeoMapper
import loaders
import fv3fit
import xarray as xr
from vcm import DerivedMapping
from vcm.safe import get_variables
from typing import Sequence, Mapping, Callable, Any

VAR_MAPPING = {'air_temperature': '1', 'specific_humidity': '2'}


class PredictiveMapper(GeoMapper):
    
    def __init__(
        self,
        models: Mapping[str, fv3fit.Predictor],
        data_path: str,
        mapping_function: Callable[[str], loaders.mappers.GeoMapper],
        mapping_kwargs: Mapping[str, Any],
        grid: xr.Dataset,
        additional_vars: Sequence[str]=None
    ):
        self._models = models
        self._base_mapper = mapping_function(data_path, **mapping_kwargs)
        self._grid = grid
        if additional_vars:
            self._additional_vars = additional_vars
        else:
            self._additional_vars = []
        
    def __getitem__(self, timestamp: str) -> xr.Dataset:
        print(f"Getting {timestamp}")
        ds = xr.merge([self._base_mapper[timestamp], self._grid])
        ds = DerivedMapping(ds)
        predicted_ds = []
        for model_name, model in self._models.items():
            model_pred_ds = xr.Dataset()
            inputs = model.input_variables
            input_ds = xr.Dataset({var: ds[var] for var in inputs})
            model_pred_ds = model.predict_columnwise(
                input_ds, feature_dim='z'
            )
            model_pred_ds = xr.merge([
                model_pred_ds,
                xr.Dataset({var: ds[var] for var in self._additional_vars})
            ])
            predicted_ds.append(model_pred_ds.expand_dims(derivation=[model_name]))
        outputs = list(model.output_variables) + self._additional_vars
        output_ds = xr.Dataset({var: ds[var] for var in outputs})
        predicted_ds.append(output_ds.expand_dims(derivation=['target']))
        predicted_ds = xr.concat(predicted_ds, dim='derivation')
        rename_dict = {f"dQ{v}": f"{k}_tendency_due_to_ML" for k, v in VAR_MAPPING.items()}
        return predicted_ds.rename(rename_dict)
    
    def keys(self):
        return self._base_mapper.keys()