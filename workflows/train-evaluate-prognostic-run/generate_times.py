import intake
import json
import random
import sys

from loaders.mappers import open_nudge_to_fine

data_path, output_train, output_test = sys.argv[1:]
mapper = open_nudge_to_fine(
    data_path,
    nudging_variables=["air_temperature", "specific_humidity", "x_wind", "y_wind", "pressure_thickness_of_atmospheric_layer"])
times = sorted(list(mapper.keys()))


train_times = [t for t in times if t < "20160901.000000"]
test_times = [t for t in times if t >= "20160901.000000"]

random.seed(0)

train_times = random.sample(train_times, 130)
test_times = random.sample(test_times, 50)

with open(output_train, "w") as f:
    json.dump(train_times, f, indent=4)
with open(output_test, "w") as f:
    json.dump(test_times, f, indent=4)