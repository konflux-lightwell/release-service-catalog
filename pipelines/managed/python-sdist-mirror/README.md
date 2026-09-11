# python-sdist-mirror pipeline

Phase 1 Managed Release Pipeline: evaluates ingested Python sdists from a Snapshot OCI artifact.
Source mirroring is intentionally disabled until the taisce-cuan task and interface are available at a reviewed immutable revision. This pipeline must not resolve the unverified archive-sources task. The source-origin sidecar remains the authoritative input for future RHTL/PyPI integration; RHTL parameters are not required for the PyPI flow.
Unlike wheel release pipelines, this pipeline does NOT perform wheel signing or Pulp wheel uploads.

## Parameters

| Name                            | Description                                                                                           | Optional | Default value                                        |
|---------------------------------|-------------------------------------------------------------------------------------------------------|----------|------------------------------------------------------|
| release                         | The namespaced name of the Release CR.                                                                | No       | -                                                    |
| releasePlan                     | The namespaced name of the ReleasePlan CR.                                                            | No       | -                                                    |
| releasePlanAdmission            | The namespaced name of the ReleasePlanAdmission CR.                                                   | No       | -                                                    |
| releaseServiceConfig            | The namespaced name of the ReleaseServiceConfig CR.                                                   | No       | -                                                    |
| snapshot                        | The namespaced name of the Snapshot CR.                                                               | No       | -                                                    |
| enterpriseContractPolicy        | JSON string containing the Enterprise Contract policy configuration.                                  | No       | -                                                    |
| enterpriseContractExtraRuleData | Extra rule data for Enterprise Contract.                                                              | Yes      | ""                                                   |
| enterpriseContractTimeout       | Timeout for Enterprise Contract evaluation.                                                           | Yes      | 1h0m0s                                               |
| taskGitRevision                 | Required full immutable catalog commit SHA supplied by deployment schema (must be 40 hex characters). | No       | -                                                    |
| taisceCuanGitRevision           | Required full Taisce v2 commit SHA supplied by deployment schema.                                     | No       | -                                                    |
| taisceImage                     | Required full immutable digest image for the Taisce task, supplied by deployment.                     | No       | -                                                    |
| sourceOriginPath                | Path to the source-origin sidecar in the extracted artifact.                                          | Yes      | source-origin.json                                   |
| ociStorage                      | OCI storage repository for Trusted Artifacts.                                                         | Yes      | quay.io/konflux-ci/release-service-trusted-artifacts |
