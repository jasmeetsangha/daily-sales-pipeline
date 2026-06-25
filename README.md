## GitHub Environments

This project uses GitHub Environments to separate deployment configuration between development and production.

The required environments are:

* `development`
* `production`

Environment-specific configuration should be stored inside each GitHub Environment instead of being hardcoded directly in the workflow or stored only as repository-level secrets.

### Why GitHub Environments are used

GitHub Environments provide:

* Separate variables for development and production
* Separate secrets for development and production
* Safer production deployment controls
* Optional approval rules before production runs
* Cleaner workflow configuration
* Reduced risk of accidentally using production credentials during development

### Development Environment

The `development` environment is used for testing workflow changes, dbt changes, and sample data pipeline runs.

Recommended development variables:

| Variable            | Description                            |
| ------------------- | -------------------------------------- |
| `GCP_PROJECT_ID`    | GCP project used for development       |
| `GCP_BUCKET_NAME`   | GCS bucket used by the pipeline        |
| `REGION`            | BigQuery region                        |
| `RAW_DATASET`       | Development raw BigQuery dataset       |
| `ANALYTICS_DATASET` | Development analytics BigQuery dataset |
| `INCOMING_PREFIX`   | Development incoming GCS folder        |
| `PROCESSED_PREFIX`  | Development processed GCS folder       |
| `REJECTED_PREFIX`   | Development rejected GCS folder        |

Recommended development secret:

| Secret       | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `GCP_SA_KEY` | Service account JSON key used by GitHub Actions for development runs |

### Production Environment

The `production` environment is used for production pipeline runs.

Recommended production variables:

| Variable            | Description                           |
| ------------------- | ------------------------------------- |
| `GCP_PROJECT_ID`    | GCP project used for production       |
| `GCP_BUCKET_NAME`   | GCS bucket used by the pipeline       |
| `REGION`            | BigQuery region                       |
| `RAW_DATASET`       | Production raw BigQuery dataset       |
| `ANALYTICS_DATASET` | Production analytics BigQuery dataset |
| `INCOMING_PREFIX`   | Production incoming GCS folder        |
| `PROCESSED_PREFIX`  | Production processed GCS folder       |
| `REJECTED_PREFIX`   | Production rejected GCS folder        |

Recommended production secret:

| Secret       | Description                                                         |
| ------------ | ------------------------------------------------------------------- |
| `GCP_SA_KEY` | Service account JSON key used by GitHub Actions for production runs |

### Shared configuration

Values that are identical across all environments may remain as repository-level variables or secrets.

Examples:

| Name             | Type                | Reason                                                             |
| ---------------- | ------------------- | ------------------------------------------------------------------ |
| `REGION`         | Repository variable | Can remain shared if all environments use the same BigQuery region |
| `PYTHON_VERSION` | Repository variable | Can remain shared if all environments use the same Python version  |

### Workflow behavior

The GitHub Actions workflow should allow the target environment to be selected when the workflow is manually triggered.

Example:

```yaml
workflow_dispatch:
  inputs:
    target_environment:
      description: "Environment to run against"
      required: true
      default: "development"
      type: choice
      options:
        - development
        - production
```

The job should reference the selected environment:

```yaml
environment: ${{ inputs.target_environment }}
```

After the environment is selected, the workflow can use environment-specific variables and secrets:

```yaml
env:
  PROJECT_ID: ${{ vars.GCP_PROJECT_ID }}
  BUCKET_NAME: ${{ vars.GCP_BUCKET_NAME }}
  REGION: ${{ vars.REGION }}
  RAW_DATASET: ${{ vars.RAW_DATASET }}
  ANALYTICS_DATASET: ${{ vars.ANALYTICS_DATASET }}
```

Authentication should use the environment-specific secret:

```yaml
with:
  credentials_json: ${{ secrets.GCP_SA_KEY }}
```

### Recommended production controls

The `production` environment should have stricter controls than `development`.

Recommended production settings:

* Require approval before production runs
* Restrict production deployments to the `main` branch
* Use production-specific secrets and credentials
* Avoid sharing development credentials with production

### Expected result

With this setup:

* Development runs use development datasets, folders, and credentials
* Production runs use production datasets, folders, and credentials
* Production deployments can require manual approval
* The workflow stays reusable while configuration changes by environment
