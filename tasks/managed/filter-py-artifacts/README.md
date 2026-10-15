# filter-py-artifacts

Filter extracted Python artifacts against build-index purls using `slan-cuan build-index-filter`.
Discovers the build-index.json OCI referrer on the component image, fails closed
if missing or ambiguous, and filters the payload directory. Remediated releases keep
only artifacts whose coordinates match index purls; validated releases can pass
PUBLISH_ALL="true" to keep all artifacts.

## Parameters

| Name                    | Description                                                                                           | Optional | Default value |
|-------------------------|-------------------------------------------------------------------------------------------------------|----------|---------------|
| SNAPSHOT_PATH           | Path to the reduced snapshot spec (relative to dataDir).                                              | Yes      | ""            |
| IMAGE                   | Container image reference (digest-pinned) to discover build-index from. If empty, sourced from SNAPSHOT_PATH. | Yes | ""            |
| filesDir                | The relative path within dataDir where payload files are located                                      | Yes      | files         |
| payloadDir              | Directory containing payload files to filter. Overrides filesDir if set.                              | Yes      | ""            |
| PUBLISH_ALL             | Whether to publish all artifacts without filtering by build-index purls ("true" or "false")          | Yes      | false         |
| sourceDataArtifact      | Trusted Artifact containing the reduced snapshot spec and files                                       | No       | -             |
| dataDir                 | The location where data will be stored                                                                | Yes      | /var/workdir  |
| ociArtifactExpiresAfter | Expiration date for the trusted artifacts created                                                     | Yes      | 1d            |
| orasOptions             | oras options to pass to Trusted Artifacts calls                                                       | Yes      | ""            |
| trustedArtifactsDebug   | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                | Yes      | ""            |
| taskGitUrl              | The url to the git repo where the release-service-catalog tasks and stepactions to be used are stored | No       | -             |
| taskGitRevision         | The revision in the taskGitUrl repo to be used                                                        | No       | -             |
| ociStorage              | The OCI repository where the Trusted Artifacts are stored                                             | No       | -             |

## Results

| Name                        | Description                                                               |
|-----------------------------|---------------------------------------------------------------------------|
| sourceDataArtifact          | Produced trusted data artifact containing filtered payload files          |
| CONSUMED_BUILD_INDEX_DIGEST | Digest of the consumed build-index.json                                   |
