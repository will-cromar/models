/*
Compiles to a Kubernetes `Job` resource that executes unit tests on TPU.

Uses templates from this repository:
https://github.com/GoogleCloudPlatform/ml-testing-accelerators
*/
local base = import 'templates/base.libsonnet';
local gpus = import 'templates/gpus.libsonnet';
local tpus = import 'templates/tpus.libsonnet';

# Add new test targets to this list.
local testTargets = [
  'official/vision/image_classification/mnist_test',
  'official/vision/image_classification/classifier_trainer_test',
  'official/nlp/bert/model_training_utils_test',
];

# Set these 3 variables with `--ext-str`.
local image = std.extVar('image');
local buildId = std.extVar('build_id');
local gcsBucket = std.extVar('gcs_bucket');

local outputDir = "%s/%s" % [gcsBucket, buildId];
# Symlink the test file with the `_tpu` suffix so they aren't skipped.
local tpuTestCommand(testPath) = |||
  ln -s /tensorflow/models/%(testPath)s.py /tensorflow/models/%(testPath)s_tpu.py
  python3 /tensorflow/models/%(testPath)s_tpu.py --tpu=$(KUBE_GOOGLE_CLOUD_TPU_ENDPOINTS) --test_tmpdir=%(outputDir)s
||| % {testPath: testPath, outputDir: outputDir};

local unit = base.BaseTest {
  local config = self,

  frameworkPrefix: "tf",
  mode: "unit-tests",
  configMaps: [ ],

  tpuSettings+: {
    softwareVersion: "nightly",
  },

  timeout: 1800, # 30 minutes

  image: image,
  imageTag: buildId,
};

local tpu = unit {
  modelName: "tpu",
  accelerator: tpus.v2_8,
  command: [
    'bash',
    '-cue',
    std.join('\n', std.map(tpuTestCommand, testTargets))
  ],
};

local gpu = unit {
  modelName: "gpu",
  accelerator: gpus.teslaV100,
  command: [
    'bash',
    'official/utils/testing/scripts/presubmit.sh',
    'python3',
  ],
};

{
  'gpu-tests.yaml': gpu.oneshotJob,
  'tpu-tests.yaml': tpu.oneshotJob,
}
