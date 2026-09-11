# materialize-lightwell-carrier

Copies the immutable Lightwell carrier closure from the extracted Trusted Artifact files directory into the release workspace. Paths are confined to the extracted carrier, destinations must not already exist, and every copy is verified byte-for-byte before prepare or signing can consume it.

## Parameters

| Name                   | Description | Optional | Default value             |
|------------------------|------|----------|---------------------------|
| sourceDataArtifact     | null | No       | -                         |
| taskGitUrl             | null | No       | -                         |
| taskGitRevision        | null | No       | -                         |
| ociStorage             | null | No       | -                         |
| sourceOriginPath       | null | Yes      | source-origin.json        |
| transformationPath     | null | Yes      | sdist-transformation.json |
| rhtlResponsePath       | null | Yes      | rhtl-response.json        |
| provenanceResponsePath | null | Yes      | provenance-response.bin   |
